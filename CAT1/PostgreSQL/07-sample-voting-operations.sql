-- Sample Voting Operations for Rwanda E-Voting System
-- This script demonstrates how to cast votes and test the triggers

-- ============================================
-- SAMPLE VOTING OPERATIONS
-- ============================================

-- Cast votes for Gasabo constituency (ConstituencyID: 1)
-- Candidates: 1 (Jean Baptiste Uwimana - RPF), 2 (Marie Claire Mukasine - SDP)

INSERT INTO Votes (VoterID, CandidateID, ConstituencyID) VALUES
(1, 1, 1),   -- Uwimana Jean votes for Jean Baptiste Uwimana
(2, 1, 1),   -- Mukasine Alice votes for Jean Baptiste Uwimana
(3, 1, 1),   -- Habimana Patrick votes for Jean Baptiste Uwimana
(4, 2, 1),   -- Uwase Grace votes for Marie Claire Mukasine
(5, 1, 1),   -- Nkusi Emmanuel votes for Jean Baptiste Uwimana
(6, 2, 1),   -- Mukamana Jeanne votes for Marie Claire Mukasine
(7, 1, 1),   -- Mutabazi Joseph votes for Jean Baptiste Uwimana
(8, 1, 1),   -- Nyirahabimana Sarah votes for Jean Baptiste Uwimana
(9, 2, 1),   -- Niyonzima David votes for Marie Claire Mukasine
(10, 1, 1);  -- Uwera Christine votes for Jean Baptiste Uwimana

-- Cast votes for Kicukiro constituency (ConstituencyID: 2)
-- Candidates: 3 (Patrick Nkusi - RPF), 4 (Grace Uwase - Liberal Party)

INSERT INTO Votes (VoterID, CandidateID, ConstituencyID) VALUES
(11, 3, 2),  -- Mugabo Pierre votes for Patrick Nkusi
(12, 3, 2),  -- Mukantwari Alice votes for Patrick Nkusi
(13, 3, 2),  -- Nsabimana Eric votes for Patrick Nkusi
(14, 4, 2),  -- Uwamahoro Francine votes for Grace Uwase
(15, 3, 2),  -- Hakizimana Claude votes for Patrick Nkusi
(16, 4, 2),  -- Mukandori Diane votes for Grace Uwase
(17, 3, 2),  -- Nshimiyimana Felix votes for Patrick Nkusi
(18, 3, 2),  -- Nyiransabimana Immaculee votes for Patrick Nkusi
(19, 3, 2),  -- Uwizeye Gilbert votes for Patrick Nkusi
(20, 4, 2);  -- Mukamugema Josephine votes for Grace Uwase

-- Cast votes for Nyarugenge constituency (ConstituencyID: 3)
-- Candidates: 5 (Emmanuel Habimana - RPF), 6 (Jeanne Mukamana - Green Party)

INSERT INTO Votes (VoterID, CandidateID, ConstituencyID) VALUES
(21, 5, 3),  -- Bizimana Innocent votes for Emmanuel Habimana
(22, 5, 3),  -- Mukandayisenga Vestine votes for Emmanuel Habimana
(23, 5, 3),  -- Habiyambere Laurent votes for Emmanuel Habimana
(24, 6, 3),  -- Uwimana Esperance votes for Jeanne Mukamana
(25, 5, 3),  -- Niyitegeka Martin votes for Emmanuel Habimana
(26, 6, 3),  -- Mukamazimpaka Angelique votes for Jeanne Mukamana
(27, 5, 3),  -- Ndayisaba Olivier votes for Emmanuel Habimana
(28, 5, 3),  -- Nyiramana Beatrice votes for Emmanuel Habimana
(29, 5, 3),  -- Mugisha Theophile votes for Emmanuel Habimana
(30, 6, 3);  -- Uwase Chantal votes for Jeanne Mukamana

-- ============================================
-- QUERY RESULTS AFTER VOTING
-- ============================================

-- View updated results
SELECT * FROM Results ORDER BY ConstituencyID, TotalVotes DESC;

-- View constituency turnout
SELECT * FROM ConstituencyTurnoutSummary ORDER BY ConstituencyName;

-- View leading candidates
SELECT * FROM LeadingCandidatesByConstituency;

-- View party performance
SELECT * FROM PartyPerformanceSummary ORDER BY TotalVotes DESC;

-- View voters who have voted
SELECT VoterID, VoterName, NationalID, HasVoted 
FROM Voters 
WHERE HasVoted = TRUE 
ORDER BY VoterID;

-- ============================================
-- TEST DUPLICATE VOTING PREVENTION
-- ============================================

-- This should fail with an error message
-- Uncomment to test:
-- INSERT INTO Votes (VoterID, CandidateID, ConstituencyID) 
-- VALUES (1, 2, 1);
-- Expected error: "Voter with ID 1 has already cast a vote. Duplicate voting is not allowed."

-- ============================================
-- TEST CONSTITUENCY VALIDATION
-- ============================================

-- This should fail because voter 1 is in constituency 1, not 2
-- Uncomment to test:
-- INSERT INTO Votes (VoterID, CandidateID, ConstituencyID) 
-- VALUES (1, 3, 2);
-- Expected error: Constituency mismatch error
