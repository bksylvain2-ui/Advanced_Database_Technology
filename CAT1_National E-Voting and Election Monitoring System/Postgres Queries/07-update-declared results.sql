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
