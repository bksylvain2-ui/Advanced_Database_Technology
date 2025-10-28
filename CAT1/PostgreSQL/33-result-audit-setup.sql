-- ============================================================================
-- B7: E-C-A Trigger for Denormalized Totals (small DML set)
-- ============================================================================
-- WHAT: Create audit table and statement-level trigger to track denormalized
--       totals in Result table when Ballot (Votes) changes occur
-- ============================================================================

-- Step 1: Create Result_AUDIT table
-- ============================================================================
CREATE TABLE IF NOT EXISTS Result_AUDIT (
    AuditID SERIAL PRIMARY KEY,
    bef_total INTEGER,
    aft_total INTEGER,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    key_col VARCHAR(64),
    operation VARCHAR(10),
    affected_rows INTEGER,
    CONSTRAINT chk_result_audit_operation 
        CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE'))
);

COMMENT ON TABLE Result_AUDIT IS 'Audit trail for Result table denormalized total recomputations';
COMMENT ON COLUMN Result_AUDIT.bef_total IS 'Total votes before the DML operation';
COMMENT ON COLUMN Result_AUDIT.aft_total IS 'Total votes after the DML operation';
COMMENT ON COLUMN Result_AUDIT.key_col IS 'Identifier for the affected Result record (ConstituencyID-CandidateID)';
COMMENT ON COLUMN Result_AUDIT.operation IS 'Type of DML operation (INSERT/UPDATE/DELETE)';
COMMENT ON COLUMN Result_AUDIT.affected_rows IS 'Number of rows affected by the operation';

-- Step 2: Create trigger function for statement-level audit
-- ============================================================================
CREATE OR REPLACE FUNCTION audit_result_recomputation()
RETURNS TRIGGER AS $$
DECLARE
    v_constituency_id INTEGER;
    v_candidate_id INTEGER;
    v_before_total INTEGER;
    v_after_total INTEGER;
    v_key VARCHAR(64);
    v_affected_count INTEGER;
BEGIN
    -- Get affected constituency and candidate combinations
    -- Handle different DML operations
    IF TG_OP = 'DELETE' THEN
        -- For DELETE, use OLD table
        FOR v_constituency_id, v_candidate_id IN 
            SELECT DISTINCT c.ConstituencyID, OLD.CandidateID
            FROM OLD
            JOIN Candidates c ON OLD.CandidateID = c.CandidateID
        LOOP
            -- Get before total (current value in Results)
            SELECT TotalVotes INTO v_before_total
            FROM Results
            WHERE ConstituencyID = v_constituency_id 
              AND CandidateID = v_candidate_id;
            
            -- Recompute actual total from Votes table
            SELECT COUNT(*) INTO v_after_total
            FROM Votes v
            JOIN Candidates c ON v.CandidateID = c.CandidateID
            WHERE c.ConstituencyID = v_constituency_id 
              AND v.CandidateID = v_candidate_id;
            
            -- Update Results table with new total
            UPDATE Results
            SET TotalVotes = v_after_total,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE ConstituencyID = v_constituency_id 
              AND CandidateID = v_candidate_id;
            
            -- Create audit key
            v_key := v_constituency_id || '-' || v_candidate_id;
            
            -- Get affected row count
            GET DIAGNOSTICS v_affected_count = ROW_COUNT;
            
            -- Insert audit record
            INSERT INTO Result_AUDIT (bef_total, aft_total, key_col, operation, affected_rows)
            VALUES (COALESCE(v_before_total, 0), COALESCE(v_after_total, 0), v_key, TG_OP, v_affected_count);
        END LOOP;
        
    ELSIF TG_OP = 'INSERT' THEN
        -- For INSERT, use NEW table
        FOR v_constituency_id, v_candidate_id IN 
            SELECT DISTINCT c.ConstituencyID, NEW.CandidateID
            FROM NEW
            JOIN Candidates c ON NEW.CandidateID = c.CandidateID
        LOOP
            -- Get before total
            SELECT TotalVotes INTO v_before_total
            FROM Results
            WHERE ConstituencyID = v_constituency_id 
              AND CandidateID = v_candidate_id;
            
            -- Recompute actual total
            SELECT COUNT(*) INTO v_after_total
            FROM Votes v
            JOIN Candidates c ON v.CandidateID = c.CandidateID
            WHERE c.ConstituencyID = v_constituency_id 
              AND v.CandidateID = v_candidate_id;
            
            -- Update Results table
            UPDATE Results
            SET TotalVotes = v_after_total,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE ConstituencyID = v_constituency_id 
              AND CandidateID = v_candidate_id;
            
            v_key := v_constituency_id || '-' || v_candidate_id;
            GET DIAGNOSTICS v_affected_count = ROW_COUNT;
            
            INSERT INTO Result_AUDIT (bef_total, aft_total, key_col, operation, affected_rows)
            VALUES (COALESCE(v_before_total, 0), COALESCE(v_after_total, 0), v_key, TG_OP, v_affected_count);
        END LOOP;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- For UPDATE, check both OLD and NEW
        FOR v_constituency_id, v_candidate_id IN 
            SELECT DISTINCT c.ConstituencyID, NEW.CandidateID
            FROM NEW
            JOIN Candidates c ON NEW.CandidateID = c.CandidateID
            UNION
            SELECT DISTINCT c.ConstituencyID, OLD.CandidateID
            FROM OLD
            JOIN Candidates c ON OLD.CandidateID = c.CandidateID
        LOOP
            -- Get before total
            SELECT TotalVotes INTO v_before_total
            FROM Results
            WHERE ConstituencyID = v_constituency_id 
              AND CandidateID = v_candidate_id;
            
            -- Recompute actual total
            SELECT COUNT(*) INTO v_after_total
            FROM Votes v
            JOIN Candidates c ON v.CandidateID = c.CandidateID
            WHERE c.ConstituencyID = v_constituency_id 
              AND v.CandidateID = v_candidate_id;
            
            -- Update Results table
            UPDATE Results
            SET TotalVotes = v_after_total,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE ConstituencyID = v_constituency_id 
              AND CandidateID = v_candidate_id;
            
            v_key := v_constituency_id || '-' || v_candidate_id;
            GET DIAGNOSTICS v_affected_count = ROW_COUNT;
            
            INSERT INTO Result_AUDIT (bef_total, aft_total, key_col, operation, affected_rows)
            VALUES (COALESCE(v_before_total, 0), COALESCE(v_after_total, 0), v_key, TG_OP, v_affected_count);
        END LOOP;
    END IF;
    
    RETURN NULL; -- Result is ignored for AFTER trigger
