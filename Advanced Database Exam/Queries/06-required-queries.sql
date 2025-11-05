-- Required Queries for Rwanda E-Voting System
-- Explicitly addresses tasks 4, 5, and 6 from requirements

-- ============================================
-- TASK 4: Retrieve Total Votes per Candidate per Constituency
-- ============================================

-- Query 4.1: Total votes for each candidate in their constituency
SELECT 
    c.CandidateID,
    c.CandidateName,
    p.PartyName,
    const.ConstituencyID,
    const.ConstituencyName,
    const.Province,
    COUNT(v.VoteID) AS TotalVotes
FROM 
    Candidates c
INNER JOIN 
    Parties p ON c.PartyID = p.PartyID
INNER JOIN 
    Constituencies const ON c.ConstituencyID = const.ConstituencyID
LEFT JOIN 
    Votes v ON c.CandidateID = v.CandidateID
GROUP BY 
    c.CandidateID, c.CandidateName, p.PartyName, 
    const.ConstituencyID, const.ConstituencyName, const.Province
ORDER BY 
    const.ConstituencyName, TotalVotes DESC;

-- Query 4.2: Total votes per candidate for a specific constituency (e.g., Gasabo)
SELECT 
    c.CandidateID,
    c.CandidateName,
    p.PartyName,
    COUNT(v.VoteID) AS TotalVotes,
    ROUND((COUNT(v.VoteID)::DECIMAL / 
        (SELECT COUNT(*) FROM Votes WHERE ConstituencyID = 1) * 100), 2) AS VotePercentage
FROM 
    Candidates c
INNER JOIN 
    Parties p ON c.PartyID = p.PartyID
LEFT JOIN 
    Votes v ON c.CandidateID = v.CandidateID
WHERE 
    c.ConstituencyID = 1  -- Change this to query different constituencies
GROUP BY 
    c.CandidateID, c.CandidateName, p.PartyName
ORDER BY 
    TotalVotes DESC;

-- Query 4.3: Using the existing view for candidate performance
SELECT 
    CandidateName,
    PartyName,
    ConstituencyName,
    Province,
    TotalVotes,
    VotePercentage,
    RankInConstituency
FROM 
    CandidatePerformanceByConstituency
ORDER BY 
    ConstituencyName, RankInConstituency;

-- ============================================
-- TASK 5: Update Declared Results After Tally Completion
-- ============================================

-- Note: Results are automatically updated via triggers when votes are cast
-- However, here are manual UPDATE queries for specific scenarios:

-- Query 5.1: Manually recalculate and update results for a specific constituency
UPDATE Results r
SET 
    TotalVotes = (
        SELECT COUNT(*) 
        FROM Votes v 
        WHERE v.CandidateID = r.CandidateID 
        AND v.ConstituencyID = r.ConstituencyID
    ),
    VotePercentage = ROUND(
        (SELECT COUNT(*)::DECIMAL 
         FROM Votes v 
         WHERE v.CandidateID = r.CandidateID 
         AND v.ConstituencyID = r.ConstituencyID) / 
        NULLIF((SELECT COUNT(*) 
                FROM Votes v2 
                WHERE v2.ConstituencyID = r.ConstituencyID), 0) * 100, 
        2
    ),
    LastUpdated = CURRENT_TIMESTAMP
WHERE 
    r.ConstituencyID = 1;  -- Change to update specific constituency

-- Query 5.2: Update results for all constituencies (full tally update)
UPDATE Results r
SET 
    TotalVotes = (
        SELECT COUNT(*) 
        FROM Votes v 
        WHERE v.CandidateID = r.CandidateID 
        AND v.ConstituencyID = r.ConstituencyID
    ),
    VotePercentage = ROUND(
        (SELECT COUNT(*)::DECIMAL 
         FROM Votes v 
         WHERE v.CandidateID = r.CandidateID 
         AND v.ConstituencyID = r.ConstituencyID) / 
        NULLIF((SELECT COUNT(*) 
                FROM Votes v2 
                WHERE v2.ConstituencyID = r.ConstituencyID), 0) * 100, 
        2
    ),
    LastUpdated = CURRENT_TIMESTAMP;

