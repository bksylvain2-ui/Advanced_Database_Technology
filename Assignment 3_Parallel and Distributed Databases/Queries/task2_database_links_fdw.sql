-- =====================================================
-- TASK 2: Create and Use Database Links (FDW Simulation)
-- Assignment 3: Distributed and Parallel Database
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: 
-- 1. Run task1_create_schema.sql (basic tasks)
-- 2. Run task3_insert_mock_data.sql (basic tasks)
-- 3. Run task1_distributed_schema_fragmentation.sql (Assignment 3)

-- PostgreSQL uses Foreign Data Wrapper (FDW) instead of Oracle database links
-- We'll use postgres_fdw to connect between schemas

-- =====================================================
-- STEP 1: Enable Foreign Data Wrapper Extension
-- =====================================================

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- =====================================================
-- STEP 2: Create Foreign Server (simulates database link)
-- =====================================================

-- Note: In a real distributed setup, you'd connect to a different database
-- For simulation, we're connecting to the same database but different schema

-- Create foreign server pointing to Node B schema
-- In production, this would be: OPTIONS (host 'remote_host', dbname 'evotingdb')
DROP SERVER IF EXISTS nodeB_server CASCADE;
CREATE SERVER nodeB_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (dbname 'evotingdb');

-- =====================================================
-- STEP 3: Create User Mapping
-- =====================================================

-- Map current user to remote server
CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
    SERVER nodeB_server
    OPTIONS (user 'postgres', password 'your_password');

-- Note: Replace 'your_password' with actual PostgreSQL password
-- Or use a safer authentication method in production

-- =====================================================
-- STEP 4: Create Foreign Table (simulates remote table access)
-- =====================================================

-- Import foreign schema from Node B
IMPORT FOREIGN SCHEMA evotingdb_nodeB
    FROM SERVER nodeB_server
    INTO evotingdb_nodeA;

-- This creates foreign tables in Node A schema that reference Node B tables
-- Now we can query Node B tables from Node A using: evotingdb_nodeA.candidate, etc.

-- Alternative: Create specific foreign table manually
-- DROP FOREIGN TABLE IF EXISTS evotingdb_nodeA.foreign_candidate;
-- CREATE FOREIGN TABLE evotingdb_nodeA.foreign_candidate (
--     CandidateID INTEGER,
--     PartyID INTEGER,
--     ConstituencyID INTEGER,
--     FullName VARCHAR(100),
--     Manifesto TEXT
-- ) SERVER nodeB_server
-- OPTIONS (schema_name 'evotingdb_nodeB', table_name 'candidate');

-- =====================================================
-- STEP 5: Remote SELECT Query (Accessing Node B from Node A)
-- =====================================================

-- Query foreign table (Node B data from Node A)
SELECT 
    'Remote Query from Node A' AS QueryType,
    CandidateID,
    FullName,
    Manifesto
FROM 
    evotingdb_nodeB.candidate
ORDER BY 
    CandidateID;

-- =====================================================
-- STEP 6: Distributed Join (Local + Remote)
-- =====================================================

-- Join local Node A candidates with remote Node B candidates
SELECT 
    'Node A' AS SourceNode,
    c.CandidateID,
    c.FullName,
    con.Name AS ConstituencyName
FROM 
    evotingdb_nodeA.candidate c
    INNER JOIN evotingdb_nodeA.constituency con ON c.ConstituencyID = con.ConstituencyID
UNION ALL
SELECT 
    'Node B (Remote)' AS SourceNode,
    c.CandidateID,
    c.FullName,
    con.Name AS ConstituencyName
FROM 
    evotingdb_nodeB.candidate c
    INNER JOIN evotingdb_nodeB.constituency con ON c.ConstituencyID = con.ConstituencyID
ORDER BY 
    SourceNode, CandidateID;

-- =====================================================
-- STEP 7: Cross-Node Aggregation Query
-- =====================================================

-- Aggregate candidates from both nodes
SELECT 
    p.PartyName,
    COUNT(DISTINCT CASE WHEN c.CandidateID IN (
        SELECT CandidateID FROM evotingdb_nodeA.candidate
    ) THEN c.CandidateID END) AS NodeA_Candidates,
    COUNT(DISTINCT CASE WHEN c.CandidateID IN (
        SELECT CandidateID FROM evotingdb_nodeB.candidate
    ) THEN c.CandidateID END) AS NodeB_Candidates,
    COUNT(DISTINCT c.CandidateID) AS Total_Candidates
FROM 
    evotingdb_nodeA.party p
    LEFT JOIN (
        SELECT * FROM evotingdb_nodeA.candidate
        UNION ALL
        SELECT * FROM evotingdb_nodeB.candidate
    ) c ON p.PartyID = c.PartyID
GROUP BY 
    p.PartyName;

-- Explanation:
-- Foreign Data Wrapper (FDW) allows PostgreSQL to access remote data as if it were local.
-- This simulates Oracle's database links functionality.
-- Queries can join local and remote tables seamlessly.

