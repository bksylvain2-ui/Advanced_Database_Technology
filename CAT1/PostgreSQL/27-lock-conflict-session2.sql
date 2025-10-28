-- ============================================================================
-- A5: Distributed Lock Conflict - SESSION 2 (Node_B via proj_link)
-- ============================================================================
-- This script simulates Session 2 trying to update the same row
-- Run this SECOND in a separate database connection (after Session 1)
-- This will BLOCK until Session 1 releases the lock
-- ============================================================================

\echo '============================================================================'
\echo 'SESSION 2: Attempting to Update Same Row (will WAIT)'
\echo '============================================================================'

-- Show current session info
SELECT 
    pg_backend_pid() AS session2_pid,
    current_user AS session2_user,
    now() AS session2_start_time;

\echo ''
\echo 'Step 1: Record attempt start time'
\echo '----------------------------------------------------------------------------'

SELECT now() AS attempt_start_time;

\echo ''
\echo 'Step 2: Attempting to update the SAME row (PaymentID = 1)'
\echo '----------------------------------------------------------------------------'
\echo 'NOTE: This will BLOCK and WAIT for Session 1 to release the lock'
\echo ''

-- Begin transaction
BEGIN;

-- This UPDATE will BLOCK because Session 1 holds the lock
-- Simulating remote update via database link by updating the same table
UPDATE ElectionPayment
SET Amount = Amount + 0.02,
    PaymentDate = now()
WHERE PaymentID = 1
RETURNING 
    PaymentID,
    DeliveryID,
    Amount,
    PaymentDate,
    'UPDATED BY SESSION 2 (after wait)' AS update_status;

-- Record completion time (will only execute after Session 1 releases lock)
SELECT now() AS update_completed_time;

\echo ''
\echo '✓ Update completed! Session 1 must have released the lock.'
\echo ''

-- Commit the transaction
COMMIT;

\echo ''
\echo '============================================================================'
\echo 'SESSION 2 STATUS: Update COMPLETED, Transaction COMMITTED'
\echo '============================================================================'
\echo 'The update succeeded after waiting for Session 1 to release the lock.'
\echo '============================================================================'
