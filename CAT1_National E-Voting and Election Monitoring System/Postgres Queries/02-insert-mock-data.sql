-- ============================================================================
-- Script 02: Insert Sample Data (Rwandan Context)
-- ============================================================================
-- ============================================================================
-- Insert Constituencies (2 constituencies as required)
-- ============================================================================
INSERT INTO Constituency (Name, Region, RegisteredVoters) VALUES
('Gasabo District', 'Kigali', 530000),
('Nyarugenge District', 'Kigali', 290000);

-- ============================================================================
-- Insert Political Parties (3 parties as required)
-- ============================================================================
INSERT INTO Party (PartyName, Leader, Symbol, Headquarters) VALUES
('Rwanda Patriotic Front', 'Paul Kagame', 'Umbrella', 'Kigali City'),
('Social Democratic Party', 'Vincent Biruta', 'Scales', 'Kigali City'),
('Liberal Party', 'Donatille Mukabalisa', 'Torch', 'Kigali City');

-- ============================================================================
-- Insert Voters (Sample voters from both constituencies)
-- ============================================================================
INSERT INTO Voter (FullName, NationalID, Gender, ConstituencyID, Status) VALUES
-- Gasabo District Voters
('Uwimana Jean Claude', '1198780123456789', 'M', 1, 'Active'),
('Mukamana Grace', '1199085012345678', 'F', 1, 'Active'),
('Niyonzima Patrick', '1198580234567890', 'M', 1, 'Active'),
('Uwase Marie', '1199290345678901', 'F', 1, 'Active'),
('Habimana Eric', '1198880456789012', 'M', 1, 'Active'),
('Ingabire Alice', '1199185567890123', 'F', 1, 'Active'),
('Mugisha David', '1198680678901234', 'M', 1, 'Active'),
('Nyirahabimana Sarah', '1199390789012345', 'F', 1, 'Active'),
('Bizimana Joseph', '1198780890123456', 'M', 1, 'Active'),
('Uwera Christine', '1199285901234567', 'F', 1, 'Active'),

-- Nyarugenge District Voters
('Nsengimana Emmanuel', '1198881012345678', 'M', 2, 'Active'),
('Mukamazimpaka Jeanne', '1199186123456789', 'F', 2, 'Active'),
('Hakizimana Claude', '1198581234567890', 'M', 2, 'Active'),
('Nyiramana Francine', '1199291345678901', 'F', 2, 'Active'),
('Nshimiyimana Robert', '1198881456789012', 'M', 2, 'Active'),
('Mukandayisenga Agnes', '1199186567890123', 'F', 2, 'Active'),
('Uwizeyimana Felix', '1198681678901234', 'M', 2, 'Active'),
('Nyiransabimana Beatrice', '1199391789012345', 'F', 2, 'Active'),
('Habiyambere Jean Paul', '1198781890123456', 'M', 2, 'Active'),
('Mukeshimana Diane', '1199286901234567', 'F', 2, 'Active');

-- ============================================================================
-- Insert Candidates (Multiple candidates per constituency from different parties)
-- ============================================================================
INSERT INTO Candidate (PartyID, ConstituencyID, FullName, Manifesto) VALUES
-- Gasabo District Candidates
(1, 1, 'Kagame Paul', 'Continued economic development, digital transformation, and national unity for Rwanda'),
(2, 1, 'Biruta Vincent', 'Social welfare programs, healthcare expansion, and education reform'),
(3, 1, 'Mukabalisa Donatille', 'Women empowerment, youth employment, and democratic governance'),

-- Nyarugenge District Candidates
(1, 2, 'Ndayisaba Jean Baptiste', 'Infrastructure development, job creation, and poverty reduction'),
(2, 2, 'Uwamahoro Claudine', 'Healthcare accessibility, environmental protection, and social justice'),
(3, 2, 'Nkurunziza Innocent', 'Economic liberalization, private sector growth, and innovation');

-- ============================================================================
-- Insert Ballots (Voting records)
-- ============================================================================
INSERT INTO Ballot (VoterID, CandidateID, VoteDate, Validity) VALUES
-- Gasabo District Votes
(1, 1, '2024-08-15 08:30:00', 'Valid'),
(2, 1, '2024-08-15 09:15:00', 'Valid'),
(3, 2, '2024-08-15 10:00:00', 'Valid'),
(4, 1, '2024-08-15 10:45:00', 'Valid'),
(5, 3, '2024-08-15 11:20:00', 'Valid'),
(6, 1, '2024-08-15 12:00:00', 'Valid'),
(7, 2, '2024-08-15 13:30:00', 'Valid'),
(8, 1, '2024-08-15 14:15:00', 'Valid'),
(9, 1, '2024-08-15 15:00:00', 'Valid'),
(10, 3, '2024-08-15 15:45:00', 'Valid'),

-- Nyarugenge District Votes
(11, 4, '2024-08-15 08:45:00', 'Valid'),
(12, 4, '2024-08-15 09:30:00', 'Valid'),
(13, 5, '2024-08-15 10:15:00', 'Valid'),
(14, 4, '2024-08-15 11:00:00', 'Valid'),
(15, 6, '2024-08-15 11:45:00', 'Valid'),
(16, 4, '2024-08-15 12:30:00', 'Valid'),
(17, 5, '2024-08-15 13:15:00', 'Valid'),
(18, 4, '2024-08-15 14:00:00', 'Valid'),
(19, 4, '2024-08-15 14:45:00', 'Valid'),
(20, 6, '2024-08-15 15:30:00', 'Valid');

-- ============================================================================
-- Insert Initial Results (Will be updated after tallying)
-- ============================================================================
INSERT INTO Result (CandidateID, TotalVotes, DeclaredDate) VALUES
(1, 0, NULL),
(2, 0, NULL),
(3, 0, NULL),
(4, 0, NULL),
(5, 0, NULL),
(6, 0, NULL);

-- ============================================================================
-- Sample Data Insertion Complete
-- ============================================================================
