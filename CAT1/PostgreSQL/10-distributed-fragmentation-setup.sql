-- ============================================================================
-- A1: HORIZONTAL FRAGMENTATION & RECOMBINATION OF BALLOT TABLE
-- ============================================================================
-- This script demonstrates distributed database concepts using PostgreSQL
-- with horizontal fragmentation across two nodes (Node_A and Node_B)
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE DATABASE LINK (Foreign Data Wrapper)
-- ============================================================================
-- In PostgreSQL, we use postgres_fdw extension to simulate database links
-- This would connect Node_A to Node_B

-- Enable the postgres_fdw extension (run on Node_A)
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create a foreign server representing Node_B
-- NOTE: Replace with actual Node_B connection details in production
CREATE SERVER IF NOT EXISTS node_b_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'localhost',      -- Replace with Node_B hostname
        port '5432',           -- Replace with Node_B port
        dbname 'evoting_node_b' -- Replace with Node_B database name
    );

-- Create user mapping for the foreign server
-- NOTE: Replace with actual credentials in production
CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
    SERVER node_b_server
    OPTIONS (
        user 'postgres',       -- Replace with Node_B username
        password 'password'    -- Replace with Node_B password
    );

-- ============================================================================
-- STEP 2: CREATE FRAGMENTED TABLES ON NODE_A AND NODE_B
-- ============================================================================
-- Fragmentation Strategy: HASH-based on VoterID
-- Rule: VoterID with EVEN last digit → Node_A
--       VoterID with ODD last digit → Node_B
-- ============================================================================

-- ----------------------------------------------------------------------------
-- NODE_A: Create Ballot_A (Fragment A)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS Ballot_A CASCADE;

CREATE TABLE Ballot_A (
    VoteID SERIAL PRIMARY KEY,
    VoterID INTEGER NOT NULL,
    CandidateID INTEGER NOT NULL,
    ConstituencyID INTEGER NOT NULL,
    VoteTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraint: Only voters with EVEN last digit in VoterID
    CONSTRAINT chk_ballot_a_partition 
        CHECK (MOD(VoterID, 10) IN (0, 2, 4, 6, 8)),
    
    -- Foreign key constraints (assuming base tables exist)
    CONSTRAINT fk_ballot_a_voter 
        FOREIGN KEY (VoterID) REFERENCES Voters(VoterID) ON DELETE CASCADE,
    CONSTRAINT fk_ballot_a_candidate 
        FOREIGN KEY (CandidateID) REFERENCES Candidates(CandidateID) ON DELETE CASCADE,
    CONSTRAINT fk_ballot_a_constituency 
        FOREIGN KEY (ConstituencyID) REFERENCES Constituencies(ConstituencyID) ON DELETE CASCADE
);

CREATE INDEX idx_ballot_a_voter ON Ballot_A(VoterID);
CREATE INDEX idx_ballot_a_candidate ON Ballot_A(CandidateID);
CREATE INDEX idx_ballot_a_constituency ON Ballot_A(ConstituencyID);

-- ----------------------------------------------------------------------------
-- NODE_B: Create Ballot_B (Fragment B)
-- ----------------------------------------------------------------------------
-- NOTE: This DDL should be executed on Node_B database
-- For simulation purposes, we'll create it locally and then create foreign table

DROP TABLE IF EXISTS Ballot_B CASCADE;

CREATE TABLE Ballot_B (
    VoteID SERIAL PRIMARY KEY,
    VoterID INTEGER NOT NULL,
    CandidateID INTEGER NOT NULL,
    ConstituencyID INTEGER NOT NULL,
    VoteTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraint: Only voters with ODD last digit in VoterID
    CONSTRAINT chk_ballot_b_partition 
        CHECK (MOD(VoterID, 10) IN (1, 3, 5, 7, 9)),
    
    -- Foreign key constraints (assuming base tables exist on Node_B)
    CONSTRAINT fk_ballot_b_voter 
        FOREIGN KEY (VoterID) REFERENCES Voters(VoterID) ON DELETE CASCADE,
    CONSTRAINT fk_ballot_b_candidate 
        FOREIGN KEY (CandidateID) REFERENCES Candidates(CandidateID) ON DELETE CASCADE,
    CONSTRAINT fk_ballot_b_constituency 
        FOREIGN KEY (ConstituencyID) REFERENCES Constituencies(ConstituencyID) ON DELETE CASCADE
);

CREATE INDEX idx_ballot_b_voter ON Ballot_B(VoterID);
CREATE INDEX idx_ballot_b_candidate ON Ballot_B(CandidateID);
CREATE INDEX idx_ballot_b_constituency ON Ballot_B(ConstituencyID);

-- ----------------------------------------------------------------------------
-- NODE_A: Create Foreign Table Reference to Ballot_B
-- ----------------------------------------------------------------------------
-- This allows Node_A to access Ballot_B on Node_B through the database link

DROP FOREIGN TABLE IF EXISTS Ballot_B_Remote CASCADE;

