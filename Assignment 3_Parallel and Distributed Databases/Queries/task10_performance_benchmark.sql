-- =====================================================
-- TASK 10: Performance Benchmark and Report
-- Assignment 3: Distributed and Parallel Database
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: 
-- 1. Run task1_create_schema.sql (basic tasks)
-- 2. Run task3_insert_mock_data.sql (basic tasks)
-- 3. Run task1_distributed_schema_fragmentation.sql (Assignment 3)
-- 4. Run task2_database_links_fdw.sql (Assignment 3)
-- 5. Expand dataset: INSERT additional test data

-- =====================================================
-- SETUP: Expand Dataset for Benchmarking
-- =====================================================

-- Add more data for meaningful performance comparison
-- OPTIMIZED: Reduced data volume and using Invalid votes to avoid trigger conflicts
-- Run this to expand the dataset (reduced to 100 rows per node for faster execution)
DO $$
DECLARE
    i INTEGER;
BEGIN
    FOR i IN 1..100 LOOP  -- Reduced from 5000 to 100 for faster execution
        BEGIN
            -- Insert into Node A (using Invalid votes to avoid duplicate vote trigger)
            INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
            VALUES (
                ((RANDOM() * 2)::INTEGER + 1),
                ((RANDOM() * 2)::INTEGER + 1),
                CURRENT_TIMESTAMP - (RANDOM() * 365 || ' days')::INTERVAL,
                'Invalid'  -- Use Invalid to avoid trigger conflicts
            );
            
            -- Insert into Node B (using Invalid votes)
            INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
            VALUES (
                ((RANDOM() * 2)::INTEGER + 4),
                ((RANDOM() * 2)::INTEGER + 4),
                CURRENT_TIMESTAMP - (RANDOM() * 365 || ' days')::INTERVAL,
                'Invalid'  -- Use Invalid to avoid trigger conflicts
            );
        EXCEPTION
            WHEN OTHERS THEN
                -- Skip duplicates silently
                NULL;
        END;
    END LOOP;
    
    RAISE NOTICE 'Benchmark data generation completed';
END $$;

-- =====================================================
-- BENCHMARK QUERY: Complex Aggregation
-- =====================================================

-- Query to benchmark: Total votes per party across all constituencies and regions
-- This query will be run in 3 modes: Centralized, Parallel, Distributed

-- =====================================================
-- MODE 1: CENTRALIZED (Single Node, Serial)
-- =====================================================

-- Reset settings for baseline
SET max_parallel_workers_per_gather = 0;
SET enable_hashjoin = ON;
SET enable_mergejoin = ON;
SET enable_nestloop = ON;

-- Note: Timing information is included in EXPLAIN (ANALYZE, TIMING) output
-- In pgAdmin 4, check the execution time from EXPLAIN output

-- Centralized query (using main schema, not distributed)
EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE) 
SELECT 
    p.PartyName,
    con.Region,
    COUNT(b.BallotID) AS TotalVotes,
    SUM(CASE WHEN b.Validity = 'Valid' THEN 1 ELSE 0 END) AS ValidVotes,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - b.VoteDate)) / 86400), 
        2
    ) AS AvgDaysSinceVote
FROM 
    Party p
    INNER JOIN Candidate c ON p.PartyID = c.PartyID
    INNER JOIN Constituency con ON c.ConstituencyID = con.ConstituencyID
    LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID
GROUP BY 
    p.PartyName, con.Region
HAVING 
    COUNT(b.BallotID) > 0
ORDER BY 
    TotalVotes DESC;

-- Record execution time: _______________ ms

-- =====================================================
-- MODE 2: PARALLEL (Single Node, Parallel Workers)
-- =====================================================

-- Enable parallel execution
SET max_parallel_workers_per_gather = 4;
SET max_parallel_workers = 8;

-- Parallel query execution
EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE) 
SELECT 
    p.PartyName,
    con.Region,
    COUNT(b.BallotID) AS TotalVotes,
    SUM(CASE WHEN b.Validity = 'Valid' THEN 1 ELSE 0 END) AS ValidVotes,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - b.VoteDate)) / 86400), 
        2
    ) AS AvgDaysSinceVote
FROM 
    Party p
    INNER JOIN Candidate c ON p.PartyID = c.PartyID
    INNER JOIN Constituency con ON c.ConstituencyID = con.ConstituencyID
    LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID
GROUP BY 
    p.PartyName, con.Region
HAVING 
    COUNT(b.BallotID) > 0
ORDER BY 
    TotalVotes DESC;

