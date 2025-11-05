-- ============================================================================
-- A5: Lock Diagnostics - View Blocking/Waiting Sessions
-- ============================================================================
-- Run this script in a THIRD connection while Session 1 holds lock
-- and Session 2 is waiting
-- ============================================================================

\echo '============================================================================'
\echo 'LOCK DIAGNOSTICS REPORT'
\echo 'Timestamp: ' \echo `date`
\echo '============================================================================'

\echo ''
\echo '1. ACTIVE SESSIONS'
\echo '----------------------------------------------------------------------------'

SELECT 
    pid AS session_pid,
    usename AS username,
    application_name,
    client_addr,
    state,
    wait_event_type,
    wait_event,
    substring(query, 1, 60) AS current_query,
    query_start,
    now() - query_start AS duration
FROM pg_stat_activity
WHERE state != 'idle'
AND query NOT LIKE '%pg_stat_activity%'
ORDER BY query_start;

\echo ''
\echo '2. CURRENT LOCKS (V$LOCK equivalent)'
\echo '----------------------------------------------------------------------------'

SELECT * FROM lock_monitor
WHERE table_name = 'electionpayment'
ORDER BY granted DESC, query_start;

\echo ''
\echo '3. BLOCKING SESSIONS (DBA_BLOCKERS equivalent)'
\echo '----------------------------------------------------------------------------'

SELECT 
    blocker_pid,
    blocker_user,
    substring(blocker_query, 1, 50) AS blocker_query,
    blocker_duration,
    blocked_pid,
    blocked_user,
    substring(blocked_query, 1, 50) AS blocked_query,
    blocked_duration,
    locked_table,
    blocking_mode,
    blocked_mode
FROM dba_blockers;

\echo ''
\echo '4. WAITING SESSIONS (DBA_WAITERS equivalent)'
\echo '----------------------------------------------------------------------------'

SELECT 
    waiter_pid,
    waiter_user,
    waiter_state,
    wait_event_type,
    wait_event,
    wait_duration,
    substring(waiter_query, 1, 60) AS waiter_query,
    locked_table,
    requested_mode
FROM dba_waiters;

\echo ''
\echo '5. DETAILED LOCK INFORMATION'
\echo '----------------------------------------------------------------------------'

SELECT 
    l.locktype,
    l.relation::regclass AS table_name,
    l.mode,
    l.granted,
    l.pid AS session_pid,
    a.usename,
    a.state,
    a.wait_event,
    substring(a.query, 1, 50) AS query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE l.relation = 'electionpayment'::regclass
ORDER BY l.granted DESC, a.query_start;

\echo ''
\echo '6. COMPREHENSIVE LOCK STATUS'
\echo '----------------------------------------------------------------------------'

SELECT * FROM show_lock_status();

\echo ''
\echo '============================================================================'
\echo 'DIAGNOSIS SUMMARY'
\echo '============================================================================'
\echo 'Expected findings:'
\echo '  ✓ Session 1 (blocker) holds RowExclusiveLock on ElectionPayment'
\echo '  ✓ Session 2 (waiter) is waiting for the same row'
\echo '  ✓ Session 2 wait_event should show "transactionid" or "tuple"'
\echo '  ✓ Blocker query: UPDATE ElectionPayment ... WHERE PaymentID = 1'
\echo '  ✓ Waiter query: UPDATE ElectionPayment ... WHERE PaymentID = 1'
\echo '============================================================================'