-- Query 5.3: Insert or update results (UPSERT) for a specific candidate
INSERT INTO Results (CandidateID, ConstituencyID, TotalVotes, VotePercentage, LastUpdated)
SELECT 
    c.CandidateID,
    c.ConstituencyID,
    COUNT(v.VoteID) AS TotalVotes,
    ROUND((COUNT(v.VoteID)::DECIMAL / 
        NULLIF((SELECT COUNT(*) FROM Votes WHERE ConstituencyID = c.ConstituencyID), 0) * 100), 2) AS VotePercentage,
    CURRENT_TIMESTAMP
FROM 
    Candidates c
LEFT JOIN 
    Votes v ON c.CandidateID = v.CandidateID
WHERE 
    c.CandidateID = 1  -- Change to specific candidate
GROUP BY 
    c.CandidateID, c.ConstituencyID
ON CONFLICT (CandidateID, ConstituencyID) 
DO UPDATE SET
    TotalVotes = EXCLUDED.TotalVotes,
    VotePercentage = EXCLUDED.VotePercentage,
    LastUpdated = EXCLUDED.LastUpdated;

-- Query 5.4: View updated results after tally
SELECT 
    r.ResultID,
    c.CandidateName,
    p.PartyName,
    const.ConstituencyName,
    const.Province,
    r.TotalVotes,
    r.VotePercentage,
    r.LastUpdated
FROM 
    Results r
INNER JOIN 
    Candidates c ON r.CandidateID = c.CandidateID
INNER JOIN 
    Parties p ON c.PartyID = p.PartyID
INNER JOIN 
    Constituencies const ON r.ConstituencyID = const.ConstituencyID
ORDER BY 
    const.Province, const.ConstituencyName, r.TotalVotes DESC;

-- ============================================
-- TASK 6: Identify Winning Candidate per Region (Province/Constituency)
-- ============================================

-- Query 6.1: Winning candidate per constituency
SELECT 
    const.ConstituencyID,
    const.ConstituencyName,
    const.Province,
    c.CandidateID,
    c.CandidateName AS WinningCandidate,
    p.PartyName AS WinningParty,
    COUNT(v.VoteID) AS TotalVotes,
    ROUND((COUNT(v.VoteID)::DECIMAL / 
        (SELECT COUNT(*) FROM Votes WHERE ConstituencyID = const.ConstituencyID) * 100), 2) AS VotePercentage
FROM 
    Constituencies const
INNER JOIN 
    Candidates c ON const.ConstituencyID = c.ConstituencyID
INNER JOIN 
    Parties p ON c.PartyID = p.PartyID
LEFT JOIN 
    Votes v ON c.CandidateID = v.CandidateID
GROUP BY 
    const.ConstituencyID, const.ConstituencyName, const.Province,
    c.CandidateID, c.CandidateName, p.PartyName
HAVING 
    COUNT(v.VoteID) = (
        SELECT MAX(vote_count)
        FROM (
            SELECT COUNT(*) as vote_count
            FROM Votes v2
            INNER JOIN Candidates c2 ON v2.CandidateID = c2.CandidateID
            WHERE c2.ConstituencyID = const.ConstituencyID
            GROUP BY c2.CandidateID
        ) AS max_votes
    )
ORDER BY 
    const.Province, const.ConstituencyName;

-- Query 6.2: Winning candidate per province (region)
WITH ProvincialVotes AS (
    SELECT 
        const.Province,
        c.CandidateID,
        c.CandidateName,
        p.PartyName,
        COUNT(v.VoteID) AS TotalVotes
    FROM 
        Constituencies const
    INNER JOIN 
        Candidates c ON const.ConstituencyID = c.ConstituencyID
    INNER JOIN 
        Parties p ON c.PartyID = p.PartyID
    LEFT JOIN 
        Votes v ON c.CandidateID = v.CandidateID
    GROUP BY 
        const.Province, c.CandidateID, c.CandidateName, p.PartyName
),
RankedCandidates AS (
    SELECT 
        Province,
        CandidateID,
        CandidateName,
        PartyName,
        TotalVotes,
        RANK() OVER (PARTITION BY Province ORDER BY TotalVotes DESC) AS Rank
    FROM 
        ProvincialVotes
)
SELECT 
    Province AS Region,
    CandidateName AS WinningCandidate,
    PartyName AS WinningParty,
    TotalVotes,
    ROUND((TotalVotes::DECIMAL / 
        (SELECT SUM(TotalVotes) FROM ProvincialVotes pv WHERE pv.Province = RankedCandidates.Province) * 100), 2) AS VotePercentage
