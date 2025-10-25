-- ============================================================================
-- Script 03: Queries for Various Tasks
-- ============================================================================
-- Query 1: Retrieve total votes per candidate per constituency
-- ============================================================================
SELECT 
    co.Name AS Constituency,
    co.Region,
    c.FullName AS Candidate,
    p.PartyName AS Party,
    COUNT(b.BallotID) AS TotalVotes
FROM 
    Candidate c
    INNER JOIN Party p ON c.PartyID = p.PartyID
    INNER JOIN Constituency co ON c.ConstituencyID = co.ConstituencyID
    LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID AND b.Validity = 'Valid'
GROUP BY 
    co.Name, co.Region, c.FullName, p.PartyName, c.CandidateID
ORDER BY 
    co.Name, TotalVotes DESC;

-- ============================================================================
-- Query 2: Update declared results after tally completion
-- This updates the Result table with actual vote counts
-- ============================================================================
UPDATE Result r
SET 
    TotalVotes = (
        SELECT COUNT(*)
        FROM Ballot b
        WHERE b.CandidateID = r.CandidateID 
        AND b.Validity = 'Valid'
    ),
    DeclaredDate = CURRENT_TIMESTAMP
WHERE r.DeclaredDate IS NULL;

-- Verify the update
SELECT 
    c.FullName AS Candidate,
    p.PartyName AS Party,
    co.Name AS Constituency,
    r.TotalVotes,
    r.DeclaredDate
FROM 
    Result r
    INNER JOIN Candidate c ON r.CandidateID = c.CandidateID
    INNER JOIN Party p ON c.PartyID = p.PartyID
    INNER JOIN Constituency co ON c.ConstituencyID = co.ConstituencyID
ORDER BY 
    co.Name, r.TotalVotes DESC;

-- ============================================================================
-- Query 3: Identify winning candidates per region/constituency
-- ============================================================================
WITH RankedCandidates AS (
    SELECT 
        co.Name AS Constituency,
        co.Region,
        c.FullName AS Candidate,
        p.PartyName AS Party,
        r.TotalVotes,
        ROW_NUMBER() OVER (PARTITION BY co.ConstituencyID ORDER BY r.TotalVotes DESC) AS Rank
    FROM 
        Result r
        INNER JOIN Candidate c ON r.CandidateID = c.CandidateID
        INNER JOIN Party p ON c.PartyID = p.PartyID
        INNER JOIN Constituency co ON c.ConstituencyID = co.ConstituencyID
)
SELECT 
    Constituency,
    Region,
    Candidate AS Winner,
    Party,
    TotalVotes
FROM 
    RankedCandidates
WHERE 
    Rank = 1
ORDER BY 
    Region, Constituency;

-- ============================================================================
-- Query 4: Voter turnout analysis per constituency
-- ============================================================================
SELECT 
    co.Name AS Constituency,
    co.Region,
    co.RegisteredVoters,
    COUNT(DISTINCT b.VoterID) AS VotersTurnedOut,
    ROUND((COUNT(DISTINCT b.VoterID)::NUMERIC / co.RegisteredVoters) * 100, 2) AS TurnoutPercentage
FROM 
    Constituency co
    LEFT JOIN Voter v ON co.ConstituencyID = v.ConstituencyID
    LEFT JOIN Ballot b ON v.VoterID = b.VoterID AND b.Validity = 'Valid'
GROUP BY 
    co.ConstituencyID, co.Name, co.Region, co.RegisteredVoters
ORDER BY 
    TurnoutPercentage DESC;

-- ============================================================================
-- Query 5: Invalid/Disputed ballots report
-- ============================================================================
SELECT 
    b.BallotID,
    v.FullName AS Voter,
    v.NationalID,
    c.FullName AS Candidate,
    co.Name AS Constituency,
    b.VoteDate,
    b.Validity
FROM 
    Ballot b
    INNER JOIN Voter v ON b.VoterID = v.VoterID
    INNER JOIN Candidate c ON b.CandidateID = c.CandidateID
    INNER JOIN Constituency co ON v.ConstituencyID = co.ConstituencyID
WHERE 
    b.Validity IN ('Invalid', 'Disputed')
ORDER BY 
    b.VoteDate DESC;

-- ============================================================================
-- Queries Complete
-- ============================================================================
