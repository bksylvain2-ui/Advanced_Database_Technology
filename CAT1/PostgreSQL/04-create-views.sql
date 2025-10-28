-- Database Views for Rwanda E-Voting System
-- These views provide analytical insights and simplified data access

-- 1. View: Constituency Turnout Summary
-- Shows voter turnout statistics for each constituency
CREATE OR REPLACE VIEW ConstituencyTurnoutSummary AS
SELECT 
    c.ConstituencyID,
    c.ConstituencyName,
    c.Province,
    c.RegisteredVoters,
    COUNT(DISTINCT v.VoterID) AS VotersCastBallot,
    ROUND((COUNT(DISTINCT v.VoterID)::DECIMAL / c.RegisteredVoters * 100), 2) AS TurnoutPercentage,
    c.RegisteredVoters - COUNT(DISTINCT v.VoterID) AS VotersNotVoted
FROM 
    Constituencies c
LEFT JOIN 
    Votes v ON c.ConstituencyID = v.ConstituencyID
GROUP BY 
    c.ConstituencyID, c.ConstituencyName, c.Province, c.RegisteredVoters
ORDER BY 
    TurnoutPercentage DESC;

-- 2. View: Candidate Performance by Constituency
-- Shows detailed performance of each candidate in their constituency
CREATE OR REPLACE VIEW CandidatePerformanceByConstituency AS
SELECT 
    cand.CandidateID,
    cand.CandidateName,
    p.PartyName,
    const.ConstituencyName,
    const.Province,
    COUNT(v.VoteID) AS TotalVotes,
    ROUND((COUNT(v.VoteID)::DECIMAL / 
        (SELECT COUNT(*) FROM Votes WHERE ConstituencyID = const.ConstituencyID) * 100), 2) AS VotePercentage,
    RANK() OVER (PARTITION BY const.ConstituencyID ORDER BY COUNT(v.VoteID) DESC) AS RankInConstituency
FROM 
    Candidates cand
INNER JOIN 
    Parties p ON cand.PartyID = p.PartyID
INNER JOIN 
    Constituencies const ON cand.ConstituencyID = const.ConstituencyID
LEFT JOIN 
    Votes v ON cand.CandidateID = v.CandidateID
GROUP BY 
    cand.CandidateID, cand.CandidateName, p.PartyName, 
    const.ConstituencyID, const.ConstituencyName, const.Province
ORDER BY 
    const.ConstituencyName, TotalVotes DESC;

-- 3. View: Party Performance Summary
-- Aggregates votes and performance metrics for each political party
CREATE OR REPLACE VIEW PartyPerformanceSummary AS
SELECT 
    p.PartyID,
    p.PartyName,
    p.PartyLeader,
    p.Ideology,
    COUNT(DISTINCT cand.CandidateID) AS TotalCandidates,
    COUNT(v.VoteID) AS TotalVotes,
    ROUND((COUNT(v.VoteID)::DECIMAL / 
        (SELECT COUNT(*) FROM Votes) * 100), 2) AS NationalVotePercentage,
    COUNT(DISTINCT CASE 
        WHEN (SELECT COUNT(*) FROM Votes v2 
              WHERE v2.CandidateID = cand.CandidateID) = 
             (SELECT MAX(vote_count) FROM 
                (SELECT COUNT(*) as vote_count FROM Votes 
                 WHERE ConstituencyID = cand.ConstituencyID 
                 GROUP BY CandidateID) AS max_votes)
        THEN cand.ConstituencyID 
    END) AS ConstituenciesWon
FROM 
    Parties p
LEFT JOIN 
    Candidates cand ON p.PartyID = cand.PartyID
LEFT JOIN 
    Votes v ON cand.CandidateID = v.CandidateID
GROUP BY 
    p.PartyID, p.PartyName, p.PartyLeader, p.Ideology
ORDER BY 
    TotalVotes DESC;

-- 4. View: Provincial Election Results
-- Summarizes election results at the provincial level
CREATE OR REPLACE VIEW ProvincialElectionResults AS
SELECT 
    const.Province,
    SUM(const.RegisteredVoters) AS TotalRegisteredVoters,
    COUNT(DISTINCT v.VoterID) AS TotalVotesCast,
    ROUND((COUNT(DISTINCT v.VoterID)::DECIMAL / 
        SUM(const.RegisteredVoters) * 100), 2) AS ProvincialTurnout,
    COUNT(DISTINCT const.ConstituencyID) AS NumberOfConstituencies,
    COUNT(DISTINCT cand.CandidateID) AS NumberOfCandidates
FROM 
    Constituencies const
LEFT JOIN 
    Votes v ON const.ConstituencyID = v.ConstituencyID
LEFT JOIN 
    Candidates cand ON const.ConstituencyID = cand.ConstituencyID
GROUP BY 
    const.Province
ORDER BY 
    TotalVotesCast DESC;

-- 5. View: Voter Demographics Summary
-- Provides demographic breakdown of voters who cast ballots
CREATE OR REPLACE VIEW VoterDemographicsSummary AS
SELECT 
    const.Province,
    const.ConstituencyName,
    COUNT(CASE WHEN voters.Gender = 'Male' AND voters.HasVoted = TRUE THEN 1 END) AS MaleVoters,
    COUNT(CASE WHEN voters.Gender = 'Female' AND voters.HasVoted = TRUE THEN 1 END) AS FemaleVoters,
    COUNT(CASE WHEN voters.Age BETWEEN 18 AND 25 AND voters.HasVoted = TRUE THEN 1 END) AS Age18_25,
    COUNT(CASE WHEN voters.Age BETWEEN 26 AND 35 AND voters.HasVoted = TRUE THEN 1 END) AS Age26_35,
    COUNT(CASE WHEN voters.Age BETWEEN 36 AND 50 AND voters.HasVoted = TRUE THEN 1 END) AS Age36_50,
    COUNT(CASE WHEN voters.Age > 50 AND voters.HasVoted = TRUE THEN 1 END) AS Age51Plus,
    COUNT(CASE WHEN voters.HasVoted = TRUE THEN 1 END) AS TotalVoted
