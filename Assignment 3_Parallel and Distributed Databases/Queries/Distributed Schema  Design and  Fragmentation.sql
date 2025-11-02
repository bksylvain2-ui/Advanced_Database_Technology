-- =====================================================
-- TASK 1: Distributed Schema Design & Fragmentation
-- Assignment 3: Distributed and Parallel Database
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: 
-- 1. Run task1_create_schema.sql
-- 2. Run task3_insert_mock_data.sql

-- Simulate horizontal fragmentation by creating two node schemas
-- Node A: Handles Kigali region (Gasabo District)
-- Node B: Handles other regions (Nyarugenge District)

-- =====================================================
-- NODE A SCHEMA (Kigali - Gasabo District)
-- =====================================================

CREATE SCHEMA IF NOT EXISTS evotingdb_nodeA;

-- Create tables in Node A schema
CREATE TABLE evotingdb_nodeA.Party (
    PartyID SERIAL PRIMARY KEY,
    PartyName VARCHAR(100) NOT NULL UNIQUE,
    Leader VARCHAR(100) NOT NULL,
    Symbol VARCHAR(50) NOT NULL,
    Headquarters VARCHAR(100) NOT NULL
);

CREATE TABLE evotingdb_nodeA.Constituency (
    ConstituencyID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Region VARCHAR(50) NOT NULL,
    RegisteredVoters INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE evotingdb_nodeA.Voter (
    VoterID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    NationalID VARCHAR(20) NOT NULL UNIQUE,
    Gender VARCHAR(10) NOT NULL,
    ConstituencyID INTEGER NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active'
);

CREATE TABLE evotingdb_nodeA.Candidate (
    CandidateID SERIAL PRIMARY KEY,
    PartyID INTEGER NOT NULL,
    ConstituencyID INTEGER NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Manifesto TEXT
);

CREATE TABLE evotingdb_nodeA.Ballot (
    BallotID SERIAL PRIMARY KEY,
    VoterID INTEGER NOT NULL,
    CandidateID INTEGER NOT NULL,
    VoteDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Validity VARCHAR(20) NOT NULL DEFAULT 'Valid'
);

-- Insert sample data for Node A (Gasabo District - ConstituencyID = 1)
INSERT INTO evotingdb_nodeA.Constituency (Name, Region, RegisteredVoters) 
VALUES ('Gasabo District', 'Kigali', 15000);

INSERT INTO evotingdb_nodeA.Party (PartyName, Leader, Symbol, Headquarters) VALUES
    ('Rwandan Patriotic Front', 'Paul Kagame', 'RPF', 'Kigali'),
    ('Social Democratic Party', 'Jean Damascene Ntawukuliryayo', 'PSD', 'Kigali'),
    ('Liberal Party', 'Donatille Mukabalisa', 'PL', 'Kigali');

INSERT INTO evotingdb_nodeA.Candidate (PartyID, ConstituencyID, FullName, Manifesto) VALUES
    (1, 1, 'John Bizimana', 'Economic development and infrastructure'),
    (2, 1, 'Joseph Mukamana', 'Social welfare and equality'),
    (3, 1, 'Pierre Nkurunziza', 'Democratic reforms and transparency');

INSERT INTO evotingdb_nodeA.Voter (FullName, NationalID, Gender, ConstituencyID, Status) VALUES
    ('Alice Uwizeye', '1198801234567', 'Female', 1, 'Active'),
    ('David Nkurunziza', '1198802345678', 'Male', 1, 'Active'),
    ('Grace Mukamana', '1198803456789', 'Female', 1, 'Active');

-- =====================================================
-- NODE B SCHEMA (Kigali - Nyarugenge District)
-- =====================================================

CREATE SCHEMA IF NOT EXISTS evotingdb_nodeB;

-- Create tables in Node B schema
CREATE TABLE evotingdb_nodeB.Party (
    PartyID SERIAL PRIMARY KEY,
    PartyName VARCHAR(100) NOT NULL UNIQUE,
    Leader VARCHAR(100) NOT NULL,
    Symbol VARCHAR(50) NOT NULL,
    Headquarters VARCHAR(100) NOT NULL
);

CREATE TABLE evotingdb_nodeB.Constituency (
    ConstituencyID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Region VARCHAR(50) NOT NULL,
    RegisteredVoters INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE evotingdb_nodeB.Voter (
    VoterID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    NationalID VARCHAR(20) NOT NULL UNIQUE,
    Gender VARCHAR(10) NOT NULL,
    ConstituencyID INTEGER NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active'
);

CREATE TABLE evotingdb_nodeB.Candidate (
    CandidateID SERIAL PRIMARY KEY,
    PartyID INTEGER NOT NULL,
    ConstituencyID INTEGER NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Manifesto TEXT
);

CREATE TABLE evotingdb_nodeB.Ballot (
    BallotID SERIAL PRIMARY KEY,
    VoterID INTEGER NOT NULL,
    CandidateID INTEGER NOT NULL,
    VoteDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Validity VARCHAR(20) NOT NULL DEFAULT 'Valid'
);

-- Insert sample data for Node B (Nyarugenge District - ConstituencyID = 2)
INSERT INTO evotingdb_nodeB.Constituency (Name, Region, RegisteredVoters) 
VALUES ('Nyarugenge District', 'Kigali', 12000);

INSERT INTO evotingdb_nodeB.Party (PartyName, Leader, Symbol, Headquarters) VALUES
    ('Rwandan Patriotic Front', 'Paul Kagame', 'RPF', 'Kigali'),
    ('Social Democratic Party', 'Jean Damascene Ntawukuliryayo', 'PSD', 'Kigali'),
    ('Liberal Party', 'Donatille Mukabalisa', 'PL', 'Kigali');

INSERT INTO evotingdb_nodeB.Candidate (PartyID, ConstituencyID, FullName, Manifesto) VALUES
    (1, 2, 'Marie Uwimana', 'Education and healthcare reform'),
    (2, 2, 'Agnes Nyirarukundo', 'Youth empowerment programs'),
    (3, 2, 'Clementine Mukeshimana', 'Environmental protection');

INSERT INTO evotingdb_nodeB.Voter (FullName, NationalID, Gender, ConstituencyID, Status) VALUES
    ('Emmanuel Habimana', '1198804567890', 'Male', 2, 'Active'),
    ('Felicia Nyiramana', '1198805678901', 'Female', 2, 'Active'),
    ('Robert Nshuti', '1198806789012', 'Male', 2, 'Active');

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check data in Node A
SELECT 'Node A - Gasabo District' AS Node, COUNT(*) AS VoterCount 
FROM evotingdb_nodeA.Voter;

SELECT 'Node A - Gasabo District' AS Node, COUNT(*) AS CandidateCount 
FROM evotingdb_nodeA.Candidate;

-- Check data in Node B
SELECT 'Node B - Nyarugenge District' AS Node, COUNT(*) AS VoterCount 
FROM evotingdb_nodeB.Voter;

SELECT 'Node B - Nyarugenge District' AS Node, COUNT(*) AS CandidateCount 
FROM evotingdb_nodeB.Candidate;

-- Explanation:
-- Horizontal fragmentation splits tables by rows based on a condition.
-- Node A contains Gasabo District data, Node B contains Nyarugenge District data.
-- This improves performance by distributing data across logical nodes.
