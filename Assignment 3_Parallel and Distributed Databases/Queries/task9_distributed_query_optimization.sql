-- =====================================================
-- TASK 9: Distributed Query Optimization
-- Assignment 3: Distributed and Parallel Database
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: 
-- 1. Run task1_create_schema.sql (basic tasks)
-- 2. Run task1_distributed_schema_fragmentation.sql (Assignment 3)
-- 3. Run task2_database_links_fdw.sql (Assignment 3)

-- Analyze how PostgreSQL optimizer handles distributed joins across FDWs

-- =====================================================
-- STEP 1: Enable Query Planning Details
-- =====================================================

-- Enable detailed query planning output
SET explain_format = 'text';  -- or 'json', 'xml', 'yaml'
SET explain_analyze = true;
SET explain_buffers = true;
SET explain_verbose = true;

-- =====================================================
-- STEP 2: Analyze Simple Distributed Query
-- =====================================================

-- Query joining local and remote tables
EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
SELECT 
    a.FullName AS NodeA_Candidate,
    b.FullName AS NodeB_Candidate,
    a_party.PartyName AS NodeA_Party,
    b_party.PartyName AS NodeB_Party
FROM 
    evotingdb_nodeA.candidate a
    INNER JOIN evotingdb_nodeA.party a_party ON a.PartyID = a_party.PartyID
    CROSS JOIN evotingdb_nodeB.candidate b
    INNER JOIN evotingdb_nodeB.party b_party ON b.PartyID = b_party.PartyID
WHERE 
    a_party.PartyName = b_party.PartyName
ORDER BY 
    a.FullName, b.FullName;

-- Analyze the execution plan:
-- Look for:
-- 1. Foreign Scan (remote table access)
-- 2. Join methods (Hash Join, Nested Loop, Merge Join)
-- 3. Cost estimates
-- 4. Actual execution time

-- =====================================================
-- STEP 3: Distributed Join with Aggregation
-- =====================================================

EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
SELECT 
    p.PartyName,
    COUNT(DISTINCT CASE 
        WHEN c.CandidateID IN (SELECT CandidateID FROM evotingdb_nodeA.candidate) 
        THEN c.CandidateID 
    END) AS NodeA_Candidates,
    COUNT(DISTINCT CASE 
        WHEN c.CandidateID IN (SELECT CandidateID FROM evotingdb_nodeB.candidate) 
        THEN c.CandidateID 
    END) AS NodeB_Candidates,
    SUM(b_count.TotalBallots) AS TotalBallots
FROM 
    evotingdb_nodeA.party p
    LEFT JOIN (
        SELECT PartyID, CandidateID FROM evotingdb_nodeA.candidate
        UNION ALL
        SELECT PartyID, CandidateID FROM evotingdb_nodeB.candidate
    ) c ON p.PartyID = c.PartyID
    LEFT JOIN (
        SELECT 
            c.CandidateID,
            COUNT(b.BallotID) AS TotalBallots
        FROM 
            evotingdb_nodeA.candidate c
            LEFT JOIN evotingdb_nodeA.ballot b ON c.CandidateID = b.CandidateID
        GROUP BY c.CandidateID
        UNION ALL
        SELECT 
            c.CandidateID,
            COUNT(b.BallotID) AS TotalBallots
        FROM 
            evotingdb_nodeB.candidate c
            LEFT JOIN evotingdb_nodeB.ballot b ON c.CandidateID = b.CandidateID
        GROUP BY c.CandidateID
    ) b_count ON c.CandidateID = b_count.CandidateID
GROUP BY 
    p.PartyName
ORDER BY 
    TotalBallots DESC;

-- =====================================================
-- STEP 4: Optimizer Strategy Analysis
-- =====================================================

-- View optimizer statistics and configuration
SELECT 
    name,
    setting,
    unit,
    context,
    short_desc
FROM 
    pg_settings
WHERE 
    name IN (
        'enable_hashjoin',
        'enable_mergejoin',
        'enable_nestloop',
        'join_collapse_limit',
        'from_collapse_limit',
        'random_page_cost',
        'seq_page_cost'
    )
ORDER BY 
    name;

-- =====================================================
-- STEP 5: Compare Join Strategies
-- =====================================================

-- Force specific join types to compare performance

-- Hash Join (enable others, disable rest)
SET enable_hashjoin = ON;
SET enable_mergejoin = OFF;
SET enable_nestloop = OFF;

EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    a.FullName,
    b.FullName,
    a_party.PartyName
FROM 
    evotingdb_nodeA.candidate a
    INNER JOIN evotingdb_nodeA.party a_party ON a.PartyID = a_party.PartyID
    INNER JOIN evotingdb_nodeB.candidate b ON a.PartyID = (
        SELECT PartyID FROM evotingdb_nodeB.party WHERE PartyName = a_party.PartyName
    )
ORDER BY 
    a.FullName;

-- Reset join strategies
SET enable_hashjoin = ON;
SET enable_mergejoin = ON;
SET enable_nestloop = ON;

-- =====================================================
-- STEP 6: Data Movement Minimization
-- =====================================================

-- Optimize query to minimize data transfer between nodes
-- Push filters down to remote nodes when possible

EXPLAIN (ANALYZE, BUFFERS, VERBOSE) 
SELECT 
    node_a.FullName AS CandidateA,
    node_b.FullName AS CandidateB,
    node_a_party.PartyName
