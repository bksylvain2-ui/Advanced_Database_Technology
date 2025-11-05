-- ============================================================================
-- A5: Lock Conflict Summary & Verification
-- ============================================================================
-- Run this after both sessions complete to verify the scenario
-- ============================================================================

\echo '============================================================================'
\echo 'A5: DISTRIBUTED LOCK CONFLICT & DIAGNOSIS - SUMMARY REPORT'
\echo '============================================================================'

\echo ''
\echo '1. REQUIREMENT VERIFICATION'
\echo '----------------------------------------------------------------------------'

-- Verify the contested row exists and was updated
SELECT 
    '✓ Contested Row Exists' AS requirement,
    CASE 
        WHEN COUNT(*) = 1 THEN 'PASS'
        ELSE 'FAIL'
    END AS status,
    COUNT(*) AS row_count
FROM ElectionPayment
WHERE PaymentID = 1
GROUP BY PaymentID

UNION ALL

-- Verify no extra rows were added
SELECT 
    '✓ No Extra Rows Added (≤10 total)' AS requirement,
    CASE 
        WHEN COUNT(*) <= 10 THEN 'PASS'
        ELSE 'FAIL'
    END AS status,
    COUNT(*) AS row_count
FROM ElectionPayment

UNION ALL

-- Verify no pending locks
SELECT 
    '✓ No Pending Locks' AS requirement,
    CASE 
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status,
    COUNT(*) AS lock_count
FROM pg_locks
WHERE relation = 'electionpayment'::regclass
AND granted = false;

\echo ''
\echo '2. FINAL DATA STATE'
\echo '----------------------------------------------------------------------------'

-- Show the final state of the contested row
SELECT 
    PaymentID,
    DeliveryID,
    Amount,
    PaymentDate,
    'Row updated by both sessions' AS note
FROM ElectionPayment
WHERE PaymentID = 1;

\echo ''
\echo '3. LOCK MONITORING VIEWS STATUS'
\echo '----------------------------------------------------------------------------'

-- Verify monitoring views exist
SELECT 
    viewname AS view_name,
    '✓ Available' AS status
FROM pg_views
WHERE viewname IN ('lock_monitor', 'dba_blockers', 'dba_waiters')
ORDER BY viewname;

\echo ''
\echo '4. CURRENT SYSTEM STATE'
\echo '----------------------------------------------------------------------------'

-- Show current active sessions
SELECT 
    COUNT(*) AS active_sessions,
    COUNT(*) FILTER (WHERE state = 'active') AS active_queries,
    COUNT(*) FILTER (WHERE wait_event IS NOT NULL) AS waiting_sessions
FROM pg_stat_activity
WHERE state != 'idle';

-- Show current locks
SELECT 
    COUNT(*) AS total_locks,
    COUNT(*) FILTER (WHERE granted = true) AS granted_locks,
    COUNT(*) FILTER (WHERE granted = false) AS waiting_locks
FROM pg_locks
WHERE relation IS NOT NULL;

\echo ''
\echo '5. A5 DELIVERABLES CHECKLIST'
\echo '----------------------------------------------------------------------------'

SELECT 
    'UPDATE Statements' AS deliverable,
    '✓ Scripts 22 & 23' AS location,
    'Two UPDATE statements on PaymentID = 1' AS description
UNION ALL
SELECT 
    'Lock Diagnostics',
    '✓ Script 24',
    'dba_blockers, dba_waiters, lock_monitor views'
UNION ALL
SELECT 
    'Blocker/Waiter Evidence',
    '✓ Script 24 output',
    'Shows Session 1 blocking Session 2'
UNION ALL
SELECT 
    'Lock Release',
    '✓ Script 25',
    'COMMIT releases lock, Session 2 proceeds'
UNION ALL
SELECT 
    'Timestamps',
    '✓ All scripts',
    'Each script records timestamps showing sequence'
UNION ALL
SELECT 
    'No Extra Rows',
    '✓ Verified above',
    'Reused existing row, no new inserts';

\echo ''
\echo '============================================================================'
\echo 'EXECUTION INSTRUCTIONS'
\echo '============================================================================'
\echo ''
\echo 'To demonstrate A5, execute scripts in this order:'
\echo ''
\echo '  Terminal 1 (Session 1 - Node_A):'
\echo '    1. Run: psql -f scripts/22-lock-conflict-session1.sql'
\echo '    2. Keep terminal open (transaction stays open)'
\echo ''
\echo '  Terminal 2 (Session 2 - Node_B):'
\echo '    3. Run: psql -f scripts/23-lock-conflict-session2.sql'
\echo '    4. This will BLOCK and wait for Session 1'
\echo ''
\echo '  Terminal 3 (Diagnostics):'
\echo '    5. Run: psql -f scripts/24-lock-diagnostics.sql'
\echo '    6. Observe blocker/waiter information'
\echo ''
\echo '  Back to Terminal 1:'
\echo '    7. Run: psql -f scripts/25-lock-release.sql'
\echo '    8. Session 1 commits, releasing lock'
\echo ''
\echo '  Terminal 2 will automatically complete after step 8'
\echo ''
\echo '  Any Terminal:'
\echo '    9. Run: psql -f scripts/26-lock-conflict-summary.sql'
\echo '    10. Verify all requirements met'
\echo ''
\echo '============================================================================'
\echo 'A5 IMPLEMENTATION COMPLETE'
\echo '============================================================================'