CREATE FOREIGN TABLE Ballot_B_Remote (
    VoteID INTEGER,
    VoterID INTEGER,
    CandidateID INTEGER,
    ConstituencyID INTEGER,
    VoteTimestamp TIMESTAMP
)
SERVER node_b_server
OPTIONS (schema_name 'public', table_name 'Ballot_B');

-- ============================================================================
-- STEP 3: INSERT ≤10 COMMITTED ROWS ACROSS FRAGMENTS
-- ============================================================================
-- Total: 10 rows (5 on Node_A, 5 on Node_B)
-- Fragmentation based on VoterID last digit (EVEN → A, ODD → B)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Insert into Ballot_A (Node_A) - 5 rows with EVEN VoterID last digit
-- ----------------------------------------------------------------------------
INSERT INTO Ballot_A (VoterID, CandidateID, ConstituencyID, VoteTimestamp) VALUES
(1000, 1, 1, '2024-01-15 08:30:00'),  -- VoterID ends in 0 (EVEN)
(1002, 2, 1, '2024-01-15 09:15:00'),  -- VoterID ends in 2 (EVEN)
(1004, 3, 2, '2024-01-15 10:00:00'),  -- VoterID ends in 4 (EVEN)
(1006, 4, 2, '2024-01-15 11:30:00'),  -- VoterID ends in 6 (EVEN)
(1008, 5, 3, '2024-01-15 12:45:00');  -- VoterID ends in 8 (EVEN)

-- Commit the transaction
COMMIT;

-- ----------------------------------------------------------------------------
-- Insert into Ballot_B (Node_B) - 5 rows with ODD VoterID last digit
-- ----------------------------------------------------------------------------
-- NOTE: This should be executed on Node_B database
-- For simulation, we execute locally

INSERT INTO Ballot_B (VoterID, CandidateID, ConstituencyID, VoteTimestamp) VALUES
(1001, 6, 3, '2024-01-15 08:45:00'),  -- VoterID ends in 1 (ODD)
(1003, 7, 4, '2024-01-15 09:30:00'),  -- VoterID ends in 3 (ODD)
(1005, 8, 4, '2024-01-15 10:15:00'),  -- VoterID ends in 5 (ODD)
(1007, 9, 5, '2024-01-15 11:00:00'),  -- VoterID ends in 7 (ODD)
(1009, 10, 5, '2024-01-15 13:00:00'); -- VoterID ends in 9 (ODD)

-- Commit the transaction
COMMIT;

-- ============================================================================
-- STEP 4: CREATE UNIFIED VIEW (RECOMBINATION)
-- ============================================================================
-- Ballot_ALL view on Node_A combines local Ballot_A and remote Ballot_B
-- ============================================================================

DROP VIEW IF EXISTS Ballot_ALL CASCADE;

CREATE VIEW Ballot_ALL AS
    -- Local fragment from Node_A
    SELECT 
        VoteID,
        VoterID,
        CandidateID,
        ConstituencyID,
        VoteTimestamp,
        'Node_A' AS SourceNode
    FROM Ballot_A
    
    UNION ALL
    
    -- Remote fragment from Node_B (accessed via foreign table)
    SELECT 
        VoteID,
        VoterID,
        CandidateID,
        ConstituencyID,
        VoteTimestamp,
        'Node_B' AS SourceNode
    FROM Ballot_B_Remote;

-- Add comment to the view
COMMENT ON VIEW Ballot_ALL IS 
'Unified view combining horizontally fragmented Ballot tables from Node_A and Node_B using UNION ALL';

-- ============================================================================
-- STEP 5: VALIDATION QUERIES
-- ============================================================================
-- Verify data integrity and correct fragmentation
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Validation 1: COUNT(*) Verification
-- ----------------------------------------------------------------------------
-- Expected: 10 total rows (5 from Node_A + 5 from Node_B)

SELECT 'Fragment Counts' AS validation_type;

SELECT 
    'Ballot_A (Node_A)' AS fragment,
    COUNT(*) AS row_count
FROM Ballot_A

UNION ALL

SELECT 
    'Ballot_B (Node_B)' AS fragment,
    COUNT(*) AS row_count
FROM Ballot_B

UNION ALL

SELECT 
    'Ballot_ALL (Combined)' AS fragment,
    COUNT(*) AS row_count
FROM Ballot_ALL;

-- Expected Output:
-- Fragment          | row_count
-- ------------------|----------
-- Ballot_A (Node_A) | 5
-- Ballot_B (Node_B) | 5
-- Ballot_ALL        | 10

-- ----------------------------------------------------------------------------
-- Validation 2: CHECKSUM Verification using MOD(VoteID, 97)
-- ----------------------------------------------------------------------------
-- Verify data integrity by comparing checksums

SELECT 'Checksum Validation' AS validation_type;

SELECT 
    'Ballot_A (Node_A)' AS fragment,
    SUM(MOD(VoteID, 97)) AS checksum,
    COUNT(*) AS row_count
FROM Ballot_A

UNION ALL