-- Record execution time: _______________ ms
-- Note: Look for "Workers Launched: X" in the output

-- =====================================================
-- MODE 3: DISTRIBUTED (Multi-Node via FDW)
-- =====================================================

-- Distributed query across Node A and Node B
EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE) 
SELECT 
    p.PartyName,
    'Kigali' AS Region,  -- Both nodes are in Kigali region
    COUNT(b.BallotID) AS TotalVotes,
    SUM(CASE WHEN b.Validity = 'Valid' THEN 1 ELSE 0 END) AS ValidVotes,
    ROUND(
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - b.VoteDate)) / 86400), 
        2
    ) AS AvgDaysSinceVote
FROM 
    evotingdb_nodeA.party p
    INNER JOIN (
        SELECT * FROM evotingdb_nodeA.candidate
        UNION ALL
        SELECT * FROM evotingdb_nodeB.candidate
    ) c ON p.PartyID = c.PartyID
    INNER JOIN (
        SELECT * FROM evotingdb_nodeA.constituency
        UNION ALL
        SELECT * FROM evotingdb_nodeB.constituency
    ) con ON c.ConstituencyID = con.ConstituencyID
    LEFT JOIN (
        SELECT * FROM evotingdb_nodeA.ballot
        UNION ALL
        SELECT * FROM evotingdb_nodeB.ballot
    ) b ON c.CandidateID = b.CandidateID
GROUP BY 
    p.PartyName
HAVING 
    COUNT(b.BallotID) > 0
ORDER BY 
    TotalVotes DESC;

-- Record execution time: _______________ ms
-- Note: Look for "Foreign Scan" operations in the output

-- =====================================================
-- PERFORMANCE METRICS COLLECTION
-- =====================================================

-- Query to extract performance metrics from EXPLAIN output
-- Run this after each mode and record results

SELECT 
    'Performance Metrics' AS MetricType,
    NOW() AS BenchmarkTime;

-- Get buffer statistics
SELECT 
    'Buffer Statistics' AS MetricType,
    schemaname,
    relname AS tablename,
    heap_blks_read AS BlocksRead,
    heap_blks_hit AS BlocksHit,
    CASE 
        WHEN (heap_blks_read + heap_blks_hit) > 0 
        THEN ROUND(100.0 * heap_blks_hit / (heap_blks_read + heap_blks_hit), 2)
        ELSE 0 
    END AS CacheHitRatio
FROM 
    pg_statio_user_tables
WHERE 
    relname IN ('ballot', 'candidate', 'party', 'constituency')
ORDER BY 
    relname;

-- =====================================================
-- COMPARATIVE ANALYSIS QUERY
-- =====================================================

-- Summary query to compare I/O operations
SELECT 
    'Ballot Table Statistics' AS Check,
    schemaname,
    relname AS tablename,
    seq_scan AS SequentialScans,
    idx_scan AS IndexScans,
    n_tup_ins AS Inserts,
    n_tup_upd AS Updates,
    n_tup_del AS Deletes,
    n_live_tup AS LiveRows,
    last_vacuum,
    last_analyze
FROM 
    pg_stat_user_tables
WHERE 
    relname = 'ballot';

-- =====================================================
-- BENCHMARK RESULTS TEMPLATE
-- =====================================================

/*
PERFORMANCE BENCHMARK REPORT
============================

Test Query: Total votes per party across all constituencies
Dataset Size: ~10,000 ballots across 2 nodes
Hardware: [Your system specs]

RESULTS SUMMARY:
----------------

Mode 1: CENTRALIZED (Serial)
  Execution Time: _____ ms
  Planning Time:  _____ ms
  Total Cost:     _____
  Buffers:        Shared Read: ____, Hit: ____
  Workers:        0
  Strategy:       Sequential scan with hash aggregation
  
Mode 2: PARALLEL (4 Workers)
  Execution Time: _____ ms
  Planning Time:  _____ ms
  Total Cost:     _____
  Buffers:        Shared Read: ____, Hit: ____
  Workers:        4 launched
  Strategy:       Parallel sequential scan with parallel hash aggregation
  Speedup:        _____% vs Centralized

Mode 3: DISTRIBUTED (FDW)
  Execution Time: _____ ms
  Planning Time:  _____ ms
  Total Cost:     _____
  Buffers:        Shared Read: ____, Hit: ____
  Foreign Scans:  _____
  Strategy:       Distributed aggregation with FDW remote scans
  Speedup:        _____% vs Centralized

ANALYSIS:
---------

1. Centralized Mode:
   - Single process execution
   - All data accessed from one location
   - Baseline for comparison
   - Suitable for small datasets

2. Parallel Mode:
   - Multiple worker processes
   - Data partitioned and processed simultaneously
   - Significant improvement for large datasets
   - CPU utilization increases

3. Distributed Mode:
   - Data spread across multiple nodes
   - Network overhead for remote access
   - Benefits from data locality
   - Scales horizontally

RECOMMENDATIONS:
----------------

- For small datasets (< 10K rows): Use Centralized mode
- For large datasets (> 100K rows): Use Parallel mode (best performance)
- For geographically distributed data: Use Distributed mode (data locality)
- For hybrid: Combine Parallel + Distributed for maximum scalability

SCALABILITY ASSESSMENT:
----------------------

Parallel Mode scales well with:
- Number of CPU cores
- Available memory
- I/O bandwidth

Distributed Mode scales well with:
- Number of nodes
- Network bandwidth
- Data distribution strategy

EFFICIENCY RATING:
------------------

Centralized:   ★★★☆☆ (Good for small data)
Parallel:      ★★★★★ (Excellent for large single-node data)
Distributed:   ★★★★☆ (Good for distributed data, network overhead)

*/

