-- ============================================================================
-- Script 04: Create Views
-- ============================================================================
-- View 1: Total votes per party (summarized across all constituencies)
-- ============================================================================
CREATE OR REPLACE VIEW vw_party_vote_summary AS
SELECT 
    p.PartyID,
    p.PartyName,
    p.Leader,
    p.Symbol,
    COUNT(b.BallotID) AS TotalVotes,
    ROUND((COUNT(b.BallotID)::NUMERIC / NULLIF(SUM(COUNT(b.BallotID)) OVER (), 0)) * 100, 2) AS VotePercentage
FROM 
    Party p
    LEFT JOIN Candidate c ON p.PartyID = c.PartyID
    LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID AND b.Validity = 'Valid'
GROUP BY 
    p.PartyID, p.PartyName, p.Leader, p.Symbol
ORDER BY 
    TotalVotes DESC;

-- Test the view
SELECT * FROM vw_party_vote_summary;

-- ============================================================================
-- View 2: Detailed election results by constituency
-- ============================================================================
CREATE OR REPLACE VIEW vw_constituency_results AS
SELECT 
    co.ConstituencyID,
    co.Name AS Constituency,
    co.Region,
    c.CandidateID,
    c.FullName AS Candidate,
    p.PartyName AS Party,
    r.TotalVotes,
    r.DeclaredDate,
    RANK() OVER (PARTITION BY co.ConstituencyID ORDER BY r.TotalVotes DESC) AS PositionRank
FROM 
    Constituency co
    INNER JOIN Candidate c ON co.ConstituencyID = c.ConstituencyID
    INNER JOIN Party p ON c.PartyID = p.PartyID
    INNER JOIN Result r ON c.CandidateID = r.CandidateID
ORDER BY 
    co.Name, PositionRank;

-- Test the view
SELECT * FROM vw_constituency_results;

-- ============================================================================
-- View 3: Active voters summary
-- ============================================================================
CREATE OR REPLACE VIEW vw_active_voters AS
SELECT 
    co.Name AS Constituency,
    co.Region,
    COUNT(v.VoterID) AS TotalActiveVoters,
    COUNT(CASE WHEN v.Gender = 'M' THEN 1 END) AS MaleVoters,
    COUNT(CASE WHEN v.Gender = 'F' THEN 1 END) AS FemaleVoters
FROM 
    Constituency co
    LEFT JOIN Voter v ON co.ConstituencyID = v.ConstituencyID AND v.Status = 'Active'
GROUP BY 
    co.ConstituencyID, co.Name, co.Region
ORDER BY 
    co.Name;

-- Test the view
SELECT * FROM vw_active_voters;

-- ============================================================================
-- Views Creation Complete
-- ============================================================================
