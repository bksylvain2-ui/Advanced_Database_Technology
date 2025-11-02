-- =====================================================
-- TASK 11: Parallel Query Execution
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: 
-- 1. Run task1_create_schema.sql
-- 2. Run task3_insert_mock_data.sql

-- PostgreSQL automatically uses parallel execution when beneficial
-- We'll demonstrate serial vs parallel query performance

-- =====================================================
-- STEP 1: Check Current Parallel Settings
-- =====================================================

-- View current parallel configuration
SELECT 
    name,
    setting,
    unit,
    short_desc
FROM 
    pg_settings
WHERE 
    name LIKE '%parallel%'
ORDER BY 
    name;

-- =====================================================
-- STEP 2: Enable Parallel Query Execution
-- =====================================================

-- Enable parallel query execution (PostgreSQL 9.6+)
SET max_parallel_workers_per_gather = 4;
SET parallel_setup_cost = 10;
SET parallel_tuple_cost = 0.01;
SET min_parallel_table_scan_size = 8MB;
SET min_parallel_index_scan_size = 512KB;

-- =====================================================
-- STEP 3: Create Large Dataset for Testing
-- =====================================================

-- Insert more sample data to make queries benefit from parallelism
-- (Run this to expand the dataset)
DO $$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..1000 LOOP
        INSERT INTO Ballot (VoterID, CandidateID, VoteDate, Validity)
        VALUES (
            (RANDOM() * 5 + 1)::INTEGER,
            (RANDOM() * 5 + 1)::INTEGER,
            CURRENT_TIMESTAMP - (RANDOM() * 365 || ' days')::INTERVAL,
            CASE WHEN RANDOM() > 0.1 THEN 'Valid' ELSE 'Invalid' END
        );
    END LOOP;
END $$;

-- =====================================================
-- STEP 4: Serial Query Execution (Baseline)
-- =====================================================

-- Disable parallel execution
SET max_parallel_workers_per_gather = 0;

-- Run query and analyze
EXPLAIN (ANALYZE, BUFFERS, TIMING) 
SELECT 
    c.FullName AS CandidateName,
    p.PartyName,
    COUNT(b.BallotID) AS TotalVotes,
    SUM(CASE WHEN b.Validity = 'Valid' THEN 1 ELSE 0 END) AS ValidVotes
FROM 
    Candidate c
    INNER JOIN Party p ON c.PartyID = p.PartyID
    LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID
GROUP BY 
    c.CandidateID, c.FullName, p.PartyName
ORDER BY 
    TotalVotes DESC;

-- Note the execution time from the EXPLAIN output

-- =====================================================
-- STEP 5: Parallel Query Execution
-- =====================================================

-- Enable parallel execution
SET max_parallel_workers_per_gather = 4;

-- Run same query with parallelism enabled
EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE) 
SELECT 
    c.FullName AS CandidateName,
    p.PartyName,
    COUNT(b.BallotID) AS TotalVotes,
    SUM(CASE WHEN b.Validity = 'Valid' THEN 1 ELSE 0 END) AS ValidVotes
FROM 
    Candidate c
    INNER JOIN Party p ON c.PartyID = p.PartyID
    LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID
GROUP BY 
    c.CandidateID, c.FullName, p.PartyName
ORDER BY 
    TotalVotes DESC;

-- Look for "Workers Launched" in the EXPLAIN output
-- This indicates parallel execution occurred

-- =====================================================
-- STEP 6: Parallel Aggregation Query
-- =====================================================

-- Complex query that benefits from parallelism
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    con.Region,
    p.PartyName,
    COUNT(DISTINCT c.CandidateID) AS Candidates,
    COUNT(b.BallotID) AS TotalBallots,
    ROUND(AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - b.VoteDate)) / 86400), 2) AS AvgDaysSinceVote
FROM 
    Constituency con
    INNER JOIN Candidate c ON con.ConstituencyID = c.ConstituencyID
    INNER JOIN Party p ON c.PartyID = p.PartyID
    LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID
GROUP BY 
    con.Region, p.PartyName
HAVING 
    COUNT(b.BallotID) > 0
ORDER BY 
    TotalBallots DESC;

-- =====================================================
-- STEP 7: Compare Execution Plans
-- =====================================================

-- Query to check if parallel workers were used
SELECT 
    pid,
    usename,
    query,
    state,
    wait_event_type,
    wait_event
FROM 
    pg_stat_activity
WHERE 
    query LIKE '%Ballot%'
    AND state = 'active';

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check parallel query statistics
SELECT 
    schemaname,
    tablename,
    seq_scan,
    idx_scan,
    n_tup_ins,
    n_tup_upd,
    n_tup_del
FROM 
    pg_stat_user_tables
WHERE 
    tablename IN ('ballot', 'candidate', 'voter')
ORDER BY 
    tablename;

-- Explanation:
-- PostgreSQL automatically decides when to use parallel execution based on:
-- 1. Table size (must exceed min_parallel_table_scan_size)
-- 2. Query complexity
-- 3. Available CPU cores (max_parallel_workers_per_gather)
-- Look for "Workers Launched: X" in EXPLAIN output to confirm parallelism.

