-- =====================================================
-- TASK 14: Distributed Concurrency Control
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: 
-- 1. Run task1_create_schema.sql
-- 2. Run task3_insert_mock_data.sql
-- 3. Run task9_distributed_schema_fragmentation.sql

-- Demonstrate lock conflicts using pg_locks when multiple sessions access same data

-- =====================================================
-- STEP 1: Check Current Lock Configuration
-- =====================================================

-- View lock-related settings
SELECT 
    name,
    setting,
    short_desc
FROM 
    pg_settings
WHERE 
    name LIKE '%lock%' OR name LIKE '%deadlock%'
ORDER BY 
    name;

-- =====================================================
-- STEP 2: Session 1 - Begin Transaction and Lock Row
-- =====================================================

-- Run this in pgAdmin Query Tool Window 1
BEGIN;

-- Select and lock a candidate record (FOR UPDATE creates row-level lock)
SELECT 
    CandidateID,
    FullName,
    Manifesto
FROM 
    Candidate
WHERE 
    CandidateID = 1
FOR UPDATE;

-- Keep transaction open (don't commit yet)
-- This simulates a long-running transaction

-- =====================================================
-- STEP 3: View Active Locks (Run in Separate Window)
-- =====================================================

-- Query to see all locks on the Candidate table
SELECT 
    l.locktype,
    l.database,
    l.relation::regclass AS TableName,
    l.page,
    l.tuple,
    l.virtualxid,
    l.transactionid,
    l.mode,
    l.granted,
    a.usename AS UserName,
    a.query,
    a.state
FROM 
    pg_locks l
    LEFT JOIN pg_stat_activity a ON l.pid = a.pid
WHERE 
    l.relation::regclass::text = 'candidate'
ORDER BY 
    l.granted, l.mode;

-- =====================================================
-- STEP 4: Session 2 - Attempt Concurrent Update (Lock Conflict)
-- =====================================================

-- Run this in pgAdmin Query Tool Window 2 (while Session 1 is still active)
-- This will wait/block because Session 1 holds a lock

BEGIN;

-- This query will block waiting for Session 1's lock to release
UPDATE Candidate
SET Manifesto = 'Updated manifesto from Session 2'
WHERE CandidateID = 1;

-- If you see the query hanging, it's waiting for the lock
-- This demonstrates lock conflict

-- =====================================================
-- STEP 5: Monitor Lock Conflicts and Blocking
-- =====================================================

-- Query to find blocking locks and waiters
SELECT 
    blocked_locks.pid AS BlockedPID,
    blocking_locks.pid AS BlockingPID,
    blocked_activity.usename AS BlockedUser,
    blocking_activity.usename AS BlockingUser,
    blocked_activity.query AS BlockedQuery,
    blocking_activity.query AS BlockingQuery,
    blocked_locks.mode AS BlockedMode,
    blocking_locks.mode AS BlockingMode,
    blocked_activity.state AS BlockedState
FROM 
    pg_catalog.pg_locks blocked_locks
    JOIN pg_catalog.pg_stat_activity blocked_activity 
        ON blocked_activity.pid = blocked_locks.pid
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
    JOIN pg_catalog.pg_stat_activity blocking_activity 
        ON blocking_activity.pid = blocking_locks.pid
WHERE 
    NOT blocked_locks.granted;

-- =====================================================
-- STEP 6: Lock Timeout Configuration
-- =====================================================

-- Set lock timeout (milliseconds) to prevent indefinite waiting
SET lock_timeout = '5s';  -- Wait max 5 seconds for lock

-- If lock not acquired within timeout, query fails with error:
-- ERROR: canceling statement due to lock timeout

-- =====================================================
-- STEP 7: Distributed Lock Scenario (Cross-Node)
-- =====================================================

-- Session 1: Lock row in Node A
BEGIN;
SELECT * FROM evotingdb_nodeA.Candidate WHERE CandidateID = 1 FOR UPDATE;

-- Session 2: Lock row in Node B (no conflict - different node)
BEGIN;
SELECT * FROM evotingdb_nodeB.Candidate WHERE CandidateID = 4 FOR UPDATE;

-- Both can proceed as they lock different nodes

-- =====================================================
-- STEP 8: Deadlock Detection
-- =====================================================

-- PostgreSQL automatically detects deadlocks
-- Simulate deadlock scenario:

-- Session 1:
BEGIN;
UPDATE Candidate SET Manifesto = 'Session 1 Update' WHERE CandidateID = 1;
-- Then try to update CandidateID = 2 (but Session 2 has it locked)

-- Session 2 (run simultaneously):
BEGIN;
UPDATE Candidate SET Manifesto = 'Session 2 Update' WHERE CandidateID = 2;
-- Then try to update CandidateID = 1 (but Session 1 has it locked)

-- PostgreSQL will detect deadlock and abort one transaction:
-- ERROR: deadlock detected

-- =====================================================
-- STEP 9: Lock Information Summary
-- =====================================================

-- View all locks in the system
SELECT 
    l.locktype,
    l.relation::regclass AS TableName,
    l.mode,
    l.granted,
    COUNT(*) AS LockCount
FROM 
    pg_locks l
WHERE 
    l.locktype = 'relation'
GROUP BY 
    l.locktype, l.relation::regclass, l.mode, l.granted
ORDER BY 
    TableName, l.mode;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check for any blocking transactions
SELECT 
    COUNT(*) AS BlockedTransactions
FROM 
    pg_locks l1
    JOIN pg_locks l2 ON l1.transactionid = l2.transactionid
WHERE 
    NOT l1.granted
    AND l2.granted
    AND l1.pid != l2.pid;

-- Explanation:
-- PostgreSQL uses multi-version concurrency control (MVCC):
-- 1. Row-level locking prevents conflicts
-- 2. pg_locks shows all active locks
-- 3. Deadlock detection automatically resolves circular waits
-- 4. Lock timeouts prevent indefinite blocking
-- 5. Different lock modes: SHARE, EXCLUSIVE, UPDATE, etc.

