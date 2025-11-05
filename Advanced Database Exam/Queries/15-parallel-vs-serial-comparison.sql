-- ============================================================================
-- A3: PARALLEL VS SERIAL COMPARISON TABLE
-- ============================================================================
-- This script generates a comprehensive comparison between serial and parallel
-- execution modes, showing performance metrics and execution plan differences.
-- ============================================================================

\echo '============================================================================'
\echo 'A3: PARALLEL VS SERIAL AGGREGATION COMPARISON'
\echo '============================================================================'

-- ============================================================================
-- COMPARISON TABLE: Serial vs Parallel Execution
-- ============================================================================

SELECT 
    '═══════════════════════════════════════════════════════════════════════════' AS separator
UNION ALL
SELECT '                    SERIAL VS PARALLEL EXECUTION COMPARISON'
UNION ALL
SELECT '═══════════════════════════════════════════════════════════════════════════';

-- Main comparison table
WITH serial_stats AS (
    SELECT 
        query_name,
        AVG(execution_time_ms) AS avg_time_ms,
        MAX(rows_returned) AS rows_returned,
        AVG(COALESCE(buffers_shared_hit, 0)) AS avg_buffers_hit,
        AVG(COALESCE(buffers_shared_read, 0)) AS avg_buffers_read
    FROM execution_stats
    WHERE execution_mode = 'SERIAL'
    GROUP BY query_name
),
parallel_stats AS (
    SELECT 
        query_name,
        AVG(execution_time_ms) AS avg_time_ms,
        MAX(rows_returned) AS rows_returned,
        AVG(COALESCE(buffers_shared_hit, 0)) AS avg_buffers_hit,
        AVG(COALESCE(buffers_shared_read, 0)) AS avg_buffers_read
    FROM execution_stats
    WHERE execution_mode = 'PARALLEL'
    GROUP BY query_name
)
SELECT 
    s.query_name AS "Query Name",
    s.rows_returned AS "Rows",
    ROUND(s.avg_time_ms, 2) AS "Serial Time (ms)",
    ROUND(p.avg_time_ms, 2) AS "Parallel Time (ms)",
    ROUND(s.avg_buffers_hit, 0) AS "Serial Buffers",
    ROUND(p.avg_buffers_hit, 0) AS "Parallel Buffers",
    CASE 
        WHEN p.avg_time_ms < s.avg_time_ms THEN 'Parallel Faster'
        WHEN p.avg_time_ms > s.avg_time_ms THEN 'Serial Faster'
        ELSE 'Similar'
    END AS "Performance Winner"
FROM serial_stats s
JOIN parallel_stats p ON s.query_name = p.query_name
ORDER BY s.query_name;

-- ============================================================================
-- SUMMARY COMPARISON (2-ROW TABLE AS REQUIRED)
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'SUMMARY: 2-ROW COMPARISON TABLE (Serial vs Parallel)'
\echo '============================================================================'

SELECT 
    execution_mode AS "Execution Mode",
    COUNT(DISTINCT query_name) AS "Queries Run",
    ROUND(AVG(execution_time_ms), 3) AS "Avg Time (ms)",
    SUM(rows_returned) AS "Total Rows",
    ROUND(AVG(COALESCE(buffers_shared_hit, 0)), 0) AS "Avg Buffer Gets",
    CASE execution_mode
        WHEN 'SERIAL' THEN 'Sequential scan, no parallelism'
        WHEN 'PARALLEL' THEN 'Parallel workers (up to 8), gather merge'
    END AS "Plan Notes"
FROM execution_stats
GROUP BY execution_mode
ORDER BY execution_mode DESC;

-- ============================================================================
-- EXECUTION PLAN COMPARISON SUMMARY
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'EXECUTION PLAN CHARACTERISTICS'
\echo '============================================================================'

SELECT 
    'SERIAL EXECUTION' AS "Mode",
    'Sequential Scan' AS "Scan Type",
    'Single Process' AS "Workers",
    'Hash Aggregate' AS "Aggregation Method",
    'Standard Sort' AS "Sort Method",
    'No parallelism overhead' AS "Key Characteristic"
UNION ALL
SELECT 
    'PARALLEL EXECUTION',
    'Parallel Seq Scan',
    'Up to 8 Workers',
    'Partial Aggregate → Finalize Aggregate',
    'Gather Merge',
    'Parallel coordination overhead';

-- ============================================================================
-- PERFORMANCE INSIGHTS
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'PERFORMANCE INSIGHTS'
\echo '============================================================================'

SELECT 
    'Dataset Size' AS "Factor",
    '10 rows total (5 per fragment)' AS "Value",
    'Too small to benefit from parallelism' AS "Impact"
UNION ALL
SELECT 
    'Parallel Overhead',
    'Worker coordination cost',
    'May exceed actual computation time'
UNION ALL
SELECT 
    'Serial Advantage',
    'No coordination overhead',
    'Faster for small datasets'
UNION ALL
SELECT 
    'Parallel Advantage',
    'Would benefit large datasets (>100K rows)',
    'Scales with data volume'
UNION ALL
SELECT 
    'Recommendation',
    'Use parallel for large tables only',
    'Serial is optimal for ≤10 rows';

-- ============================================================================
-- DETAILED METRICS BY QUERY
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'DETAILED METRICS BY QUERY'
\echo '============================================================================'

SELECT 
    query_name AS "Query",
    execution_mode AS "Mode",
    execution_time_ms AS "Time (ms)",
    rows_returned AS "Rows",
    run_timestamp AS "Executed At"
FROM execution_stats
ORDER BY query_name, execution_mode DESC;

-- ============================================================================
-- CONFIGURATION COMPARISON
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'CONFIGURATION SETTINGS COMPARISON'
\echo '============================================================================'

SELECT 
    'max_parallel_workers_per_gather' AS "Setting",
    '0' AS "Serial Value",
    '8' AS "Parallel Value",
    'Controls number of parallel workers' AS "Purpose"
UNION ALL
SELECT 
    'parallel_setup_cost',
    '1000000',
    '0',
    'Cost of starting parallel workers'
UNION ALL
SELECT 
    'parallel_tuple_cost',
    '1000000',
    '0',
    'Cost per tuple in parallel mode'
UNION ALL
SELECT 
    'force_parallel_mode',
    'off',
    'on',
    'Force parallel even for small tables';

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'CONCLUSION'
\echo '============================================================================'
\echo 'For this small dataset (≤10 rows), serial execution is expected to be'
\echo 'faster or similar to parallel execution due to parallel coordination overhead.'
\echo 'Parallel execution would show significant benefits with larger datasets'
\echo '(typically >100,000 rows) where the computation cost exceeds coordination cost.'
\echo '============================================================================'
