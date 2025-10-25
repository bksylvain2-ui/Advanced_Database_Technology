-- ============================================================================
-- Script 07: Additional Useful Queries and Reports
-- ============================================================================
-- Query 1: Gender-based voting analysis
-- ============================================================================
SELECT 
    co.Name AS Constituency,
    v.Gender,
    COUNT(b.BallotID) AS TotalVotes,
    ROUND((COUNT(b.BallotID)::NUMERIC / SUM(COUNT(b.BallotID)) OVER (PARTITION BY co.ConstituencyID)) * 100, 2) AS PercentageOfConstituency
FROM 
    Constituency co
    INNER JOIN Voter v ON co.ConstituencyID = v.ConstituencyID
    INNER JOIN Ballot b ON v.VoterID = b.VoterID AND b.Validity = 'Valid'
GROUP BY 
    co.ConstituencyID, co.Name, v.Gender
ORDER BY 
    co.Name, v.Gender;

-- ============================================================================
-- Query 2: Hourly voting pattern analysis
-- ============================================================================
SELECT 
    EXTRACT(HOUR FROM b.VoteDate) AS VotingHour,
    COUNT(b.BallotID) AS TotalVotes,
    ROUND((COUNT(b.BallotID)::NUMERIC / SUM(COUNT(b.BallotID)) OVER ()) * 100, 2) AS PercentageOfTotal
FROM 
    Ballot b
WHERE 
    b.Validity = 'Valid'
GROUP BY 
    EXTRACT(HOUR FROM b.VoteDate)
ORDER BY 
    VotingHour;

-- ============================================================================
-- Query 3: Party performance by constituency
-- ============================================================================
SELECT 
    co.Name AS Constituency,
    p.PartyName,
    COUNT(b.BallotID) AS Votes,
    ROUND((COUNT(b.BallotID)::NUMERIC / SUM(COUNT(b.BallotID)) OVER (PARTITION BY co.ConstituencyID)) * 100, 2) AS PercentageInConstituency
FROM 
    Constituency co
    INNER JOIN Candidate c ON co.ConstituencyID = c.ConstituencyID
    INNER JOIN Party p ON c.PartyID = p.PartyID
    LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID AND b.Validity = 'Valid'
GROUP BY 
    co.ConstituencyID, co.Name, p.PartyID, p.PartyName
ORDER BY 
    co.Name, Votes DESC;

-- ============================================================================
-- Query 4: Candidates with no votes
-- ============================================================================
SELECT 
    c.FullName AS Candidate,
    p.PartyName AS Party,
    co.Name AS Constituency,
    r.TotalVotes
FROM 
    Candidate c
    INNER JOIN Party p ON c.PartyID = p.PartyID
    INNER JOIN Constituency co ON c.ConstituencyID = co.ConstituencyID
    INNER JOIN Result r ON c.CandidateID = r.CandidateID
WHERE 
    r.TotalVotes = 0
ORDER BY 
    co.Name, p.PartyName;

-- ============================================================================
-- Query 5: Complete election summary report
-- ============================================================================
SELECT 
    'Total Constituencies' AS Metric,
    COUNT(*)::TEXT AS Value
FROM Constituency

UNION ALL

SELECT 
    'Total Registered Voters',
    SUM(RegisteredVoters)::TEXT
FROM Constituency

UNION ALL

SELECT 
    'Total Active Voters',
    COUNT(*)::TEXT
FROM Voter
WHERE Status = 'Active'

UNION ALL

SELECT 
    'Total Political Parties',
    COUNT(*)::TEXT
FROM Party

UNION ALL

SELECT 
    'Total Candidates',
    COUNT(*)::TEXT
FROM Candidate

UNION ALL

SELECT 
    'Total Valid Votes Cast',
    COUNT(*)::TEXT
FROM Ballot
WHERE Validity = 'Valid'

UNION ALL

SELECT 
    'Total Invalid/Disputed Votes',
    COUNT(*)::TEXT
FROM Ballot
WHERE Validity IN ('Invalid', 'Disputed')

UNION ALL

SELECT 
    'Overall Voter Turnout %',
    ROUND((COUNT(DISTINCT b.VoterID)::NUMERIC / SUM(c.RegisteredVoters)) * 100, 2)::TEXT
FROM Ballot b
CROSS JOIN (SELECT SUM(RegisteredVoters) AS RegisteredVoters FROM Constituency) c
WHERE b.Validity = 'Valid';

-- ============================================================================
-- Query 6: Winners summary across all constituencies
-- ============================================================================
WITH Winners AS (
    SELECT 
        co.Name AS Constituency,
        co.Region,
        c.FullName AS Winner,
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
    Winner,
    Party,
    TotalVotes
FROM Winners
WHERE Rank = 1
ORDER BY TotalVotes DESC;

-- ============================================================================
-- Additional Queries Complete
-- ============================================================================
