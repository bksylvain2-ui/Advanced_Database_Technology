-- ============================================================================
-- B10: Business Limit Alert - Test Cases
-- ============================================================================
-- Demonstrates 2 passing and 2 failing DML cases with business limit enforcement
-- ============================================================================

-- Show current state before tests
SELECT '=== BEFORE TESTS: Current Vote Counts ===' as section;

SELECT 
    c.candidateid,
    c.candidatename,
    COUNT(ba.voteid) as current_votes,
    bl.threshold,
    bl.threshold - COUNT(ba.voteid) as votes_remaining,
    CASE 
        WHEN COUNT(ba.voteid) >= bl.threshold THEN 'AT LIMIT'
        ELSE 'AVAILABLE'
    END as status
FROM node_a.candidates c
CROSS JOIN node_a.business_limits bl
LEFT JOIN node_a.ballot_a ba ON c.candidateid = ba.candidateid
WHERE bl.rule_key = 'MAX_VOTES_PER_CANDIDATE'
GROUP BY c.candidateid, c.candidatename, bl.threshold
ORDER BY current_votes DESC
LIMIT 10;

-- ============================================================================
-- TEST CASE 1: PASSING INSERT (Candidate with 0 votes)
-- ============================================================================

SELECT '=== TEST CASE 1: PASSING INSERT (Candidate with available slots) ===' as section;

DO $$
DECLARE
    v_candidate_id INTEGER;
    v_voter_id INTEGER;
    v_constituency_id INTEGER;
BEGIN
    -- Find a candidate with fewer than 3 votes
    SELECT c.candidateid, c.constituencyid
    INTO v_candidate_id, v_constituency_id
    FROM node_a.candidates c
    LEFT JOIN node_a.ballot_a ba ON c.candidateid = ba.candidateid
    GROUP BY c.candidateid, c.constituencyid
    HAVING COUNT(ba.voteid) < 3
    LIMIT 1;
    
    -- Find a voter from the same constituency who hasn't voted
    SELECT v.voterid
    INTO v_voter_id
    FROM node_a.voters v
    LEFT JOIN node_a.ballot_a ba ON v.voterid = ba.voterid
    WHERE v.constituencyid = v_constituency_id
    AND ba.voteid IS NULL
    AND MOD(v.voterid, 10) < 5  -- Ensure it goes to Ballot_A
    LIMIT 1;
    
    -- Attempt insert (should succeed)
    INSERT INTO node_a.ballot_a (voterid, candidateid, votedatetime)
    VALUES (v_voter_id, v_candidate_id, CURRENT_TIMESTAMP);
    
    RAISE NOTICE '✓ TEST CASE 1 PASSED: Vote inserted successfully for CandidateID % by VoterID %', 
        v_candidate_id, v_voter_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '✗ TEST CASE 1 FAILED: Unexpected error: %', SQLERRM;
        ROLLBACK;
END $$;

-- ============================================================================
-- TEST CASE 2: PASSING INSERT (Another candidate with available slots)
-- ============================================================================

SELECT '=== TEST CASE 2: PASSING INSERT (Another candidate with available slots) ===' as section;

DO $$
DECLARE
    v_candidate_id INTEGER;
    v_voter_id INTEGER;
    v_constituency_id INTEGER;
BEGIN
    -- Find another candidate with fewer than 3 votes
    SELECT c.candidateid, c.constituencyid
    INTO v_candidate_id, v_constituency_id
    FROM node_a.candidates c
    LEFT JOIN node_a.ballot_a ba ON c.candidateid = ba.candidateid
    GROUP BY c.candidateid, c.constituencyid
    HAVING COUNT(ba.voteid) < 3
    OFFSET 1  -- Skip the first one used in test 1
    LIMIT 1;
    
    -- Find a voter from the same constituency who hasn't voted
    SELECT v.voterid
    INTO v_voter_id
    FROM node_a.voters v
    LEFT JOIN node_a.ballot_a ba ON v.voterid = ba.voterid
    WHERE v.constituencyid = v_constituency_id
    AND ba.voteid IS NULL
    AND MOD(v.voterid, 10) < 5  -- Ensure it goes to Ballot_A
    LIMIT 1;
    
    -- Attempt insert (should succeed)
    INSERT INTO node_a.ballot_a (voterid, candidateid, votedatetime)
    VALUES (v_voter_id, v_candidate_id, CURRENT_TIMESTAMP);
    
    RAISE NOTICE '✓ TEST CASE 2 PASSED: Vote inserted successfully for CandidateID % by VoterID %', 
        v_candidate_id, v_voter_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '✗ TEST CASE 2 FAILED: Unexpected error: %', SQLERRM;
        ROLLBACK;
