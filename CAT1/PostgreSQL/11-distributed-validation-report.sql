-- ============================================================================
-- COMPREHENSIVE VALIDATION REPORT FOR DISTRIBUTED BALLOT FRAGMENTATION
-- ============================================================================
-- This script generates a complete validation report to verify:
-- 1. Correct row counts across fragments
-- 2. Checksum integrity
-- 3. Fragmentation rule compliance
-- 4. Data consistency
-- ============================================================================

\echo '============================================================================'
\echo 'DISTRIBUTED DATABASE VALIDATION REPORT'
\echo 'Ballot Table Horizontal Fragmentation (Node_A & Node_B)'
\echo '============================================================================'
\echo ''

-- Set output format for better readability
\pset border 2
\pset format wrapped

-- ----------------------------------------------------------------------------
-- SECTION 1: ROW COUNT VALIDATION
-- ----------------------------------------------------------------------------
\echo '1. ROW COUNT VALIDATION'
\echo '------------------------'

SELECT 
    fragment_name,
    row_count,
    CASE 
        WHEN fragment_name = 'Ballot_ALL (Combined)' AND row_count = 10 THEN '✓ PASS'
        WHEN fragment_name LIKE 'Ballot_% (Node%)' AND row_count = 5 THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS status
FROM (
    SELECT 'Ballot_A (Node_A)' AS fragment_name, COUNT(*) AS row_count FROM Ballot_A
    UNION ALL
    SELECT 'Ballot_B (Node_B)', COUNT(*) FROM Ballot_B
    UNION ALL
    SELECT 'Ballot_ALL (Combined)', COUNT(*) FROM Ballot_ALL
) counts
ORDER BY 
    CASE fragment_name
        WHEN 'Ballot_A (Node_A)' THEN 1
        WHEN 'Ballot_B (Node_B)' THEN 2
        WHEN 'Ballot_ALL (Combined)' THEN 3
    END;

\echo ''

-- ----------------------------------------------------------------------------
-- SECTION 2: CHECKSUM VALIDATION (MOD 97)
-- ----------------------------------------------------------------------------
\echo '2. CHECKSUM VALIDATION (MOD 97)'
\echo '--------------------------------'

WITH checksums AS (
    SELECT 
        'Ballot_A (Node_A)' AS fragment,
        SUM(MOD(VoteID, 97)) AS checksum,
        COUNT(*) AS rows
    FROM Ballot_A
    
    UNION ALL
    
    SELECT 
        'Ballot_B (Node_B)',
        SUM(MOD(VoteID, 97)),
        COUNT(*)
    FROM Ballot_B
    
    UNION ALL
    
    SELECT 
        'Ballot_ALL (Combined)',
        SUM(MOD(VoteID, 97)),
        COUNT(*)
    FROM Ballot_ALL
    
    UNION ALL
    
    SELECT 
        'Expected (A + B)',
        (SELECT SUM(MOD(VoteID, 97)) FROM Ballot_A) + 
        (SELECT SUM(MOD(VoteID, 97)) FROM Ballot_B),
        (SELECT COUNT(*) FROM Ballot_A) + 
        (SELECT COUNT(*) FROM Ballot_B)
)
SELECT 
    fragment,
    checksum,
    rows,
    CASE 
        WHEN fragment = 'Ballot_ALL (Combined)' AND 
             checksum = (SELECT checksum FROM checksums WHERE fragment = 'Expected (A + B)')
        THEN '✓ PASS'
        WHEN fragment = 'Expected (A + B)' THEN '✓ REFERENCE'
        ELSE '—'
    END AS status
FROM checksums
ORDER BY 
    CASE fragment
        WHEN 'Ballot_A (Node_A)' THEN 1
        WHEN 'Ballot_B (Node_B)' THEN 2
        WHEN 'Expected (A + B)' THEN 3
        WHEN 'Ballot_ALL (Combined)' THEN 4
    END;

\echo ''

-- ----------------------------------------------------------------------------
-- SECTION 3: FRAGMENTATION RULE COMPLIANCE
-- ----------------------------------------------------------------------------
\echo '3. FRAGMENTATION RULE COMPLIANCE'
\echo '---------------------------------'
\echo 'Rule: VoterID with EVEN last digit → Node_A'
\echo '      VoterID with ODD last digit → Node_B'
\echo ''

SELECT 
    test_name,
    total_rows,
    expected_rows,
    violating_rows,
    CASE 
        WHEN violating_rows = 0 THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS status