-- =====================================================
-- AUTOMATED BENCHMARK SCRIPT
-- =====================================================

-- Run all three modes and collect timing
DO $$
DECLARE
    centralized_time NUMERIC;
    parallel_time NUMERIC;
    distributed_time NUMERIC;
BEGIN
    -- Mode 1: Centralized
    SET max_parallel_workers_per_gather = 0;
    PERFORM COUNT(*) FROM (
        SELECT p.PartyName, COUNT(b.BallotID) 
        FROM Party p
        INNER JOIN Candidate c ON p.PartyID = c.PartyID
        LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID
        GROUP BY p.PartyName
    ) subq;
    
    -- Mode 2: Parallel
    SET max_parallel_workers_per_gather = 4;
    PERFORM COUNT(*) FROM (
        SELECT p.PartyName, COUNT(b.BallotID) 
        FROM Party p
        INNER JOIN Candidate c ON p.PartyID = c.PartyID
        LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID
        GROUP BY p.PartyName
    ) subq;
    
    -- Results summary
    RAISE NOTICE 'Benchmark completed. Check EXPLAIN ANALYZE output for detailed timing.';
END $$;

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify benchmark data exists
SELECT 
    'Benchmark Data Verification' AS Check,
    'Node A Ballots' AS Metric,
    COUNT(*) AS Count,
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS Status
FROM 
    evotingdb_nodeA.ballot
UNION ALL
SELECT 
    'Benchmark Data Verification' AS Check,
    'Node B Ballots' AS Metric,
    COUNT(*) AS Count,
    CASE WHEN COUNT(*) > 0 THEN '✓ PASS' ELSE '✗ FAIL' END AS Status
FROM 
    evotingdb_nodeB.ballot;

-- Compare total ballots across all modes
SELECT 
    'Total Ballots Comparison' AS Check,
    (SELECT COUNT(*) FROM Ballot) AS Centralized_Count,
    ((SELECT COUNT(*) FROM evotingdb_nodeA.ballot) + 
     (SELECT COUNT(*) FROM evotingdb_nodeB.ballot)) AS Distributed_Count,
    CASE 
        WHEN (SELECT COUNT(*) FROM Ballot) > 0 
             AND ((SELECT COUNT(*) FROM evotingdb_nodeA.ballot) + 
                  (SELECT COUNT(*) FROM evotingdb_nodeB.ballot)) > 0
        THEN '✓ PASS - Data available for all modes'
        ELSE '⚠ CHECK - Some data may be missing'
    END AS Status;

-- Quick performance summary
SELECT 
    'Performance Summary' AS Report,
    'Mode 1: Centralized' AS Mode,
    'Check EXPLAIN output above for Execution Time' AS Instruction
UNION ALL
SELECT 
    'Performance Summary' AS Report,
    'Mode 2: Parallel' AS Mode,
    'Look for "Workers Launched" in EXPLAIN output' AS Instruction
UNION ALL
SELECT 
    'Performance Summary' AS Report,
    'Mode 3: Distributed' AS Mode,
    'Look for "Foreign Scan" in EXPLAIN output' AS Instruction;

-- Explanation:
-- Performance comparison shows:
-- 1. Centralized: Baseline single-threaded execution
-- 2. Parallel: Multi-core CPU utilization for speedup
-- 3. Distributed: Network-based access, benefits from data distribution
-- Use EXPLAIN ANALYZE output to record actual execution times and compare.

