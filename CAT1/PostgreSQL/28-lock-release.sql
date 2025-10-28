-- ============================================================================
-- A5: Lock Release - Complete Session 1 Transaction
-- ============================================================================
-- Run this script in the SESSION 1 connection to release the lock
-- ============================================================================

\echo '============================================================================'
\echo 'SESSION 1: Releasing Lock'
\echo '============================================================================'

\echo ''
\echo 'Step 1: Record release time'
\echo '----------------------------------------------------------------------------'

SELECT 
    pg_backend_pid() AS session1_pid,
    now() AS lock_release_time;

\echo ''
\echo 'Step 2: Commit transaction (releases lock)'
\echo '----------------------------------------------------------------------------'

-- Commit the transaction - this releases the lock
COMMIT;

SELECT 'Transaction COMMITTED - Lock RELEASED' AS status;

\echo ''
\echo '✓ Lock released successfully'
\echo '✓ Session 2 should now complete its UPDATE'
\echo ''

\echo ''
\echo 'Step 3: Verify no locks remain'
\echo '----------------------------------------------------------------------------'

-- Verify no locks held by this session
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ No locks held by Session 1'
        ELSE '⚠ Session 1 still holds locks'
    END AS lock_status
FROM pg_locks
WHERE pid = pg_backend_pid()
AND relation = 'electionpayment'::regclass;

\echo ''
\echo 'Step 4: Check for any remaining blockers'
\echo '----------------------------------------------------------------------------'

SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ No blocking sessions detected'
        ELSE '⚠ Blocking sessions still exist'
    END AS blocker_status
FROM dba_blockers;

\echo ''
\echo 'Step 5: Verify final data state'
\echo '----------------------------------------------------------------------------'

-- Show the final state of the contested row
SELECT 
    PaymentID,
    DeliveryID,
    Amount,
    PaymentDate,
    'Final state after both updates' AS note
FROM ElectionPayment
WHERE PaymentID = 1;

\echo ''
\echo '============================================================================'
\echo 'SESSION 1 STATUS: Transaction COMMITTED, Lock RELEASED'
\echo '============================================================================'
\echo 'Session 2 should now complete successfully.'
\echo 'Check Session 2 terminal to confirm UPDATE completed.'
\echo '============================================================================'