FROM 
    Voters voters
INNER JOIN 
    Constituencies const ON voters.ConstituencyID = const.ConstituencyID
GROUP BY 
    const.Province, const.ConstituencyName
ORDER BY 
    const.Province, const.ConstituencyName;

-- 6. View: Leading Candidates by Constituency
-- Shows the leading candidate in each constituency
CREATE OR REPLACE VIEW LeadingCandidatesByConstituency AS
WITH RankedCandidates AS (
    SELECT 
        cand.CandidateID,
        cand.CandidateName,
        p.PartyName,
        const.ConstituencyID,
        const.ConstituencyName,
        const.Province,
        COUNT(v.VoteID) AS TotalVotes,
        RANK() OVER (PARTITION BY const.ConstituencyID ORDER BY COUNT(v.VoteID) DESC) AS Rank
    FROM 
        Candidates cand
    INNER JOIN 
        Parties p ON cand.PartyID = p.PartyID
    INNER JOIN 
        Constituencies const ON cand.ConstituencyID = const.ConstituencyID
    LEFT JOIN 
        Votes v ON cand.CandidateID = v.CandidateID
    GROUP BY 
        cand.CandidateID, cand.CandidateName, p.PartyName, 
        const.ConstituencyID, const.ConstituencyName, const.Province
)
SELECT 
    ConstituencyID,
    ConstituencyName,
    Province,
    CandidateName AS LeadingCandidate,
    PartyName AS LeadingParty,
    TotalVotes
FROM 
    RankedCandidates
WHERE 
    Rank = 1
ORDER BY 
    Province, ConstituencyName;

-- 7. View: Election Overview Dashboard
-- Comprehensive view for the main dashboard showing key metrics
CREATE OR REPLACE VIEW ElectionOverviewDashboard AS
SELECT 
    (SELECT SUM(RegisteredVoters) FROM Constituencies) AS TotalRegisteredVoters,
    (SELECT COUNT(DISTINCT VoterID) FROM Votes) AS TotalVotesCast,
    (SELECT COUNT(*) FROM Candidates) AS TotalCandidates,
    (SELECT COUNT(*) FROM Parties) AS TotalParties,
    (SELECT COUNT(*) FROM Constituencies) AS TotalConstituencies,
    (SELECT COUNT(DISTINCT Province) FROM Constituencies) AS TotalProvinces,
    ROUND((SELECT COUNT(DISTINCT VoterID)::DECIMAL FROM Votes) / 
        (SELECT SUM(RegisteredVoters)::DECIMAL FROM Constituencies) * 100, 2) AS OverallTurnoutPercentage,
    (SELECT PartyName FROM Parties p 
     INNER JOIN Candidates c ON p.PartyID = c.PartyID 
     INNER JOIN Votes v ON c.CandidateID = v.CandidateID 
     GROUP BY p.PartyID, p.PartyName 
     ORDER BY COUNT(v.VoteID) DESC LIMIT 1) AS LeadingParty,
    (SELECT COUNT(v.VoteID) FROM Parties p 
     INNER JOIN Candidates c ON p.PartyID = c.PartyID 
     INNER JOIN Votes v ON c.CandidateID = v.CandidateID 
     GROUP BY p.PartyID 
     ORDER BY COUNT(v.VoteID) DESC LIMIT 1) AS LeadingPartyVotes;

-- 8. View: Candidate Gender Distribution
-- Shows gender representation among candidates and their performance
CREATE OR REPLACE VIEW CandidateGenderDistribution AS
SELECT 
    p.PartyName,
    COUNT(CASE WHEN c.Gender = 'Male' THEN 1 END) AS MaleCandidates,
    COUNT(CASE WHEN c.Gender = 'Female' THEN 1 END) AS FemaleCandidates,
    COUNT(CASE WHEN c.Gender = 'Other' THEN 1 END) AS OtherGenderCandidates,
    COUNT(*) AS TotalCandidates,
    ROUND(COUNT(CASE WHEN c.Gender = 'Female' THEN 1 END)::DECIMAL / 
        COUNT(*)::DECIMAL * 100, 2) AS FemaleRepresentationPercentage
FROM 
    Candidates c
INNER JOIN 
    Parties p ON c.PartyID = p.PartyID
GROUP BY 
    p.PartyName
ORDER BY 
    FemaleRepresentationPercentage DESC;

-- Query examples to test the views:
-- SELECT * FROM ConstituencyTurnoutSummary;
-- SELECT * FROM CandidatePerformanceByConstituency WHERE ConstituencyName = 'Gasabo';
-- SELECT * FROM PartyPerformanceSummary;
-- SELECT * FROM ProvincialElectionResults;
-- SELECT * FROM VoterDemographicsSummary WHERE Province = 'Kigali City';
-- SELECT * FROM LeadingCandidatesByConstituency;
-- SELECT * FROM ElectionOverviewDashboard;
-- SELECT * FROM CandidateGenderDistribution;
