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
-- Since both Node A and Node B are in the same database (different schemas),
-- we can query them directly without FDW. However, FDW setup is included for
-- demonstration of distributed database concepts.

-- =====================================================
-- CLEANUP: Remove any existing FDW objects (if they exist)
-- =====================================================

-- Drop any existing foreign server to avoid conflicts
DROP SERVER IF EXISTS nodeB_server CASCADE;
DROP SERVER IF EXISTS nodeb_server CASCADE;

-- =====================================================
-- APPROACH 1: Direct Schema Queries (Recommended for Same Database)
-- =====================================================

-- Since both nodes are in the same database, you can query them directly
-- This is simpler and doesn't require FDW setup
-- Example: SELECT * FROM evotingdb_nodeA.candidate UNION ALL SELECT * FROM evotingdb_nodeB.candidate

-- =====================================================
-- APPROACH 2: Foreign Data Wrapper Setup (Optional - for demonstration)
-- =====================================================

-- NOTE: FDW setup is optional since both schemas are in the same database.
-- Uncomment the section below ONLY if you want to demonstrate FDW functionality.
-- For most cases, use Approach 1 (direct schema queries) above.

/*
-- STEP 1: Enable Foreign Data Wrapper Extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- STEP 2: Create Foreign Server
-- For same database, use localhost without password in options
DROP SERVER IF EXISTS nodeB_server CASCADE;
CREATE SERVER nodeB_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'evotingdb');

-- STEP 3: Create User Mapping (optional - for authentication)
-- If your PostgreSQL uses trust/local authentication, you may skip this
-- Or use your actual PostgreSQL credentials:
DROP USER MAPPING IF EXISTS FOR CURRENT_USER SERVER nodeB_server;
CREATE USER MAPPING FOR CURRENT_USER
    SERVER nodeB_server
    OPTIONS (user CURRENT_USER);

-- STEP 4: Import Foreign Schema (optional)
-- This step is not necessary since we can query schemas directly
-- IMPORT FOREIGN SCHEMA evotingdb_nodeB
--     FROM SERVER nodeB_server
--     INTO evotingdb_nodeA;
*/

-- =====================================================
-- STEP 3: Remote SELECT Query (Accessing Node B from Node A)
-- =====================================================

-- Query Node B data directly (works without FDW since same database)
SELECT 
    'Remote Query from Node A' AS QueryType,
    'Node B Data' AS SourceNode,
    CandidateID,
    FullName,
    Manifesto
FROM 
    evotingdb_nodeB.candidate
ORDER BY 
    CandidateID;

-- This query works because both schemas are in the same database
-- In a real distributed setup with FDW, you would query foreign tables

-- =====================================================
-- STEP 4: Distributed Join (Local + Remote)
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
-- STEP 5: Cross-Node Aggregation Query
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

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify FDW extension (if you chose to enable it)
SELECT 
    'FDW Extension Status' AS Check,
    CASE WHEN EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgres_fdw')
         THEN 'Installed' 
         ELSE 'Not Required - Using Direct Schema Access' 
    END AS Status;

-- Verify both schemas are accessible
SELECT 
    'Schema Access Test' AS Check,
    'Node A' AS Schema,
    COUNT(*) AS TableCount,
    CASE WHEN COUNT(*) > 0 THEN '✓ Accessible' ELSE '✗ Not Found' END AS Status
FROM 
    information_schema.tables
WHERE 
    table_schema = 'evotingdb_nodea'
UNION ALL
SELECT 
    'Schema Access Test' AS Check,
    'Node B' AS Schema,
    COUNT(*) AS TableCount,
    CASE WHEN COUNT(*) > 0 THEN '✓ Accessible' ELSE '✗ Not Found' END AS Status
FROM 
    information_schema.tables
WHERE 
    table_schema = 'evotingdb_nodeb';

-- Test distributed query across both nodes
SELECT 
    'Distributed Query Test' AS Check,
    COUNT(*) AS TotalCandidates,
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS Status
FROM (
    SELECT CandidateID, FullName FROM evotingdb_nodeA.candidate
    UNION ALL
    SELECT CandidateID, FullName FROM evotingdb_nodeB.candidate
) combined_candidates;

-- Explanation:
-- Since both Node A and Node B schemas are in the same database (evotingdb),
-- you can query them directly using schema.table notation without needing FDW.
-- Foreign Data Wrapper (FDW) is useful when connecting to a DIFFERENT database or server.
-- For this assignment, direct schema access is simpler and more reliable.
-- The FDW setup is provided as an optional demonstration for distributed database concepts.