FROM 
    RankedCandidates
WHERE 
    Rank = 1
ORDER BY 
    Province;

-- Query 6.3: Winning party per province (alternative view)
SELECT 
    const.Province AS Region,
    p.PartyName AS WinningParty,
    COUNT(v.VoteID) AS TotalVotes,
    ROUND((COUNT(v.VoteID)::DECIMAL / 
        (SELECT COUNT(*) FROM Votes v2 
         INNER JOIN Candidates c2 ON v2.CandidateID = c2.CandidateID
         INNER JOIN Constituencies const2 ON c2.ConstituencyID = const2.ConstituencyID
         WHERE const2.Province = const.Province) * 100), 2) AS VotePercentage
FROM 
    Constituencies const
INNER JOIN 
    Candidates c ON const.ConstituencyID = c.ConstituencyID
INNER JOIN 
    Parties p ON c.PartyID = p.PartyID
LEFT JOIN 
    Votes v ON c.CandidateID = v.CandidateID
GROUP BY 
    const.Province, p.PartyID, p.PartyName
HAVING 
    COUNT(v.VoteID) = (
        SELECT MAX(party_votes)
        FROM (
            SELECT COUNT(*) as party_votes
            FROM Votes v2
            INNER JOIN Candidates c2 ON v2.CandidateID = c2.CandidateID
            INNER JOIN Constituencies const2 ON c2.ConstituencyID = const2.ConstituencyID
            WHERE const2.Province = const.Province
            GROUP BY c2.PartyID
        ) AS max_party_votes
    )
ORDER BY 
    const.Province;

-- Query 6.4: Using the existing view for leading candidates
SELECT 
    Province AS Region,
    ConstituencyName,
    LeadingCandidate AS WinningCandidate,
    LeadingParty AS WinningParty,
    TotalVotes
FROM 
    LeadingCandidatesByConstituency
ORDER BY 
    Province, ConstituencyName;

-- Query 6.5: National winner (overall winning candidate)
SELECT 
    c.CandidateID,
    c.CandidateName AS NationalWinner,
    p.PartyName AS WinningParty,
    COUNT(v.VoteID) AS TotalNationalVotes,
    ROUND((COUNT(v.VoteID)::DECIMAL / 
        (SELECT COUNT(*) FROM Votes) * 100), 2) AS NationalVotePercentage,
    COUNT(DISTINCT c2.ConstituencyID) AS ConstituenciesWon
FROM 
    Candidates c
INNER JOIN 
    Parties p ON c.PartyID = p.PartyID
LEFT JOIN 
    Votes v ON c.CandidateID = v.CandidateID
LEFT JOIN 
    Candidates c2 ON c.PartyID = c2.PartyID
GROUP BY 
    c.CandidateID, c.CandidateName, p.PartyName
ORDER BY 
    TotalNationalVotes DESC
LIMIT 1;

-- ============================================
-- SUMMARY REPORT: Complete Election Results
-- ============================================

-- Comprehensive election summary
SELECT 
    'Total Registered Voters' AS Metric,
    SUM(RegisteredVoters)::TEXT AS Value
FROM Constituencies
UNION ALL
SELECT 
    'Total Votes Cast',
    COUNT(DISTINCT VoterID)::TEXT
FROM Votes
UNION ALL
SELECT 
    'Overall Turnout %',
    ROUND((COUNT(DISTINCT VoterID)::DECIMAL / 
        (SELECT SUM(RegisteredVoters) FROM Constituencies) * 100), 2)::TEXT
FROM Votes
UNION ALL
SELECT 
    'Total Candidates',
    COUNT(*)::TEXT
FROM Candidates
UNION ALL
SELECT 
    'Total Parties',
    COUNT(*)::TEXT
FROM Parties
UNION ALL
SELECT 
    'Leading Party',
    (SELECT p.PartyName 
     FROM Parties p 
     INNER JOIN Candidates c ON p.PartyID = c.PartyID 
     INNER JOIN Votes v ON c.CandidateID = v.CandidateID 
     GROUP BY p.PartyID, p.PartyName 
     ORDER BY COUNT(v.VoteID) DESC 
     LIMIT 1)
UNION ALL
SELECT 
    'Constituencies Reporting',
    COUNT(DISTINCT ConstituencyID)::TEXT
FROM Votes;
