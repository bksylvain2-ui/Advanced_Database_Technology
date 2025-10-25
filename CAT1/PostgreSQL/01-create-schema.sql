-- ============================================================================
-- National E-Voting and Election Monitoring System - Rwanda Case Study
-- Database: evoting
-- Script 01: Schema Creation
-- ============================================================================
-- Create database (run this separately if needed)
-- CREATE DATABASE evoting;
-- Connect to the database
-- ============================================================================
-- Table: Constituency
-- Stores information about electoral constituencies/districts in Rwanda
-- ============================================================================
CREATE TABLE Constituency (
    ConstituencyID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL UNIQUE,
    Region VARCHAR(50) NOT NULL CHECK (Region IN ('Kigali', 'Northern', 'Southern', 'Eastern', 'Western')),
    RegisteredVoters INTEGER NOT NULL CHECK (RegisteredVoters >= 0),
    CONSTRAINT chk_constituency_name CHECK (LENGTH(TRIM(Name)) > 0)
);
-- ============================================================================
-- Table: Party
-- Stores political party information
-- ============================================================================
CREATE TABLE Party (
    PartyID SERIAL PRIMARY KEY,
    PartyName VARCHAR(100) NOT NULL UNIQUE,
    Leader VARCHAR(100) NOT NULL,
    Symbol VARCHAR(50),
    Headquarters VARCHAR(150),
    CONSTRAINT chk_party_name CHECK (LENGTH(TRIM(PartyName)) > 0),
    CONSTRAINT chk_leader_name CHECK (LENGTH(TRIM(Leader)) > 0)
);
-- ============================================================================
-- Table: Voter
-- Stores registered voter information
-- ============================================================================
CREATE TABLE Voter (
    VoterID SERIAL PRIMARY KEY,
    FullName VARCHAR(150) NOT NULL,
    NationalID VARCHAR(16) NOT NULL UNIQUE,
    Gender CHAR(1) NOT NULL CHECK (Gender IN ('M', 'F')),
    ConstituencyID INTEGER NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active' CHECK (Status IN ('Active', 'Inactive', 'Suspended')),
    CONSTRAINT fk_voter_constituency FOREIGN KEY (ConstituencyID) 
        REFERENCES Constituency(ConstituencyID) ON DELETE CASCADE,
    CONSTRAINT chk_national_id CHECK (LENGTH(NationalID) = 16)
);
-- ============================================================================
-- Table: Candidate
-- Stores candidate information for elections
-- ============================================================================
CREATE TABLE Candidate (
    CandidateID SERIAL PRIMARY KEY,
    PartyID INTEGER NOT NULL,
    ConstituencyID INTEGER NOT NULL,
    FullName VARCHAR(150) NOT NULL,
    Manifesto TEXT,
    CONSTRAINT fk_candidate_party FOREIGN KEY (PartyID) 
        REFERENCES Party(PartyID) ON DELETE CASCADE,
    CONSTRAINT fk_candidate_constituency FOREIGN KEY (ConstituencyID) 
        REFERENCES Constituency(ConstituencyID) ON DELETE CASCADE,
    CONSTRAINT chk_candidate_name CHECK (LENGTH(TRIM(FullName)) > 0)
);
-- ============================================================================
-- Table: Ballot
-- Records individual votes cast by voters
-- CASCADE DELETE ensures ballots are removed if candidate is removed
-- ============================================================================
CREATE TABLE Ballot (
    BallotID SERIAL PRIMARY KEY,
    VoterID INTEGER NOT NULL,
    CandidateID INTEGER NOT NULL,
    VoteDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Validity VARCHAR(20) NOT NULL DEFAULT 'Valid' CHECK (Validity IN ('Valid', 'Invalid', 'Disputed')),
    CONSTRAINT fk_ballot_voter FOREIGN KEY (VoterID) 
        REFERENCES Voter(VoterID) ON DELETE CASCADE,
    CONSTRAINT fk_ballot_candidate FOREIGN KEY (CandidateID) 
        REFERENCES Candidate(CandidateID) ON DELETE CASCADE
);
-- ============================================================================
-- Table: Result
-- Stores final tallied results for each candidate (1:1 with Candidate)
-- ============================================================================
CREATE TABLE Result (
    ResultID SERIAL PRIMARY KEY,
    CandidateID INTEGER NOT NULL UNIQUE,
    TotalVotes INTEGER NOT NULL DEFAULT 0 CHECK (TotalVotes >= 0),
    DeclaredDate TIMESTAMP,
    CONSTRAINT fk_result_candidate FOREIGN KEY (CandidateID) 
        REFERENCES Candidate(CandidateID) ON DELETE CASCADE
);
-- ============================================================================
-- Create Indexes for Performance
-- ============================================================================
CREATE INDEX idx_voter_constituency ON Voter(ConstituencyID);
CREATE INDEX idx_voter_national_id ON Voter(NationalID);
CREATE INDEX idx_candidate_party ON Candidate(PartyID);
CREATE INDEX idx_candidate_constituency ON Candidate(ConstituencyID);
CREATE INDEX idx_ballot_voter ON Ballot(VoterID);
CREATE INDEX idx_ballot_candidate ON Ballot(CandidateID);
CREATE INDEX idx_ballot_date ON Ballot(VoteDate);
CREATE INDEX idx_result_candidate ON Result(CandidateID);
-- ============================================================================
-- Schema Creation Complete
-- ============================================================================
