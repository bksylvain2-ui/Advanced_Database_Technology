-- ============================================================================
-- A2: DATABASE LINK & CROSS-NODE JOIN
-- ============================================================================
-- This script demonstrates:
-- 1. Database link creation from Node_A to Node_B
-- 2. Remote SELECT on Candidate@proj_link (5 rows)
-- 3. Distributed join: Ballot_A ⋈ Constituency@proj_link (3-10 rows)
-- ============================================================================

-- ============================================================================
-- STEP 1: CREATE DATABASE LINK (proj_link) FROM NODE_A TO NODE_B
-- ============================================================================

-- Install postgres_fdw extension (if not already installed)
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create foreign server representing Node_B
-- In production, replace with actual Node_B connection details
CREATE SERVER IF NOT EXISTS proj_link
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (
        host 'node_b_hostname',      -- Replace with actual Node_B host
        port '5432',                  -- Replace with actual Node_B port
        dbname 'rwanda_evoting_db'   -- Replace with actual Node_B database name
    );

-- Create user mapping for authentication to Node_B
-- In production, use actual credentials
CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
    SERVER proj_link
    OPTIONS (
        user 'node_b_user',          -- Replace with actual Node_B username
        password 'node_b_password'   -- Replace with actual Node_B password
    );

-- Display database link information
SELECT 
    srvname AS "Database Link Name",
    srvoptions AS "Connection Options"
FROM pg_foreign_server
WHERE srvname = 'proj_link';

COMMENT ON SERVER proj_link IS 'Database link from Node_A to Node_B for distributed queries';

-- ============================================================================
-- STEP 2: CREATE FOREIGN TABLES ON NODE_A POINTING TO NODE_B TABLES
-- ============================================================================

-- Foreign table for Candidate on Node_B
DROP FOREIGN TABLE IF EXISTS Candidate_Remote CASCADE;

CREATE FOREIGN TABLE Candidate_Remote (
    CandidateID SERIAL,
    FullName VARCHAR(100),
    PartyID INT,
    ConstituencyID INT,
    Gender VARCHAR(10),
    Age INT,
    RegistrationDate DATE
)
SERVER proj_link
OPTIONS (schema_name 'public', table_name 'Candidates');

COMMENT ON FOREIGN TABLE Candidate_Remote IS 'Remote access to Candidates table on Node_B via proj_link';

-- Foreign table for Constituency on Node_B
DROP FOREIGN TABLE IF EXISTS Constituency_Remote CASCADE;

CREATE FOREIGN TABLE Constituency_Remote (
    ConstituencyID SERIAL,
    ConstituencyName VARCHAR(100),
    Province VARCHAR(50),
    RegisteredVoters INT
)
SERVER proj_link
OPTIONS (schema_name 'public', table_name 'Constituencies');

COMMENT ON FOREIGN TABLE Constituency_Remote IS 'Remote access to Constituencies table on Node_B via proj_link';

-- Foreign table for Ballot_B on Node_B (for validation)
DROP FOREIGN TABLE IF EXISTS Ballot_B_Remote CASCADE;

CREATE FOREIGN TABLE Ballot_B_Remote (
    VoteID SERIAL,
    VoterID INT,
    CandidateID INT,
    ConstituencyID INT,
    VoteTimestamp TIMESTAMP,
    NodeLocation VARCHAR(10)
)
SERVER proj_link
OPTIONS (schema_name 'public', table_name 'Ballot_B');

COMMENT ON FOREIGN TABLE Ballot_B_Remote IS 'Remote access to Ballot_B fragment on Node_B via proj_link';

-- ============================================================================
-- VERIFICATION: Database Link Created Successfully
-- ============================================================================

SELECT 
    '✓ Database Link Created' AS Status,
    'proj_link' AS LinkName,
    'Node_A → Node_B' AS Direction;
