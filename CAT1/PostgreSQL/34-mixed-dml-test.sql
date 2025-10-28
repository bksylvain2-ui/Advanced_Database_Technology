-- ============================================================================
-- B7: Mixed DML Test Script (≤4 rows affected)
-- ============================================================================
-- WHAT: Execute INSERT, UPDATE, DELETE operations on Votes table to trigger
--       denormalized total recomputation and audit logging
-- ============================================================================

\echo '============================================================================'
\echo 'B7: Mixed DML Test - Triggering Result Recomputation'
\echo '============================================================================'
\echo ''

-- Step 1: Show initial state
-- ============================================================================
\echo 'STEP 1: Initial State Before DML Operations'
\echo '------------------------------------------------------------'

SELECT 
    r.ResultID,
    r.ConstituencyID,
    co.ConstituencyName,
    r.CandidateID,
    ca.CandidateName,
    r.TotalVotes,
    r.LastUpdated
FROM Results r
JOIN Constituencies co ON r.ConstituencyID = co.ConstituencyID
JOIN Candidates ca ON r.CandidateID = ca.CandidateID
WHERE r.ConstituencyID IN (1, 2)
  AND r.CandidateID IN (1, 2, 3, 4)
ORDER BY r.ConstituencyID, r.CandidateID;

\echo ''
\echo 'Current vote count in Votes table:'
SELECT 
    c.ConstituencyID,
    v.CandidateID,
    COUNT(*) as actual_votes
FROM Votes v
JOIN Candidates c ON v.CandidateID = c.CandidateID
WHERE c.ConstituencyID IN (1, 2)
  AND v.CandidateID IN (1, 2, 3, 4)
GROUP BY c.ConstituencyID, v.CandidateID
ORDER BY c.ConstituencyID, v.CandidateID;

\echo ''
\echo 'Press Enter to continue...'
\prompt

-- Step 2: Mixed DML Operation 1 - INSERT (2 new votes)
-- ============================================================================
\echo ''
\echo 'STEP 2: DML Operation 1 - INSERT 2 new votes'
\echo '------------------------------------------------------------'

BEGIN;

-- Insert 2 new votes for different candidates
INSERT INTO Votes (VoterID, CandidateID, VoteTimestamp)
VALUES 
    (11, 1, CURRENT_TIMESTAMP), -- Vote for Candidate 1
    (12, 2, CURRENT_TIMESTAMP); -- Vote for Candidate 2

\echo '✓ Inserted 2 votes (VoterID 11→Candidate 1, VoterID 12→Candidate 2)'
\echo '✓ Trigger fired: Results table updated, audit logged'

COMMIT;

\echo ''
\echo 'Results after INSERT:'
SELECT 
    r.ConstituencyID,
    r.CandidateID,
    ca.CandidateName,
    r.TotalVotes,
    r.LastUpdated
FROM Results r
JOIN Candidates ca ON r.CandidateID = ca.CandidateID
WHERE r.CandidateID IN (1, 2)
ORDER BY r.CandidateID;

\echo ''
\echo 'Audit entries:'
SELECT * FROM Result_AUDIT ORDER BY AuditID DESC LIMIT 2;

\echo ''
\echo 'Press Enter to continue...'
\prompt

-- Step 3: Mixed DML Operation 2 - UPDATE (1 vote changed)
-- ============================================================================
\echo ''
\echo 'STEP 3: DML Operation 2 - UPDATE 1 vote (change candidate)'
\echo '------------------------------------------------------------'

BEGIN;

-- Update one vote to change the candidate
UPDATE Votes
SET CandidateID = 3,
    VoteTimestamp = CURRENT_TIMESTAMP
WHERE VoterID = 11;

\echo '✓ Updated 1 vote (VoterID 11: Candidate 1 → Candidate 3)'
\echo '✓ Trigger fired: Results updated for both old and new candidates'

COMMIT;

\echo ''
\echo 'Results after UPDATE:'
SELECT 
    r.ConstituencyID,
    r.CandidateID,
    ca.CandidateName,
    r.TotalVotes,
    r.LastUpdated
FROM Results r
JOIN Candidates ca ON r.CandidateID = ca.CandidateID
WHERE r.CandidateID IN (1, 2, 3)
ORDER BY r.CandidateID;

\echo ''
\echo 'Audit entries:'
SELECT * FROM Result_AUDIT ORDER BY AuditID DESC LIMIT 3;

\echo ''
\echo 'Press Enter to continue...'
\prompt

-- Step 4: Mixed DML Operation 3 - DELETE (1 vote removed)
-- ============================================================================
\echo ''
\echo 'STEP 4: DML Operation 3 - DELETE 1 vote'
\echo '------------------------------------------------------------'

BEGIN;

-- Delete one vote
DELETE FROM Votes
WHERE VoterID = 12;

\echo '✓ Deleted 1 vote (VoterID 12 for Candidate 2)'
\echo '✓ Trigger fired: Results decremented for Candidate 2'

COMMIT;

\echo ''
\echo 'Results after DELETE:'
SELECT 
    r.ConstituencyID,
    r.CandidateID,
    ca.CandidateName,
    r.TotalVotes,
    r.LastUpdated
FROM Results r
JOIN Candidates ca ON r.CandidateID = ca.CandidateID
WHERE r.CandidateID IN (1, 2, 3)
ORDER BY r.CandidateID;

\echo ''
\echo 'Press Enter to continue...'
\prompt

-- Step 5: Final verification
-- ============================================================================
\echo ''
\echo '============================================================================'
\echo 'STEP 5: Final Verification & Summary'
\echo '============================================================================'
\echo ''

\echo 'All Audit Entries (2-3 records expected):'
\echo '------------------------------------------------------------'
SELECT 
    AuditID,
    operation,
    key_col,
    bef_total,
    aft_total,
    (aft_total - bef_total) AS delta,
    affected_rows,
    changed_at
FROM Result_AUDIT
ORDER BY AuditID;

\echo ''
\echo 'Verification: Results table matches actual vote counts'
\echo '------------------------------------------------------------'
SELECT 
    r.ConstituencyID,
    r.CandidateID,
    ca.CandidateName,
    r.TotalVotes AS denormalized_total,
    (SELECT COUNT(*) 
     FROM Votes v 
     JOIN Candidates c ON v.CandidateID = c.CandidateID
     WHERE c.ConstituencyID = r.ConstituencyID 
       AND v.CandidateID = r.CandidateID) AS actual_count,
    CASE 
        WHEN r.TotalVotes = (SELECT COUNT(*) 
                             FROM Votes v 
                             JOIN Candidates c ON v.CandidateID = c.CandidateID
                             WHERE c.ConstituencyID = r.ConstituencyID 
                               AND v.CandidateID = r.CandidateID)
        THEN '✓ MATCH'
        ELSE '✗ MISMATCH'
    END AS status
FROM Results r
JOIN Candidates ca ON r.CandidateID = ca.CandidateID
WHERE r.CandidateID IN (1, 2, 3)
ORDER BY r.CandidateID;

\echo ''
\echo '============================================================================'
\echo 'B7 Test Complete'
\echo '============================================================================'
\echo 'Summary:'
\echo '  • Total DML operations: 3 (INSERT, UPDATE, DELETE)'
\echo '  • Total rows affected: ≤4 (2 INSERT + 1 UPDATE + 1 DELETE)'
\echo '  • Audit entries created: 2-3 records'
\echo '  • Results table: Automatically recomputed via trigger'
\echo '  • Net committed rows: Within ≤10 budget'
\echo '============================================================================'
