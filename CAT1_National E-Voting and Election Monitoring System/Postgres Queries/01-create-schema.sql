-- =====================================================
-- TASK 1: Build Schema with PK, FK, and Domain Constraints
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: Create database first
-- CREATE DATABASE evotingdb;

-- Connect to evotingdb before running this script

-- Table: Party
CREATE TABLE Party (
    PartyID SERIAL PRIMARY KEY,
    PartyName VARCHAR(100) NOT NULL UNIQUE,
    Leader VARCHAR(100) NOT NULL,
    Symbol VARCHAR(50) NOT NULL,
    Headquarters VARCHAR(100) NOT NULL,
    CONSTRAINT chk_party_name CHECK (LENGTH(PartyName) >= 3)
);

-- Table: Constituency
CREATE TABLE Constituency (
    ConstituencyID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Region VARCHAR(50) NOT NULL,
    RegisteredVoters INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT chk_registered_voters CHECK (RegisteredVoters >= 0)
);

-- Table: Voter
CREATE TABLE Voter (
    VoterID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    NationalID VARCHAR(20) NOT NULL UNIQUE,
    Gender VARCHAR(10) NOT NULL,
    ConstituencyID INTEGER NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active',
    CONSTRAINT chk_gender CHECK (Gender IN ('Male', 'Female', 'Other')),
    CONSTRAINT chk_status CHECK (Status IN ('Active', 'Inactive', 'Suspended')),
    CONSTRAINT fk_voter_constituency FOREIGN KEY (ConstituencyID) 
        REFERENCES Constituency(ConstituencyID) ON DELETE RESTRICT
);

-- Table: Candidate
CREATE TABLE Candidate (
    CandidateID SERIAL PRIMARY KEY,
    PartyID INTEGER NOT NULL,
    ConstituencyID INTEGER NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Manifesto TEXT,
    CONSTRAINT fk_candidate_party FOREIGN KEY (PartyID) 
        REFERENCES Party(PartyID) ON DELETE RESTRICT,
    CONSTRAINT fk_candidate_constituency FOREIGN KEY (ConstituencyID) 
        REFERENCES Constituency(ConstituencyID) ON DELETE RESTRICT
);

-- Table: Ballot
CREATE TABLE Ballot (
    BallotID SERIAL PRIMARY KEY,
    VoterID INTEGER NOT NULL,
    CandidateID INTEGER NOT NULL,
    VoteDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Validity VARCHAR(20) NOT NULL DEFAULT 'Valid',
    CONSTRAINT chk_ballot_validity CHECK (Validity IN ('Valid', 'Invalid', 'Pending')),
    CONSTRAINT fk_ballot_voter FOREIGN KEY (VoterID) 
        REFERENCES Voter(VoterID) ON DELETE RESTRICT,
    CONSTRAINT fk_ballot_candidate FOREIGN KEY (CandidateID) 
        REFERENCES Candidate(CandidateID) ON DELETE RESTRICT
);

-- Table: Result
CREATE TABLE Result (
    ResultID SERIAL PRIMARY KEY,
    CandidateID INTEGER NOT NULL UNIQUE,
    TotalVotes INTEGER NOT NULL DEFAULT 0,
    DeclaredDate DATE NOT NULL,
    CONSTRAINT chk_total_votes CHECK (TotalVotes >= 0),
    CONSTRAINT fk_result_candidate FOREIGN KEY (CandidateID) 
        REFERENCES Candidate(CandidateID) ON DELETE CASCADE
);
