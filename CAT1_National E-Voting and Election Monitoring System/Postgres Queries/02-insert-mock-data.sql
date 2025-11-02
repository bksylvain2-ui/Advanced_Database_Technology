-- =====================================================
-- TASK 3: Insert Mock Data (Rwandan Context)
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: Run task1_create_schema.sql first

-- Insert 3 Political Parties (Rwandan examples)
INSERT INTO Party (PartyName, Leader, Symbol, Headquarters) VALUES
    ('Rwandan Patriotic Front', 'Paul Kagame', 'RPF', 'Kigali'),
    ('Social Democratic Party', 'Jean Damascene Ntawukuliryayo', 'PSD', 'Kigali'),
    ('Liberal Party', 'Donatille Mukabalisa', 'PL', 'Kigali');

-- Insert 2 Constituencies (Rwandan regions)
INSERT INTO Constituency (Name, Region, RegisteredVoters) VALUES
    ('Gasabo District', 'Kigali', 15000),
    ('Nyarugenge District', 'Kigali', 12000);

-- Insert Candidates
INSERT INTO Candidate (PartyID, ConstituencyID, FullName, Manifesto) VALUES
    (1, 1, 'John Bizimana', 'Economic development and infrastructure'),
    (1, 2, 'Marie Uwimana', 'Education and healthcare reform'),
    (2, 1, 'Joseph Mukamana', 'Social welfare and equality'),
    (2, 2, 'Agnes Nyirarukundo', 'Youth empowerment programs'),
    (3, 1, 'Pierre Nkurunziza', 'Democratic reforms and transparency'),
    (3, 2, 'Clementine Mukeshimana', 'Environmental protection');

-- Insert Voters
INSERT INTO Voter (FullName, NationalID, Gender, ConstituencyID, Status) VALUES
    ('Alice Uwizeye', '1198801234567', 'Female', 1, 'Active'),
    ('David Nkurunziza', '1198802345678', 'Male', 1, 'Active'),
    ('Grace Mukamana', '1198803456789', 'Female', 1, 'Active'),
    ('Emmanuel Habimana', '1198804567890', 'Male', 2, 'Active'),
    ('Felicia Nyiramana', '1198805678901', 'Female', 2, 'Active'),
    ('Robert Nshuti', '1198806789012', 'Male', 2, 'Active');

-- Insert Ballots (Votes)
INSERT INTO Ballot (VoterID, CandidateID, VoteDate, Validity) VALUES
    (1, 1, '2024-03-15 08:00:00', 'Valid'),
    (2, 3, '2024-03-15 09:15:00', 'Valid'),
    (3, 1, '2024-03-15 10:30:00', 'Valid'),
    (4, 2, '2024-03-15 11:00:00', 'Valid'),
    (5, 4, '2024-03-15 12:00:00', 'Valid'),
    (6, 2, '2024-03-15 13:30:00', 'Valid');