FROM 
    (
        SELECT c.*, p.PartyName 
        FROM evotingdb_nodeA.candidate c
        INNER JOIN evotingdb_nodeA.party p ON c.PartyID = p.PartyID
        WHERE p.PartyName = 'Rwandan Patriotic Front'  -- Filter pushed to remote
    ) node_a
    CROSS JOIN 
    (
        SELECT c.*, p.PartyName 
        FROM evotingdb_nodeB.candidate c
        INNER JOIN evotingdb_nodeB.party p ON c.PartyID = p.PartyID
        WHERE p.PartyName = 'Rwandan Patriotic Front'  -- Filter pushed to remote
    ) node_b
WHERE 
    node_a.PartyName = node_b.PartyName;

-- =====================================================
-- STEP 7: Distributed Query with Indexes
-- =====================================================

-- Create indexes to optimize distributed queries
CREATE INDEX IF NOT EXISTS idx_candidate_party 
    ON evotingdb_nodeA.candidate(PartyID);
CREATE INDEX IF NOT EXISTS idx_candidate_party_b 
    ON evotingdb_nodeB.candidate(PartyID);

CREATE INDEX IF NOT EXISTS idx_ballot_candidate 
    ON evotingdb_nodeA.ballot(CandidateID);
CREATE INDEX IF NOT EXISTS idx_ballot_candidate_b 
    ON evotingdb_nodeB.ballot(CandidateID);

-- Analyze query with indexes
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    a.FullName AS NodeA_Candidate,
    b.FullName AS NodeB_Candidate,
    COUNT(a_ballot.BallotID) AS NodeA_Votes,
    COUNT(b_ballot.BallotID) AS NodeB_Votes
FROM 
    evotingdb_nodeA.candidate a
    INNER JOIN evotingdb_nodeA.ballot a_ballot ON a.CandidateID = a_ballot.CandidateID
    CROSS JOIN evotingdb_nodeB.candidate b
    INNER JOIN evotingdb_nodeB.ballot b_ballot ON b.CandidateID = b_ballot.CandidateID
    INNER JOIN evotingdb_nodeA.party a_party ON a.PartyID = a_party.PartyID
    INNER JOIN evotingdb_nodeB.party b_party ON b.PartyID = b_party.PartyID
WHERE 
    a_party.PartyName = b_party.PartyName
GROUP BY 
    a.FullName, b.FullName
HAVING 
    COUNT(a_ballot.BallotID) > 0 OR COUNT(b_ballot.BallotID) > 0;

-- =====================================================
-- STEP 8: Query Cost Analysis
-- =====================================================

-- Compare query costs
EXPLAIN (COSTS, VERBOSE, BUFFERS) 
SELECT 
    p.PartyName,
    COUNT(*) AS TotalCandidates
FROM 
    evotingdb_nodeA.party p
    INNER JOIN (
        SELECT PartyID, CandidateID FROM evotingdb_nodeA.candidate
        UNION ALL
        SELECT PartyID, CandidateID FROM evotingdb_nodeB.candidate
    ) c ON p.PartyID = c.PartyID
GROUP BY 
    p.PartyName;

-- =====================================================
-- STEP 9: View Execution Statistics
-- =====================================================

-- Query execution statistics from pg_stat_statements (if enabled)
-- First enable extension: CREATE EXTENSION pg_stat_statements;

SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    rows,
    100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0) AS cache_hit_ratio
FROM 
    pg_stat_statements
WHERE 
    query LIKE '%evotingdb_node%'
ORDER BY 
    mean_exec_time DESC
LIMIT 10;

-- =====================================================
-- STEP 10: Optimization Recommendations
-- =====================================================

-- Analyze table statistics for optimizer
ANALYZE evotingdb_nodeA.candidate;
ANALYZE evotingdb_nodeA.party;
ANALYZE evotingdb_nodeA.ballot;
ANALYZE evotingdb_nodeB.candidate;
ANALYZE evotingdb_nodeB.party;
ANALYZE evotingdb_nodeB.ballot;

-- View table statistics
SELECT 
    schemaname,
    tablename,
    n_live_tup AS RowCount,
    n_dead_tup AS DeadRows,
    last_vacuum,
    last_analyze
FROM 
    pg_stat_user_tables
WHERE 
    schemaname IN ('evotingdb_nodea', 'evotingdb_nodeb')
ORDER BY 
    schemaname, tablename;

-- =====================================================
-- EXPLANATION
-- =====================================================

-- PostgreSQL Query Optimizer Strategies for Distributed Queries:
-- 
-- 1. Cost-Based Optimization:
--    - Estimates cost of different execution plans
--    - Chooses plan with lowest cost
--    - Considers: CPU cost, I/O cost, network transfer cost
--
-- 2. Join Order Optimization:
--    - Reorders joins to minimize intermediate result sizes
--    - Pushes filters to remote nodes (predicate pushdown)
--    - Uses statistics to estimate selectivity
--
-- 3. Data Movement Minimization:
--    - Prefers joining local tables first
--    - Transfers only necessary columns (projection pushdown)
--    - Filters data at remote nodes before transfer
--
-- 4. Execution Methods:
--    - Hash Join: Fast for large datasets
--    - Nested Loop: Good for small datasets or indexed lookups
--    - Merge Join: Efficient for sorted data
--
-- 5. Parallel Execution:
--    - Uses multiple workers for expensive operations
--    - Distributes work across CPU cores
--    - Benefits from FDW parallel scans
--
-- 6. Index Usage:
--    - Uses indexes to avoid full table scans
--    - Foreign table indexes improve remote query performance
--    - Statistics guide index selection

