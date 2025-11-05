-- Insert Mock Data for Rwanda E-Voting System

-- Insert Parties (Major political parties in Rwanda)
INSERT INTO Parties (PartyName, PartyLeader, FoundedYear, Ideology) VALUES
('Rwandan Patriotic Front', 'Paul Kagame', 1987, 'Progressive'),
('Social Democratic Party', 'Vincent Biruta', 1991, 'Social Democracy'),
('Liberal Party', 'Donatille Mukabalisa', 1991, 'Liberalism'),
('Democratic Green Party', 'Frank Habineza', 2009, 'Environmentalism'),
('Party for Progress and Concord', 'Alivera Mukabaramba', 2003, 'Centrism'),
('Ideal Democratic Party', 'Sheikh Musa Fazil Harerimana', 2010, 'Democratic');

-- Insert Constituencies (Rwanda's 30 districts across 5 provinces)
INSERT INTO Constituencies (ConstituencyName, Province, RegisteredVoters) VALUES
-- Kigali City (3 districts)
('Gasabo', 'Kigali City', 450000),
('Kicukiro', 'Kigali City', 320000),
('Nyarugenge', 'Kigali City', 280000),

-- Eastern Province (7 districts)
('Bugesera', 'Eastern Province', 180000),
('Gatsibo', 'Eastern Province', 220000),
('Kayonza', 'Eastern Province', 195000),
('Kirehe', 'Eastern Province', 175000),
('Ngoma', 'Eastern Province', 165000),
('Nyagatare', 'Eastern Province', 240000),
('Rwamagana', 'Eastern Province', 185000),

-- Northern Province (5 districts)
('Burera', 'Northern Province', 155000),
('Gakenke', 'Northern Province', 190000),
('Gicumbi', 'Northern Province', 225000),
('Musanze', 'Northern Province', 210000),
('Rulindo', 'Northern Province', 145000),

-- Southern Province (8 districts)
('Gisagara', 'Southern Province', 165000),
('Huye', 'Southern Province', 195000),
('Kamonyi', 'Southern Province', 175000),
('Muhanga', 'Southern Province', 180000),
('Nyamagabe', 'Southern Province', 185000),
('Nyanza', 'Southern Province', 160000),
('Nyaruguru', 'Southern Province', 155000),
('Ruhango', 'Southern Province', 145000),

-- Western Province (7 districts)
('Karongi', 'Western Province', 190000),
('Ngororero', 'Western Province', 175000),
('Nyabihu', 'Western Province', 185000),
('Nyamasheke', 'Western Province', 195000),
('Rubavu', 'Western Province', 210000),
('Rusizi', 'Western Province', 200000),
('Rutsiro', 'Western Province', 165000);

-- Insert Candidates (2 candidates per constituency from different parties)
INSERT INTO Candidates (CandidateName, PartyID, ConstituencyID, Age, Gender, Education) VALUES
-- Kigali City
('Jean Baptiste Uwimana', 1, 1, 45, 'Male', 'Masters in Political Science'),
('Marie Claire Mukasine', 2, 1, 38, 'Female', 'MBA'),
('Patrick Nkusi', 1, 2, 42, 'Male', 'Law Degree'),
('Grace Uwase', 3, 2, 35, 'Female', 'Masters in Economics'),
('Emmanuel Habimana', 1, 3, 48, 'Male', 'PhD in Public Administration'),
('Jeanne Mukamana', 4, 3, 40, 'Female', 'Masters in Environmental Science'),

-- Eastern Province
('Joseph Mutabazi', 1, 4, 44, 'Male', 'Engineering Degree'),
('Alice Nyirahabimana', 2, 4, 36, 'Female', 'Business Administration'),
('David Niyonzima', 1, 5, 41, 'Male', 'Agricultural Science'),
('Sarah Uwera', 3, 5, 39, 'Female', 'Education Degree'),
('Pierre Mugabo', 1, 6, 46, 'Male', 'Economics Degree'),
('Christine Mukantwari', 5, 6, 37, 'Female', 'Social Work'),
('Eric Nsabimana', 1, 7, 43, 'Male', 'Law Degree'),
('Francine Uwamahoro', 2, 7, 34, 'Female', 'Public Health'),
('Claude Hakizimana', 1, 8, 47, 'Male', 'Business Management'),
('Diane Mukandori', 4, 8, 38, 'Female', 'Environmental Studies'),
('Felix Nshimiyimana', 1, 9, 45, 'Male', 'Agricultural Economics'),
('Immaculee Nyiransabimana', 3, 9, 36, 'Female', 'Development Studies'),
('Gilbert Uwizeye', 1, 10, 42, 'Male', 'Civil Engineering'),
('Josephine Mukamugema', 2, 10, 35, 'Female', 'Education'),

-- Northern Province
('Innocent Bizimana', 1, 11, 44, 'Male', 'Political Science'),
('Vestine Mukandayisenga', 5, 11, 37, 'Female', 'Sociology'),
('Laurent Habiyambere', 1, 12, 46, 'Male', 'Economics'),
('Esperance Uwimana', 3, 12, 39, 'Female', 'Business Administration'),
('Martin Niyitegeka', 1, 13, 43, 'Male', 'Public Administration'),
('Angelique Mukamazimpaka', 2, 13, 36, 'Female', 'Law'),
('Olivier Ndayisaba', 1, 14, 45, 'Male', 'Tourism Management'),
('Beatrice Nyiramana', 4, 14, 38, 'Female', 'Environmental Science'),
('Theophile Mugisha', 1, 15, 41, 'Male', 'Agricultural Science'),
('Chantal Uwase', 3, 15, 35, 'Female', 'Education'),

-- Southern Province
('Augustin Nkurunziza', 1, 16, 47, 'Male', 'Economics'),
('Drocella Mukamana', 2, 16, 39, 'Female', 'Social Work'),
('Bernard Habimana', 1, 17, 44, 'Male', 'Education'),
('Faustin Uwera', 5, 17, 37, 'Female', 'Public Health'),
('Charles Niyonsenga', 1, 18, 42, 'Male', 'Business Management'),
('Goretti Mukandutiye', 3, 18, 36, 'Female', 'Law'),
('Damascene Ntawukuriryayo', 1, 19, 46, 'Male', 'Political Science'),
('Henriette Nyirahabimana', 2, 19, 38, 'Female', 'Economics'),
('Evariste Kalisa', 1, 20, 43, 'Male', 'Agricultural Economics'),
('Ines Mukamuganga', 4, 20, 35, 'Female', 'Environmental Studies'),
('Fulgence Nsengiyumva', 1, 21, 45, 'Male', 'Public Administration'),
('Jacqueline Uwamahoro', 3, 21, 37, 'Female', 'Business Administration'),
('Gaspard Habiyaremye', 1, 22, 44, 'Male', 'Civil Engineering'),
('Keza Mukandayisenga', 2, 22, 36, 'Female', 'Education'),
('Hilaire Nshimiyimana', 1, 23, 42, 'Male', 'Law'),
('Leonie Nyiransabimana', 5, 23, 34, 'Female', 'Sociology'),

-- Western Province
('Innocent Uwimana', 1, 24, 46, 'Male', 'Economics'),
('Marthe Mukamana', 3, 24, 38, 'Female', 'Public Health'),
('Narcisse Habimana', 1, 25, 43, 'Male', 'Agricultural Science'),
('Odette Uwera', 2, 25, 36, 'Female', 'Business Administration'),
('Pascal Niyonzima', 1, 26, 45, 'Male', 'Tourism Management'),
('Quiterie Mukandori', 4, 26, 37, 'Female', 'Environmental Science'),
('Raphael Mugabo', 1, 27, 44, 'Male', 'Political Science'),
('Solange Mukantwari', 3, 27, 35, 'Female', 'Education'),
('Thaddee Nsabimana', 1, 28, 47, 'Male', 'Public Administration'),
('Umulisa Uwamahoro', 2, 28, 39, 'Female', 'Law'),
('Venuste Hakizimana', 1, 29, 42, 'Male', 'Business Management'),
('Winnie Mukandori', 5, 29, 36, 'Female', 'Social Work'),
('Xavier Nshimiyimana', 1, 30, 45, 'Male', 'Economics'),
('Yolande Nyiransabimana', 3, 30, 38, 'Female', 'Development Studies');

-- Insert Sample Voters (10 voters per constituency for demonstration)
INSERT INTO Voters (VoterName, NationalID, ConstituencyID, Age, Gender, HasVoted) VALUES
-- Gasabo District (ConstituencyID: 1)
('Uwimana Jean', '1198780012345678', 1, 26, 'Male', FALSE),
('Mukasine Alice', '1199080023456789', 1, 24, 'Female', FALSE),
('Habimana Patrick', '1198580034567890', 1, 29, 'Male', FALSE),
('Uwase Grace', '1199280045678901', 1, 22, 'Female', FALSE),
('Nkusi Emmanuel', '1197580056789012', 1, 39, 'Male', FALSE),
('Mukamana Jeanne', '1198280067890123', 1, 32, 'Female', FALSE),
('Mutabazi Joseph', '1198080078901234', 1, 34, 'Male', FALSE),
('Nyirahabimana Sarah', '1199180089012345', 1, 23, 'Female', FALSE),
('Niyonzima David', '1197880090123456', 1, 36, 'Male', FALSE),
('Uwera Christine', '1198680001234567', 1, 28, 'Female', FALSE),

-- Kicukiro District (ConstituencyID: 2)
('Mugabo Pierre', '1198780112345678', 2, 27, 'Male', FALSE),
('Mukantwari Alice', '1199080123456789', 2, 24, 'Female', FALSE),
('Nsabimana Eric', '1198580134567890', 2, 29, 'Male', FALSE),
('Uwamahoro Francine', '1199280145678901', 2, 22, 'Female', FALSE),
('Hakizimana Claude', '1197580156789012', 2, 39, 'Male', FALSE),
('Mukandori Diane', '1198280167890123', 2, 32, 'Female', FALSE),
('Nshimiyimana Felix', '1198080178901234', 2, 34, 'Male', FALSE),
('Nyiransabimana Immaculee', '1199180189012345', 2, 23, 'Female', FALSE),
('Uwizeye Gilbert', '1197880190123456', 2, 36, 'Male', FALSE),
('Mukamugema Josephine', '1198680101234567', 2, 28, 'Female', FALSE),

-- Nyarugenge District (ConstituencyID: 3)
('Bizimana Innocent', '1198780212345678', 3, 26, 'Male', FALSE),
('Mukandayisenga Vestine', '1199080223456789', 3, 24, 'Female', FALSE),
('Habiyambere Laurent', '1198580234567890', 3, 29, 'Male', FALSE),
('Uwimana Esperance', '1199280245678901', 3, 22, 'Female', FALSE),
('Niyitegeka Martin', '1197580256789012', 3, 39, 'Male', FALSE),
('Mukamazimpaka Angelique', '1198280267890123', 3, 32, 'Female', FALSE),
('Ndayisaba Olivier', '1198080278901234', 3, 34, 'Male', FALSE),
('Nyiramana Beatrice', '1199180289012345', 3, 23, 'Female', FALSE),
('Mugisha Theophile', '1197880290123456', 3, 36, 'Male', FALSE),
('Uwase Chantal', '1198680201234567', 3, 28, 'Female', FALSE);

-- Note: In a real system, you would insert voters for all 30 constituencies
-- This is a sample showing the pattern for the first 3 constituencies
