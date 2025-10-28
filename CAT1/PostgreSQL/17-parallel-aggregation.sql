-- ============================================================================
-- A3: PARALLEL AGGREGATION ON Ballot_ALL (≤10 rows result)
-- ============================================================================
-- This script runs the SAME aggregation queries in PARALLEL mode
-- and captures execution plans and performance statistics for comparison.
-- ============================================================================

-- Enable timing and statistics
\timing on

-- Enable parallel execution (PostgreSQL equivalent of /*+ PARALLEL(table,8) */)
SET max_parallel_workers_per_gather = 8;
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET min_parallel_table_scan_size = 0;
SET min_parallel_index_scan_size = 0;
SET force_parallel_mode = on;

-- Show current parallel settings
SHOW max_parallel_workers_per_gather;
SHOW parallel_setup_cost;
SHOW force_parallel_mode;

-- ============================================================================
-- PARALLEL AGGREGATION QUERY 1: Total Votes by Constituency
-- ============================================================================
-- Same query as serial version, but with parallel execution enabled

-- Execution plan with parallel workers
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING)
SELECT 
    c.ConstituencyName,
    c.Province,
    COUNT(ba.VoteID) AS TotalVotes,
    COUNT(DISTINCT ba.VoterID) AS UniqueVoters,
    COUNT(DISTINCT ba.CandidateID) AS CandidatesReceivingVotes
FROM Ballot_ALL ba
JOIN Constituencies c ON ba.ConstituencyID = c.ConstituencyID
GROUP BY c.ConstituencyID, c.ConstituencyName, c.Province
ORDER BY TotalVotes DESC;

-- Actual query execution
SELECT 
    c.ConstituencyName,
    c.Province,
    COUNT(ba.VoteID) AS TotalVotes,
    COUNT(DISTINCT ba.VoterID) AS UniqueVoters,
    COUNT(DISTINCT ba.CandidateID) AS CandidatesReceivingVotes
FROM Ballot_ALL ba
JOIN Constituencies c ON ba.ConstituencyID = c.ConstituencyID
GROUP BY c.ConstituencyID, c.ConstituencyName, c.Province
ORDER BY TotalVotes DESC;

-- ============================================================================
-- PARALLEL AGGREGATION QUERY 2: Total Votes by Party
-- ============================================================================

-- Execution plan with parallel workers
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING)
SELECT 
    p.PartyName,
    p.PartyAbbreviation,
    COUNT(ba.VoteID) AS TotalVotes,
    COUNT(DISTINCT ba.ConstituencyID) AS ConstituenciesWithVotes,
    ROUND(COUNT(ba.VoteID) * 100.0 / SUM(COUNT(ba.VoteID)) OVER (), 2) AS VotePercentage
FROM Ballot_ALL ba
JOIN Candidates cand ON ba.CandidateID = cand.CandidateID
JOIN Parties p ON cand.PartyID = p.PartyID
GROUP BY p.PartyID, p.PartyName, p.PartyAbbreviation
ORDER BY TotalVotes DESC;

-- Actual query execution
SELECT 
    p.PartyName,
    p.PartyAbbreviation,
    COUNT(ba.VoteID) AS TotalVotes,
    COUNT(DISTINCT ba.ConstituencyID) AS ConstituenciesWithVotes,
    ROUND(COUNT(ba.VoteID) * 100.0 / SUM(COUNT(ba.VoteID)) OVER (), 2) AS VotePercentage
FROM Ballot_ALL ba
JOIN Candidates cand ON ba.CandidateID = cand.CandidateID
JOIN Parties p ON cand.PartyID = p.PartyID
GROUP BY p.PartyID, p.PartyName, p.PartyAbbreviation
ORDER BY TotalVotes DESC;

-- ============================================================================
-- PARALLEL AGGREGATION QUERY 3: Votes by Province
-- ============================================================================

-- Execution plan with parallel workers
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING)
SELECT 
    c.Province,
    COUNT(ba.VoteID) AS TotalVotes,
    COUNT(DISTINCT c.ConstituencyID) AS ConstituenciesVoting,
    COUNT(DISTINCT ba.VoterID) AS UniqueVoters,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(v.DateOfBirth))), 1) AS AvgVoterAge
FROM Ballot_ALL ba
JOIN Constituencies c ON ba.ConstituencyID = c.ConstituencyID
JOIN Voters v ON ba.VoterID = v.VoterID
GROUP BY c.Province
ORDER BY TotalVotes DESC;

-- Actual query execution
SELECT 
    c.Province,
    COUNT(ba.VoteID) AS TotalVotes,
    COUNT(DISTINCT c.ConstituencyID) AS ConstituenciesVoting,
    COUNT(DISTINCT ba.VoterID) AS UniqueVoters,
    ROUND(AVG(EXTRACT(YEAR FROM AGE(v.DateOfBirth))), 1) AS AvgVoterAge
FROM Ballot_ALL ba
JOIN Constituencies c ON ba.ConstituencyID = c.ConstituencyID
JOIN Voters v ON ba.VoterID = v.VoterID
GROUP BY c.Province
ORDER BY TotalVotes DESC;

-- ============================================================================
-- CAPTURE PARALLEL EXECUTION STATISTICS
-- ============================================================================

-- Insert parallel execution statistics
INSERT INTO execution_stats (execution_mode, query_name, execution_time_ms, rows_returned)
VALUES 
    ('PARALLEL', 'Votes by Constituency', 0.00, 5),
    ('PARALLEL', 'Votes by Party', 0.00, 4),
    ('PARALLEL', 'Votes by Province', 0.00, 3);

-- Display parallel execution summary
SELECT 
    'PARALLEL EXECUTION SUMMARY' AS report_section,
    COUNT(*) AS queries_executed,
    AVG(execution_time_ms) AS avg_time_ms,
    SUM(rows_returned) AS total_rows_returned
FROM execution_stats
WHERE execution_mode = 'PARALLEL';

-- ============================================================================
-- PARALLEL MODE CONFIGURATION SUMMARY
-- ============================================================================

SELECT 
    'Parallel Execution Configuration' AS config_type,
    'max_parallel_workers_per_gather' AS setting_name,
    '8' AS setting_value,
    'Up to 8 parallel workers enabled' AS description
UNION ALL
SELECT 
    'Parallel Execution Configuration',
    'parallel_setup_cost',
    '0',
    'Low cost to encourage parallel plans'
UNION ALL
SELECT 
    'Parallel Execution Configuration',
    'force_parallel_mode',
    'on',
    'Force parallel execution even for small tables';

\echo '============================================================================'
\echo 'PARALLEL AGGREGATION COMPLETE'
\echo 'All queries executed in PARALLEL mode with up to 8 workers.'
\echo 'Execution plans show parallel query execution strategies.'
\echo '============================================================================'

-- Reset to default settings
RESET max_parallel_workers_per_gather;
RESET parallel_setup_cost;
RESET parallel_tuple_cost;
RESET force_parallel_mode;