FROM (
    SELECT 
        'Ballot_A (EVEN only)' AS test_name,
        COUNT(*) AS total_rows,
        COUNT(*) FILTER (WHERE MOD(VoterID, 10) IN (0,2,4,6,8)) AS expected_rows,
        COUNT(*) FILTER (WHERE MOD(VoterID, 10) IN (1,3,5,7,9)) AS violating_rows
    FROM Ballot_A
    
    UNION ALL
    
    SELECT 
        'Ballot_B (ODD only)',
        COUNT(*),
        COUNT(*) FILTER (WHERE MOD(VoterID, 10) IN (1,3,5,7,9)),
        COUNT(*) FILTER (WHERE MOD(VoterID, 10) IN (0,2,4,6,8))
    FROM Ballot_B
) compliance;

\echo ''

-- ----------------------------------------------------------------------------
-- SECTION 4: DATA DISTRIBUTION ANALYSIS
-- ----------------------------------------------------------------------------
\echo '4. DATA DISTRIBUTION ANALYSIS'
\echo '------------------------------'

SELECT 
    SourceNode AS node,
    vote_count,
    ROUND(percentage, 2) || '%' AS percentage,
    CASE 
        WHEN percentage BETWEEN 45 AND 55 THEN '✓ BALANCED'
        ELSE '⚠ IMBALANCED'
    END AS balance_status
FROM (
    SELECT 
        SourceNode,
        COUNT(*) AS vote_count,
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Ballot_ALL) AS percentage
    FROM Ballot_ALL
    GROUP BY SourceNode
) distribution
ORDER BY SourceNode;

\echo ''

-- ----------------------------------------------------------------------------
-- SECTION 5: DETAILED DATA SAMPLE
-- ----------------------------------------------------------------------------
\echo '5. DETAILED DATA SAMPLE (All 10 Rows)'
\echo '--------------------------------------'

SELECT 
    VoteID,
    VoterID,
    MOD(VoterID, 10) AS last_digit,
    CandidateID,
    ConstituencyID,
    TO_CHAR(VoteTimestamp, 'YYYY-MM-DD HH24:MI') AS vote_time,
    SourceNode
FROM Ballot_ALL
ORDER BY VoterID;

\echo ''

-- ----------------------------------------------------------------------------
-- SECTION 6: UNION ALL VERIFICATION
-- ----------------------------------------------------------------------------
\echo '6. UNION ALL VERIFICATION'
\echo '--------------------------'
\echo 'Verifying that Ballot_ALL correctly combines both fragments'
\echo ''

WITH fragment_union AS (
    SELECT VoteID, VoterID, CandidateID FROM Ballot_A
    UNION ALL
    SELECT VoteID, VoterID, CandidateID FROM Ballot_B
),
view_data AS (
    SELECT VoteID, VoterID, CandidateID FROM Ballot_ALL
)
SELECT 
    'Row Count Match' AS test,
    (SELECT COUNT(*) FROM fragment_union) AS manual_union_count,
    (SELECT COUNT(*) FROM view_data) AS view_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM fragment_union) = (SELECT COUNT(*) FROM view_data)
        THEN '✓ PASS'
        ELSE '✗ FAIL'
    END AS status;

\echo ''

-- ----------------------------------------------------------------------------
-- SECTION 7: SUMMARY REPORT
-- ----------------------------------------------------------------------------
\echo '7. SUMMARY REPORT'
\echo '------------------'

SELECT 
    'Total Rows in System' AS metric,
    (SELECT COUNT(*) FROM Ballot_ALL)::TEXT AS value
UNION ALL
SELECT 
    'Rows on Node_A',
    (SELECT COUNT(*) FROM Ballot_A)::TEXT
UNION ALL
SELECT 
    'Rows on Node_B',
    (SELECT COUNT(*) FROM Ballot_B)::TEXT
UNION ALL
SELECT 
    'Fragmentation Method',
    'HASH (MOD VoterID, 10)'
UNION ALL
SELECT 
    'Recombination Method',
    'UNION ALL via Ballot_ALL view'
UNION ALL
SELECT 
    'Database Link',
    'postgres_fdw (node_b_server)'
UNION ALL
SELECT 
    'Data Integrity',
    CASE 
        WHEN (SELECT COUNT(*) FROM Ballot_ALL) = 
             (SELECT COUNT(*) FROM Ballot_A) + (SELECT COUNT(*) FROM Ballot_B)
        THEN '✓ VERIFIED'
        ELSE '✗ FAILED'
    END;

\echo ''
\echo '============================================================================'
\echo 'END OF VALIDATION REPORT'
\echo '============================================================================'