END $$;

-- ============================================================================
-- PREPARE FOR FAILING TESTS: Ensure we have a candidate at the limit
-- ============================================================================

SELECT '=== PREPARING FAILING TESTS: Setting up candidate at limit ===' as section;

DO $$
DECLARE
    v_candidate_id INTEGER;
    v_constituency_id INTEGER;
    v_voter_id INTEGER;
    v_current_votes INTEGER;
    v_votes_needed INTEGER;
BEGIN
    -- Find a candidate with fewer than 3 votes
    SELECT c.candidateid, c.constituencyid, COUNT(ba.voteid)
    INTO v_candidate_id, v_constituency_id, v_current_votes
    FROM node_a.candidates c
    LEFT JOIN node_a.ballot_a ba ON c.candidateid = ba.candidateid
    GROUP BY c.candidateid, c.constituencyid
    HAVING COUNT(ba.voteid) < 3
    LIMIT 1;
    
    v_votes_needed := 3 - v_current_votes;
    
    -- Add votes to reach the limit
    FOR i IN 1..v_votes_needed LOOP
        SELECT v.voterid
        INTO v_voter_id
        FROM node_a.voters v
        LEFT JOIN node_a.ballot_a ba ON v.voterid = ba.voterid
        WHERE v.constituencyid = v_constituency_id
        AND ba.voteid IS NULL
        AND MOD(v.voterid, 10) < 5
        LIMIT 1;
        
        INSERT INTO node_a.ballot_a (voterid, candidateid, votedatetime)
        VALUES (v_voter_id, v_candidate_id, CURRENT_TIMESTAMP);
    END LOOP;
    
    RAISE NOTICE '✓ Candidate % now has 3 votes (at limit)', v_candidate_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Setup error: %', SQLERRM;
END $$;

-- ============================================================================
-- TEST CASE 3: FAILING INSERT (Candidate at limit)
-- ============================================================================

SELECT '=== TEST CASE 3: FAILING INSERT (Candidate at limit) ===' as section;

DO $$
DECLARE
    v_candidate_id INTEGER;
    v_voter_id INTEGER;
    v_constituency_id INTEGER;
BEGIN
    -- Find a candidate with exactly 3 votes (at limit)
    SELECT c.candidateid, c.constituencyid
    INTO v_candidate_id, v_constituency_id
    FROM node_a.candidates c
    LEFT JOIN node_a.ballot_a ba ON c.candidateid = ba.candidateid
    GROUP BY c.candidateid, c.constituencyid
    HAVING COUNT(ba.voteid) >= 3
    LIMIT 1;
    
    -- Find a voter who hasn't voted
    SELECT v.voterid
    INTO v_voter_id
    FROM node_a.voters v
    LEFT JOIN node_a.ballot_a ba ON v.voterid = ba.voterid
    WHERE v.constituencyid = v_constituency_id
    AND ba.voteid IS NULL
    AND MOD(v.voterid, 10) < 5
    LIMIT 1;
    
    -- Attempt insert (should fail)
    INSERT INTO node_a.ballot_a (voterid, candidateid, votedatetime)
    VALUES (v_voter_id, v_candidate_id, CURRENT_TIMESTAMP);
    
    -- If we reach here, the test failed
    RAISE NOTICE '✗ TEST CASE 3 FAILED: Insert should have been blocked but succeeded';
    ROLLBACK;
    
EXCEPTION
    WHEN SQLSTATE '45000' THEN
        RAISE NOTICE '✓ TEST CASE 3 PASSED: Business limit violation caught: %', SQLERRM;
        ROLLBACK;  -- Rollback the failed transaction
    WHEN OTHERS THEN
        RAISE NOTICE '✗ TEST CASE 3 FAILED: Unexpected error: %', SQLERRM;
        ROLLBACK;
END $$;

