-- =====================================================
-- TASK 15: Parallel Data Loading / ETL Simulation
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: 
-- 1. Run task1_create_schema.sql
-- 2. Run task3_insert_mock_data.sql

-- Simulate parallel data loading using INSERT with parallel settings

-- =====================================================
-- STEP 1: Prepare for Parallel Loading
-- =====================================================

-- Enable parallel operations
SET max_parallel_workers_per_gather = 4;
SET max_parallel_workers = 8;
SET parallel_setup_cost = 10;

-- Create temporary staging table for ETL
CREATE TEMP TABLE IF NOT EXISTS ballot_staging (
    VoterID INTEGER,
    CandidateID INTEGER,
    VoteDate TIMESTAMP,
    Validity VARCHAR(20)
);

-- =====================================================
-- STEP 2: Generate Sample Data for Loading
-- =====================================================

-- Insert sample data into staging table (simulating data extraction)
INSERT INTO ballot_staging (VoterID, CandidateID, VoteDate, Validity)
SELECT 
    (RANDOM() * 5 + 1)::INTEGER AS VoterID,
    (RANDOM() * 5 + 1)::INTEGER AS CandidateID,
    CURRENT_TIMESTAMP - (RANDOM() * 365 || ' days')::INTERVAL AS VoteDate,
    CASE WHEN RANDOM() > 0.1 THEN 'Valid' ELSE 'Invalid' END AS Validity
FROM 
    generate_series(1, 5000);  -- Generate 5000 rows

-- =====================================================
-- STEP 3: Serial Data Loading (Baseline Performance)
-- =====================================================

-- Disable parallel execution
SET max_parallel_workers_per_gather = 0;

-- Measure time for serial insert
\timing on

-- Serial INSERT
EXPLAIN (ANALYZE, BUFFERS, TIMING) 
INSERT INTO Ballot (VoterID, CandidateID, VoteDate, Validity)
SELECT 
    VoterID,
    CandidateID,
    VoteDate,
    Validity
FROM 
    ballot_staging
ON CONFLICT DO NOTHING;

-- Note execution time

-- =====================================================
-- STEP 4: Parallel Data Loading
-- =====================================================

-- Enable parallel execution
SET max_parallel_workers_per_gather = 4;

-- Clear previous inserts for fair comparison
DELETE FROM Ballot WHERE VoteDate > CURRENT_TIMESTAMP - INTERVAL '1 day';

-- Parallel INSERT with EXPLAIN
EXPLAIN (ANALYZE, BUFFERS, TIMING, VERBOSE) 
INSERT INTO Ballot (VoterID, CandidateID, VoteDate, Validity)
SELECT 
    VoterID,
    CandidateID,
    VoteDate,
    Validity
FROM 
    ballot_staging
ON CONFLICT DO NOTHING;

-- Look for "Workers Launched" in output to confirm parallelism

-- =====================================================
-- STEP 5: Parallel Data Aggregation (ETL Transformation)
-- =====================================================

-- Create aggregated results table
CREATE TABLE IF NOT EXISTS CandidateVoteSummary AS
SELECT 
    c.CandidateID,
    c.FullName,
    COUNT(b.BallotID) AS TotalVotes,
    SUM(CASE WHEN b.Validity = 'Valid' THEN 1 ELSE 0 END) AS ValidVotes
FROM 
    Candidate c
    LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID
GROUP BY 
    c.CandidateID, c.FullName;

-- Truncate for fresh run
TRUNCATE TABLE CandidateVoteSummary;

-- Parallel aggregation with EXPLAIN
EXPLAIN (ANALYZE, BUFFERS, TIMING) 
INSERT INTO CandidateVoteSummary
SELECT 
    c.CandidateID,
    c.FullName,
    COUNT(b.BallotID) AS TotalVotes,
    SUM(CASE WHEN b.Validity = 'Valid' THEN 1 ELSE 0 END) AS ValidVotes