END;
$$ LANGUAGE plpgsql;

-- Step 3: Create statement-level AFTER trigger on Votes table
-- ============================================================================
DROP TRIGGER IF EXISTS trg_audit_result_recomputation ON Votes;

CREATE TRIGGER trg_audit_result_recomputation
    AFTER INSERT OR UPDATE OR DELETE ON Votes
    REFERENCING OLD TABLE AS OLD NEW TABLE AS NEW
    FOR EACH STATEMENT
    EXECUTE FUNCTION audit_result_recomputation();

COMMENT ON TRIGGER trg_audit_result_recomputation ON Votes IS 
    'Statement-level trigger that recomputes denormalized totals in Results table and logs to Result_AUDIT';

-- Step 4: Verification queries
-- ============================================================================
\echo '✓ Result_AUDIT table created'
\echo '✓ audit_result_recomputation() function created'
\echo '✓ trg_audit_result_recomputation trigger created on Votes table'
\echo ''
\echo 'Trigger Configuration:'

SELECT 
    tgname AS trigger_name,
    tgtype AS trigger_type,
    CASE 
        WHEN tgtype & 1 = 1 THEN 'ROW'
        ELSE 'STATEMENT'
    END AS level,
    CASE 
        WHEN tgtype & 2 = 2 THEN 'BEFORE'
        WHEN tgtype & 4 = 4 THEN 'AFTER'
        ELSE 'INSTEAD OF'
    END AS timing,
    CASE 
        WHEN tgtype & 8 = 8 THEN 'INSERT '
        ELSE ''
    END ||
    CASE 
        WHEN tgtype & 16 = 16 THEN 'UPDATE '
        ELSE ''
    END ||
    CASE 
        WHEN tgtype & 32 = 32 THEN 'DELETE '
        ELSE ''
    END AS events,
    pg_get_triggerdef(oid) AS trigger_definition
FROM pg_trigger
WHERE tgname = 'trg_audit_result_recomputation';

\echo ''
\echo 'Ready for B7 testing: Execute mixed DML operations on Votes table'
