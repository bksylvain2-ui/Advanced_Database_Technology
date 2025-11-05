-- ============================================================================
-- A5: Distributed Lock Conflict - SESSION 1 (Node_A)
-- ============================================================================
-- This script simulates Session 1 that acquires a lock and holds it
-- Run this FIRST in a separate database connection
-- ============================================================================

\echo '============================================================================'
\echo 'SESSION 1: Acquiring Lock on ElectionPayment Row'
\echo '============================================================================'

-- Show current session info
SELECT 
    pg_backend_pid() AS session1_pid,
    current_user AS session1_user,
    now() AS session1_start_time;

\echo ''
\echo 'Step 1: Begin transaction and acquire lock'
\echo '----------------------------------------------------------------------------'

-- Begin transaction
BEGIN;

-- Record start time
SELECT now() AS lock_acquired_time;

-- Update a specific row in ElectionPayment (this acquires a row-level lock)
-- Using PaymentID = 1 (from our 2PC setup)
UPDATE ElectionPayment
SET Amount = Amount + 0.01,
    PaymentDate = now()
WHERE PaymentID = 1
RETURNING 
    PaymentID,
    DeliveryID,
    Amount,
    PaymentDate,
    'LOCKED BY SESSION 1' AS lock_status;

\echo ''
\echo '✓ Lock acquired on ElectionPayment row with PaymentID = 1'
\echo '✓ Transaction is OPEN - lock is held'
\echo ''
\echo 'Current lock information:'
\echo '----------------------------------------------------------------------------'

-- Show current locks held by this session
SELECT 
    locktype,
    relation::regclass AS table_name,
    mode,
    granted,
    pg_backend_pid() AS holder_pid
FROM pg_locks
WHERE pid = pg_backend_pid()
AND relation = 'ElectionPayment'::regclass;

\echo ''
\echo '============================================================================'
\echo 'SESSION 1 STATUS: Transaction OPEN, Lock HELD'
\echo '============================================================================'
\echo 'Next steps:'
\echo '  1. Now run script 23 (Session 2) in a DIFFERENT terminal/connection'
\echo '  2. Session 2 will WAIT for this lock'
\echo '  3. Run script 24 to view lock diagnostics'
\echo '  4. Then run script 25 to release this lock'
\echo '============================================================================'
\echo ''
\echo 'IMPORTANT: Keep this session open! Do NOT commit or rollback yet.'
\echo ''

-- Keep transaction open - DO NOT COMMIT YET
-- User must manually keep this session alive