FROM 
    Candidate c
    LEFT JOIN Ballot b ON c.CandidateID = b.CandidateID
GROUP BY 
    c.CandidateID, c.FullName;

-- =====================================================
-- STEP 6: Parallel Bulk Load from CSV (Simulation)
-- =====================================================

-- Create CSV-like data in staging
CREATE TEMP TABLE IF NOT EXISTS csv_staging (
    voter_name VARCHAR(100),
    national_id VARCHAR(20),
    candidate_name VARCHAR(100),
    vote_date TIMESTAMP
);

-- Simulate CSV import data
INSERT INTO csv_staging 
SELECT 
    'Voter ' || i || ' Name' AS voter_name,
    '11988' || LPAD(i::TEXT, 9, '0') AS national_id,
    'Candidate ' || ((i % 6) + 1) || ' Name' AS candidate_name,
    CURRENT_TIMESTAMP - (RANDOM() * 365 || ' days')::INTERVAL AS vote_date
FROM 
    generate_series(1, 2000) i;

-- Parallel ETL: Transform and load
EXPLAIN (ANALYZE, BUFFERS, TIMING) 
INSERT INTO Ballot (VoterID, CandidateID, VoteDate, Validity)
SELECT 
    v.VoterID,
    c.CandidateID,
    csv.vote_date,
    'Valid' AS Validity
FROM 
    csv_staging csv
    INNER JOIN Voter v ON v.NationalID = csv.national_id
    INNER JOIN Candidate c ON c.FullName LIKE '%' || SPLIT_PART(csv.candidate_name, ' ', 2) || '%'
ON CONFLICT DO NOTHING;

-- =====================================================
-- STEP 7: Performance Comparison Query
-- =====================================================

-- Query to compare serial vs parallel execution times
SELECT 
    'Serial Load' AS LoadType,
    COUNT(*) AS RowsLoaded,
    NOW() AS Timestamp
FROM 
    Ballot
WHERE 
    VoteDate > CURRENT_TIMESTAMP - INTERVAL '1 hour';

-- =====================================================
-- STEP 8: Parallel Update (ETL Scenario)
-- =====================================================

-- Enable parallel updates
SET max_parallel_workers_per_gather = 4;

-- Parallel UPDATE with aggregation
EXPLAIN (ANALYZE, BUFFERS, TIMING) 
UPDATE Candidate c
SET Manifesto = Manifesto || ' - Last Updated: ' || CURRENT_TIMESTAMP::TEXT
WHERE 
    EXISTS (
        SELECT 1 
        FROM Ballot b 
        WHERE b.CandidateID = c.CandidateID 
            AND b.Validity = 'Valid'
    );

-- =====================================================
-- STEP 9: Measure ETL Performance Metrics
-- =====================================================

-- Query execution statistics
SELECT 
    schemaname,
    tablename,
    n_tup_ins AS TotalInserts,
    n_tup_upd AS TotalUpdates,
    n_live_tup AS LiveRows,
    n_dead_tup AS DeadRows,
    last_vacuum,
    last_autovacuum
FROM 
    pg_stat_user_tables
WHERE 
    tablename IN ('ballot', 'candidatevotesummary')
ORDER BY 
    tablename;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Verify loaded data
SELECT 
    'Total Ballots Loaded' AS Metric,
    COUNT(*) AS Value
FROM 
    Ballot;

SELECT 
    'Valid Votes' AS Metric,
    COUNT(*) AS Value
FROM 
    Ballot
WHERE 
    Validity = 'Valid';

-- Explanation:
-- Parallel data loading improves ETL performance:
-- 1. PostgreSQL uses multiple worker processes
-- 2. Data is partitioned and processed in parallel
-- 3. Monitor with EXPLAIN ANALYZE to see worker usage
-- 4. Settings like max_parallel_workers control parallelism
-- 5. Effective for large bulk inserts and aggregations

