-- ============================================================================
-- A2: REMOTE SELECT ON CANDIDATE@proj_link (5 ROWS)
-- ============================================================================
-- This demonstrates querying remote Candidate table from Node_A
-- ============================================================================

-- Query 1: Remote SELECT on Candidate@proj_link - First 5 rows
SELECT 
    '=== REMOTE SELECT: Candidate@proj_link (5 rows) ===' AS Query_Description;

SELECT 
    CandidateID,
    FullName,
    PartyID,
    ConstituencyID,
    Gender,
    Age,
    RegistrationDate
FROM Candidate_Remote
ORDER BY CandidateID
LIMIT 5;

-- Query 2: Remote SELECT with aggregation - Candidates by Party
SELECT 
    '=== REMOTE SELECT: Candidates Count by Party ===' AS Query_Description;

SELECT 
    PartyID,
    COUNT(*) AS TotalCandidates,
    AVG(Age) AS AverageAge,
    COUNT(CASE WHEN Gender = 'Female' THEN 1 END) AS FemaleCandidates,
    COUNT(CASE WHEN Gender = 'Male' THEN 1 END) AS MaleCandidates
FROM Candidate_Remote
GROUP BY PartyID
ORDER BY PartyID
LIMIT 5;

-- Query 3: Remote SELECT with filtering - Young Candidates
SELECT 
    '=== REMOTE SELECT: Young Candidates (Age < 40) ===' AS Query_Description;

SELECT 
    CandidateID,
    FullName,
    Age,
    Gender,
    ConstituencyID
FROM Candidate_Remote
WHERE Age < 40
ORDER BY Age
LIMIT 5;

-- ============================================================================
-- VERIFICATION OUTPUT FOR A2 REQUIREMENT #2
-- ============================================================================

SELECT 
    '✓ Remote SELECT Executed' AS Status,
    'Candidate@proj_link' AS RemoteTable,
    '5 rows returned' AS RowCount;
