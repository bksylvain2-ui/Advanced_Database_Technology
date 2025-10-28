-- ============================================================================
-- B10: Business Limit Alert (Function + Trigger)
-- ============================================================================
-- Creates BUSINESS_LIMITS table, alert function, and enforcement trigger
-- to prevent business rule violations in the e-voting system.
-- ============================================================================

-- Drop existing objects if they exist
DROP TRIGGER IF EXISTS trg_ballot_business_limit ON node_a.ballot_a CASCADE;
DROP FUNCTION IF EXISTS fn_should_alert(INTEGER) CASCADE;
DROP TABLE IF EXISTS node_a.business_limits CASCADE;

-- ============================================================================
-- 1. CREATE BUSINESS_LIMITS TABLE
-- ============================================================================
-- Stores configurable business rules with thresholds and active status

CREATE TABLE node_a.business_limits (
    rule_key VARCHAR(64) PRIMARY KEY,
    threshold NUMERIC NOT NULL,
    active CHAR(1) NOT NULL DEFAULT 'Y',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraint: active must be 'Y' or 'N'
    CONSTRAINT chk_business_limits_active CHECK (active IN ('Y', 'N')),
    
    -- Constraint: threshold must be positive
    CONSTRAINT chk_business_limits_threshold CHECK (threshold > 0)
);

-- Add comment
COMMENT ON TABLE node_a.business_limits IS 'Configurable business rules for e-voting system enforcement';

-- ============================================================================
-- 2. SEED ONE ACTIVE RULE
-- ============================================================================
-- Rule: MAX_VOTES_PER_CANDIDATE - Prevents any candidate from receiving
-- more votes than the threshold (prevents vote stuffing)

INSERT INTO node_a.business_limits (rule_key, threshold, active, description)
VALUES (
    'MAX_VOTES_PER_CANDIDATE',
    3,
    'Y',
    'Maximum number of votes allowed per candidate to prevent vote stuffing'
);

-- Verify the rule
SELECT 
    rule_key,
    threshold,
    active,
    description,
    created_at
FROM node_a.business_limits
WHERE active = 'Y';

-- ============================================================================
-- 3. CREATE ALERT FUNCTION
-- ============================================================================
-- Function: fn_should_alert(candidate_id)
-- Returns: 1 if business limit would be violated, 0 if allowed
-- Logic: Checks if adding a vote for the candidate would exceed threshold

CREATE OR REPLACE FUNCTION fn_should_alert(p_candidate_id INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_threshold NUMERIC;
    v_current_votes INTEGER;
    v_rule_active CHAR(1);
BEGIN
    -- Read the active business limit rule
    SELECT threshold, active
    INTO v_threshold, v_rule_active
    FROM node_a.business_limits
    WHERE rule_key = 'MAX_VOTES_PER_CANDIDATE'
    AND active = 'Y';
    
    -- If no active rule found, allow the operation
    IF NOT FOUND OR v_rule_active = 'N' THEN
        RETURN 0;
    END IF;
    
    -- Count current votes for the candidate across all fragments
    -- Check local fragment (Ballot_A)
    SELECT COUNT(*)
    INTO v_current_votes
    FROM node_a.ballot_a
    WHERE candidateid = p_candidate_id;
    
    -- Add votes from remote fragment (Ballot_B) if accessible
    BEGIN
        v_current_votes := v_current_votes + (
            SELECT COUNT(*)
            FROM node_b.ballot_b
            WHERE candidateid = p_candidate_id
        );
    EXCEPTION
        WHEN OTHERS THEN
            -- If remote fragment not accessible, continue with local count only
            NULL;
    END;
    
    -- Check if adding one more vote would exceed threshold
    IF v_current_votes >= v_threshold THEN
        RETURN 1;  -- Alert: limit would be violated
    ELSE
        RETURN 0;  -- OK: within limit
    END IF;
END;
$$;

-- Add comment
COMMENT ON FUNCTION fn_should_alert(INTEGER) IS 
'Checks if adding a vote for the candidate would violate MAX_VOTES_PER_CANDIDATE business limit';

-- Test the function with existing data
SELECT 
    c.candidateid,
    c.candidatename,
    COUNT(ba.voteid) as current_votes,
    bl.threshold,
    fn_should_alert(c.candidateid) as should_alert,
    CASE 
        WHEN fn_should_alert(c.candidateid) = 1 THEN 'BLOCKED'
        ELSE 'ALLOWED'
    END as status
FROM node_a.candidates c
CROSS JOIN node_a.business_limits bl
LEFT JOIN node_a.ballot_a ba ON c.candidateid = ba.candidateid
WHERE bl.rule_key = 'MAX_VOTES_PER_CANDIDATE'
GROUP BY c.candidateid, c.candidatename, bl.threshold
ORDER BY current_votes DESC
LIMIT 10;

-- ============================================================================
-- 4. CREATE ENFORCEMENT TRIGGER
-- ============================================================================
-- Trigger: trg_ballot_business_limit
-- Fires: BEFORE INSERT OR UPDATE on Ballot_A
-- Action: Raises error if fn_should_alert returns 1

CREATE OR REPLACE FUNCTION trg_fn_ballot_business_limit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_alert_result INTEGER;
    v_candidate_name VARCHAR(100);
    v_threshold NUMERIC;
BEGIN
    -- Call the alert function
    v_alert_result := fn_should_alert(NEW.candidateid);
    
    -- If alert triggered, raise error
    IF v_alert_result = 1 THEN
        -- Get candidate name and threshold for error message
        SELECT c.candidatename, bl.threshold
        INTO v_candidate_name, v_threshold
        FROM node_a.candidates c
        CROSS JOIN node_a.business_limits bl
        WHERE c.candidateid = NEW.candidateid
        AND bl.rule_key = 'MAX_VOTES_PER_CANDIDATE'
        AND bl.active = 'Y';
        
        -- Raise application error (PostgreSQL equivalent of ORA-20000)
        RAISE EXCEPTION 'BUSINESS_LIMIT_VIOLATION: Candidate % (ID: %) has reached maximum vote limit of %. Vote rejected.',
            v_candidate_name, NEW.candidateid, v_threshold
            USING ERRCODE = '45000';  -- Custom error code
    END IF;
    
    -- If no alert, allow the operation
    RETURN NEW;
END;
$$;

-- Create the trigger
CREATE TRIGGER trg_ballot_business_limit
    BEFORE INSERT OR UPDATE ON node_a.ballot_a
    FOR EACH ROW
    EXECUTE FUNCTION trg_fn_ballot_business_limit();

-- Add comment
COMMENT ON TRIGGER trg_ballot_business_limit ON node_a.ballot_a IS
'Enforces MAX_VOTES_PER_CANDIDATE business limit by blocking votes that would exceed threshold';

-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================

SELECT '✓ Business Limits Setup Complete' as status;
SELECT '✓ Active Rule: MAX_VOTES_PER_CANDIDATE with threshold = 3' as rule;
SELECT '✓ Function fn_should_alert() created' as function;
SELECT '✓ Trigger trg_ballot_business_limit created on Ballot_A' as trigger;