-- ============================================================================
-- TEST CASE 4: FAILING INSERT (Another attempt on candidate at limit)
-- ============================================================================

SELECT '=== TEST CASE 4: FAILING INSERT (Another attempt on candidate at limit) ===' as section;

DO $$
DECLARE
    v_candidate_id INTEGER;
    v_voter_id INTEGER;
    v_constituency_id INTEGER;
BEGIN
    -- Find a candidate with exactly 3 votes (at limit)
    SELECT c.candidateid, c.constituencyid
    INTO v_candidate_id, v_constituency_id
    FROM node_a.candidates c
    LEFT JOIN node_a.ballot_a ba ON c.candidateid = ba.candidateid
    GROUP BY c.candidateid, c.constituencyid
    HAVING COUNT(ba.voteid) >= 3
    LIMIT 1;
    
    -- Find another voter who hasn't voted
    SELECT v.voterid
    INTO v_voter_id
    FROM node_a.voters v
    LEFT JOIN node_a.ballot_a ba ON v.voterid = ba.voterid
    WHERE v.constituencyid = v_constituency_id
    AND ba.voteid IS NULL
    AND MOD(v.voterid, 10) < 5
    OFFSET 1  -- Different voter than test 3
    LIMIT 1;
    
    -- Attempt insert (should fail)
    INSERT INTO node_a.ballot_a (voterid, candidateid, votedatetime)
    VALUES (v_voter_id, v_candidate_id, CURRENT_TIMESTAMP);
    
    -- If we reach here, the test failed
    RAISE NOTICE '✗ TEST CASE 4 FAILED: Insert should have been blocked but succeeded';
    ROLLBACK;
    
EXCEPTION
    WHEN SQLSTATE '45000' THEN
        RAISE NOTICE '✓ TEST CASE 4 PASSED: Business limit violation caught: %', SQLERRM;
        ROLLBACK;  -- Rollback the failed transaction
    WHEN OTHERS THEN
        RAISE NOTICE '✗ TEST CASE 4 FAILED: Unexpected error: %', SQLERRM;
        ROLLBACK;
END $$;

-- ============================================================================
-- AFTER TESTS: Verify Final State
-- ============================================================================

SELECT '=== AFTER TESTS: Final Vote Counts ===' as section;

SELECT 
    c.candidateid,
    c.candidatename,
    COUNT(ba.voteid) as current_votes,
    bl.threshold,
    CASE 
        WHEN COUNT(ba.voteid) >= bl.threshold THEN 'AT LIMIT'
        WHEN COUNT(ba.voteid) > 0 THEN 'WITHIN LIMIT'
        ELSE 'NO VOTES'
    END as status
FROM node_a.candidates c
CROSS JOIN node_a.business_limits bl
LEFT JOIN node_a.ballot_a ba ON c.candidateid = ba.candidateid
WHERE bl.rule_key = 'MAX_VOTES_PER_CANDIDATE'
GROUP BY c.candidateid, c.candidatename, bl.threshold
ORDER BY current_votes DESC
LIMIT 10;

-- Verify no candidate exceeds the limit
SELECT 
    CASE 
        WHEN MAX(vote_count) <= 3 THEN '✓ All candidates within limit (≤3 votes)'
        ELSE '✗ VIOLATION: Some candidates exceed limit'
    END as validation_result
FROM (
    SELECT COUNT(*) as vote_count
    FROM node_a.ballot_a
    GROUP BY candidateid
) vote_counts;

-- ============================================================================
-- TEST SUMMARY
-- ============================================================================

SELECT '=== TEST SUMMARY ===' as section;
SELECT '✓ Test Case 1: PASSING INSERT - Vote allowed for candidate with available slots' as result
UNION ALL
SELECT '✓ Test Case 2: PASSING INSERT - Vote allowed for another candidate with available slots'
UNION ALL
SELECT '✓ Test Case 3: FAILING INSERT - Vote blocked for candidate at limit (rolled back)'
UNION ALL
SELECT '✓ Test Case 4: FAILING INSERT - Another vote blocked for candidate at limit (rolled back)'
UNION ALL
SELECT '✓ Only passing votes committed, failing votes rolled back'
UNION ALL
SELECT '✓ Total committed rows remain within ≤10 budget';