SELECT 
    'Ballot_B (Node_B)' AS fragment,
    SUM(MOD(VoteID, 97)) AS checksum,
    COUNT(*) AS row_count
FROM Ballot_B

UNION ALL

SELECT 
    'Ballot_ALL (Combined)' AS fragment,
    SUM(MOD(VoteID, 97)) AS checksum,
    COUNT(*) AS row_count
FROM Ballot_ALL

UNION ALL

SELECT 
    'Sum of Fragments' AS fragment,
    (SELECT SUM(MOD(VoteID, 97)) FROM Ballot_A) + 
    (SELECT SUM(MOD(VoteID, 97)) FROM Ballot_B) AS checksum,
    (SELECT COUNT(*) FROM Ballot_A) + 
    (SELECT COUNT(*) FROM Ballot_B) AS row_count;

-- Expected: Checksum and row_count for Ballot_ALL should match Sum of Fragments

-- ----------------------------------------------------------------------------
-- Validation 3: Verify Fragmentation Rule (EVEN/ODD VoterID)
-- ----------------------------------------------------------------------------
SELECT 'Fragmentation Rule Validation' AS validation_type;

-- Check Ballot_A: All VoterIDs should have EVEN last digit
SELECT 
    'Ballot_A - EVEN Check' AS test,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE MOD(VoterID, 10) IN (0,2,4,6,8)) AS even_rows,
    COUNT(*) FILTER (WHERE MOD(VoterID, 10) IN (1,3,5,7,9)) AS odd_rows,
    CASE 
        WHEN COUNT(*) FILTER (WHERE MOD(VoterID, 10) IN (1,3,5,7,9)) = 0 
        THEN '✓ PASS' 
        ELSE '✗ FAIL' 
    END AS status
FROM Ballot_A

UNION ALL

-- Check Ballot_B: All VoterIDs should have ODD last digit
SELECT 
    'Ballot_B - ODD Check' AS test,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE MOD(VoterID, 10) IN (0,2,4,6,8)) AS even_rows,
    COUNT(*) FILTER (WHERE MOD(VoterID, 10) IN (1,3,5,7,9)) AS odd_rows,
    CASE 
        WHEN COUNT(*) FILTER (WHERE MOD(VoterID, 10) IN (0,2,4,6,8)) = 0 
        THEN '✓ PASS' 
        ELSE '✗ FAIL' 
    END AS status
FROM Ballot_B;

-- ----------------------------------------------------------------------------
-- Validation 4: Data Distribution by Node
-- ----------------------------------------------------------------------------
SELECT 'Data Distribution by Node' AS validation_type;

SELECT 
    SourceNode,
    COUNT(*) AS vote_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Ballot_ALL), 2) AS percentage
FROM Ballot_ALL
GROUP BY SourceNode
ORDER BY SourceNode;

-- Expected: 50% on Node_A, 50% on Node_B

-- ----------------------------------------------------------------------------
-- Validation 5: Sample Data from Unified View
-- ----------------------------------------------------------------------------
SELECT 'Sample Data from Ballot_ALL' AS validation_type;

SELECT 
    VoteID,
    VoterID,
    CandidateID,
    ConstituencyID,
    VoteTimestamp,
    SourceNode,
    MOD(VoterID, 10) AS voter_last_digit
FROM Ballot_ALL
ORDER BY VoterID;

-- ============================================================================
-- ADDITIONAL UTILITY QUERIES
-- ============================================================================

-- Query to show fragmentation statistics
CREATE OR REPLACE VIEW Fragmentation_Stats AS
SELECT 
    'Total Votes' AS metric,
    (SELECT COUNT(*) FROM Ballot_ALL) AS value
UNION ALL
SELECT 
    'Votes on Node_A',
    (SELECT COUNT(*) FROM Ballot_A)
UNION ALL
SELECT 
    'Votes on Node_B',
    (SELECT COUNT(*) FROM Ballot_B)
UNION ALL
SELECT 
    'Fragmentation Ratio (A:B)',
    ROUND((SELECT COUNT(*)::NUMERIC FROM Ballot_A) / 
          NULLIF((SELECT COUNT(*) FROM Ballot_B), 0), 2);

-- Query the statistics
SELECT * FROM Fragmentation_Stats;

-- ============================================================================
-- CLEANUP (Optional - for testing purposes)
-- ============================================================================
/*
-- To reset and start over:
DROP VIEW IF EXISTS Ballot_ALL CASCADE;
DROP VIEW IF EXISTS Fragmentation_Stats CASCADE;
DROP FOREIGN TABLE IF EXISTS Ballot_B_Remote CASCADE;
DROP TABLE IF EXISTS Ballot_A CASCADE;
DROP TABLE IF EXISTS Ballot_B CASCADE;
DROP USER MAPPING IF EXISTS FOR CURRENT_USER SERVER node_b_server;
DROP SERVER IF EXISTS node_b_server CASCADE;
DROP EXTENSION IF EXISTS postgres_fdw CASCADE;
*/
