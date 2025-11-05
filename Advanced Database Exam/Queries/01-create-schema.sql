-- National E-Voting and Election Monitoring System
-- Database Schema for Rwanda

-- Drop tables if they exist (in reverse order of dependencies)
DROP TABLE IF EXISTS Results CASCADE;
DROP TABLE IF EXISTS Votes CASCADE;
DROP TABLE IF EXISTS Voters CASCADE;
DROP TABLE IF EXISTS Candidates CASCADE;
DROP TABLE IF EXISTS Constituencies CASCADE;
DROP TABLE IF EXISTS Parties CASCADE;

-- 1. Parties Table
CREATE TABLE Parties (
    PartyID SERIAL PRIMARY KEY,
    PartyName VARCHAR(100) NOT NULL UNIQUE,
    PartyLeader VARCHAR(100) NOT NULL,
    FoundedYear INT CHECK (FoundedYear >= 1900 AND FoundedYear <= EXTRACT(YEAR FROM CURRENT_DATE)),
    Ideology VARCHAR(50),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Constituencies Table
CREATE TABLE Constituencies (
    ConstituencyID SERIAL PRIMARY KEY,
    ConstituencyName VARCHAR(100) NOT NULL UNIQUE,
    Province VARCHAR(50) NOT NULL,
    RegisteredVoters INT NOT NULL CHECK (RegisteredVoters >= 0),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Candidates Table
CREATE TABLE Candidates (
    CandidateID SERIAL PRIMARY KEY,
    CandidateName VARCHAR(100) NOT NULL,
    PartyID INT NOT NULL,
    ConstituencyID INT NOT NULL,
    Age INT CHECK (Age >= 18),
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female', 'Other')),
    Education VARCHAR(100),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (PartyID) REFERENCES Parties(PartyID) ON DELETE CASCADE,
    FOREIGN KEY (ConstituencyID) REFERENCES Constituencies(ConstituencyID) ON DELETE CASCADE
);

-- 4. Voters Table
CREATE TABLE Voters (
    VoterID SERIAL PRIMARY KEY,
    VoterName VARCHAR(100) NOT NULL,
    NationalID VARCHAR(16) NOT NULL UNIQUE,
    ConstituencyID INT NOT NULL,
    Age INT CHECK (Age >= 18),
    Gender VARCHAR(10) CHECK (Gender IN ('Male', 'Female', 'Other')),
    HasVoted BOOLEAN DEFAULT FALSE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ConstituencyID) REFERENCES Constituencies(ConstituencyID) ON DELETE CASCADE
);

-- 5. Votes Table
CREATE TABLE Votes (
    VoteID SERIAL PRIMARY KEY,
    VoterID INT NOT NULL,
    CandidateID INT NOT NULL,
    ConstituencyID INT NOT NULL,
    VoteTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (VoterID) REFERENCES Voters(VoterID) ON DELETE CASCADE,
    FOREIGN KEY (CandidateID) REFERENCES Candidates(CandidateID) ON DELETE CASCADE,
    FOREIGN KEY (ConstituencyID) REFERENCES Constituencies(ConstituencyID) ON DELETE CASCADE,
    UNIQUE(VoterID) -- Ensures one vote per voter
);

-- 6. Results Table
CREATE TABLE Results (
    ResultID SERIAL PRIMARY KEY,
    CandidateID INT NOT NULL,
    ConstituencyID INT NOT NULL,
    TotalVotes INT DEFAULT 0 CHECK (TotalVotes >= 0),
    VotePercentage DECIMAL(5,2) DEFAULT 0.00,
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CandidateID) REFERENCES Candidates(CandidateID) ON DELETE CASCADE,
    FOREIGN KEY (ConstituencyID) REFERENCES Constituencies(ConstituencyID) ON DELETE CASCADE,
    UNIQUE(CandidateID, ConstituencyID)
);

-- Create indexes for better query performance
CREATE INDEX idx_candidates_party ON Candidates(PartyID);
CREATE INDEX idx_candidates_constituency ON Candidates(ConstituencyID);
CREATE INDEX idx_voters_constituency ON Voters(ConstituencyID);
CREATE INDEX idx_voters_national_id ON Voters(NationalID);
CREATE INDEX idx_votes_candidate ON Votes(CandidateID);
CREATE INDEX idx_votes_constituency ON Votes(ConstituencyID);
CREATE INDEX idx_results_constituency ON Results(ConstituencyID);

