-- ============================================================================
-- A5: Distributed Lock Conflict & Diagnosis - Setup
-- ============================================================================
-- PostgreSQL equivalent of Oracle's DBA_BLOCKERS/DBA_WAITERS/V$LOCK
-- Creates views and functions to monitor distributed locks
-- ============================================================================

-- Enable detailed lock monitoring
ALTER SYSTEM SET log_lock_waits = on;
ALTER SYSTEM SET deadlock_timeout = '1s';
SELECT pg_reload_conf();

-- ============================================================================
-- Create Lock Monitoring Views (PostgreSQL equivalent of Oracle lock views)
-- ============================================================================

-- View 1: Current Locks (equivalent to V$LOCK)
CREATE OR REPLACE VIEW lock_monitor AS
SELECT 
    l.locktype,
    l.database,
    l.relation::regclass AS table_name,
    l.page,
    l.tuple,
    l.virtualxid,
    l.transactionid,
    l.mode,
    l.granted,
    l.pid AS session_id,
    a.usename AS username,
    a.application_name,
    a.client_addr,
    a.state,
    a.query,
    a.query_start,
    now() - a.query_start AS query_duration,
    a.wait_event_type,
    a.wait_event
FROM pg_locks l
LEFT JOIN pg_stat_activity a ON l.pid = a.pid
WHERE a.pid IS NOT NULL
ORDER BY l.granted, a.query_start;

-- View 2: Blocking Sessions (equivalent to DBA_BLOCKERS)
CREATE OR REPLACE VIEW dba_blockers AS
SELECT 
    blocking.pid AS blocker_pid,
    blocking.usename AS blocker_user,
    blocking.application_name AS blocker_app,
    blocking.client_addr AS blocker_addr,
    blocking.query AS blocker_query,
    blocking.query_start AS blocker_start,
    now() - blocking.query_start AS blocker_duration,
    blocked.pid AS blocked_pid,
    blocked.usename AS blocked_user,
    blocked.query AS blocked_query,
    blocked.query_start AS blocked_start,
    now() - blocked.query_start AS blocked_duration,
    blocked_locks.mode AS blocked_mode,
    blocking_locks.mode AS blocking_mode,
    blocked_locks.relation::regclass AS locked_table
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked ON blocked_locks.pid = blocked.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking ON blocking_locks.pid = blocking.pid
WHERE NOT blocked_locks.granted
AND blocking_locks.granted;

-- View 3: Waiting Sessions (equivalent to DBA_WAITERS)
CREATE OR REPLACE VIEW dba_waiters AS
SELECT 
    a.pid AS waiter_pid,
    a.usename AS waiter_user,
    a.application_name AS waiter_app,
    a.client_addr AS waiter_addr,
    a.state AS waiter_state,
    a.wait_event_type,
    a.wait_event,
    a.query AS waiter_query,
    a.query_start AS wait_start,
    now() - a.query_start AS wait_duration,
    l.locktype,
    l.mode AS requested_mode,
    l.granted,
    l.relation::regclass AS locked_table
FROM pg_stat_activity a
JOIN pg_locks l ON a.pid = l.pid
WHERE NOT l.granted
AND a.state = 'active'
ORDER BY a.query_start;

-- ============================================================================
-- Helper Function: Show All Lock Information
-- ============================================================================
CREATE OR REPLACE FUNCTION show_lock_status()
RETURNS TABLE (
    report_section TEXT,
    details TEXT
) AS $$
BEGIN
    -- Section 1: Active Locks
    RETURN QUERY
    SELECT 
        'ACTIVE_LOCKS'::TEXT,
        format('PID: %s | User: %s | Table: %s | Mode: %s | Granted: %s | Query: %s',
            session_id, username, table_name, mode, granted, 
            substring(query, 1, 50)) AS details
    FROM lock_monitor
    WHERE locktype = 'relation' OR locktype = 'tuple';
    
    -- Section 2: Blockers
    RETURN QUERY
    SELECT 
        'BLOCKERS'::TEXT,
        format('Blocker PID: %s blocking Waiter PID: %s | Table: %s | Blocker Query: %s',
            blocker_pid, blocked_pid, locked_table, 
            substring(blocker_query, 1, 50)) AS details
    FROM dba_blockers;
    
    -- Section 3: Waiters
    RETURN QUERY
    SELECT 
        'WAITERS'::TEXT,
        format('Waiter PID: %s | Waiting for: %s | Duration: %s | Query: %s',
            waiter_pid, wait_event, wait_duration, 
            substring(waiter_query, 1, 50)) AS details
    FROM dba_waiters;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Verification
-- ============================================================================
SELECT 'Lock monitoring views created successfully' AS status;
SELECT 'Views available: lock_monitor, dba_blockers, dba_waiters' AS info;
SELECT 'Function available: show_lock_status()' AS info;
