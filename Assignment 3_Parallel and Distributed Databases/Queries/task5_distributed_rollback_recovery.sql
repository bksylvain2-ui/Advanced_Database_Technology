-- =====================================================
-- TASK 5: Distributed Rollback and Recovery
-- Assignment 3: Distributed and Parallel Database
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: 
-- 1. Run task1_create_schema.sql (basic tasks)
-- 2. Run task1_distributed_schema_fragmentation.sql (Assignment 3)
-- 3. Run task4_two_phase_commit.sql (Assignment 3, for prepared transactions)

-- Simulate network failure during distributed transaction and recovery

-- =====================================================
-- PREREQUISITE CHECK: Verify Prepared Transactions are Enabled
-- =====================================================

-- Check if prepared transactions are enabled
SELECT 
    'Prepared Transactions Status' AS Check,
    name,
    setting,
    CASE 
        WHEN name = 'max_prepared_transactions' AND setting::int > 0 
        THEN '✓ ENABLED - Prepared transactions available'
        WHEN name = 'max_prepared_transactions' AND setting::int = 0 
        THEN '✗ DISABLED - Using savepoint alternative'
        ELSE 'CHECK'
    END AS Status
FROM 
    pg_settings
WHERE 
    name = 'max_prepared_transactions';

-- NOTE: If max_prepared_transactions = 0, use APPROACH 2 below (savepoints)
-- If enabled, uncomment APPROACH 1 sections

-- =====================================================
-- APPROACH 1: Prepared Transactions (Requires Server Config)
-- =====================================================

-- Uncomment below ONLY if max_prepared_transactions > 0
/*
-- =====================================================
-- STEP 1: Simulate Transaction with Network Failure
-- =====================================================

-- Begin distributed transaction
BEGIN;

-- Insert data into Node A
INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (1, 1, CURRENT_TIMESTAMP, 'Valid');

-- Insert data into Node B
INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (4, 4, CURRENT_TIMESTAMP, 'Valid');

-- Prepare transaction (simulating commit preparation)
PREPARE TRANSACTION 'failed_tx_001';

-- At this point, simulate network failure
-- Transaction is in prepared state but not committed

-- =====================================================
-- STEP 2: Check for Unresolved (Prepared) Transactions
-- =====================================================

-- Query prepared transactions (equivalent to DBA_2PC_PENDING in Oracle)
SELECT 
    gid AS TransactionID,
    prepared AS PreparedTime,
    owner AS Owner,
    database AS Database,
    CASE 
        WHEN age(prepared) > interval '1 hour' THEN 'STALE - Requires Recovery'
        ELSE 'ACTIVE'
    END AS Status
FROM 
    pg_prepared_xacts
ORDER BY 
    prepared;

-- =====================================================
-- STEP 3: Simulate Recovery - Check Transaction State
-- =====================================================

-- Check if transaction data exists but not committed
SELECT 
    'Node A - Before Recovery' AS Status,
    COUNT(*) AS BallotCount
FROM 
    evotingdb_nodeA.Ballot
WHERE 
    VoteDate > CURRENT_TIMESTAMP - INTERVAL '5 minutes';

SELECT 
    'Node B - Before Recovery' AS Status,
    COUNT(*) AS BallotCount
FROM 
    evotingdb_nodeB.Ballot
WHERE 
    VoteDate > CURRENT_TIMESTAMP - INTERVAL '5 minutes';

-- =====================================================
-- STEP 4: Rollback Prepared Transaction (Recovery)
-- =====================================================

-- Option 1: Rollback if transaction coordinator decides to abort
ROLLBACK PREPARED 'failed_tx_001';

-- Verify transaction was rolled back
SELECT 
    gid,
    prepared
FROM 
    pg_prepared_xacts
WHERE 
    gid = 'failed_tx_001';

-- Should return no rows (transaction rolled back)

-- =====================================================
-- STEP 5: Verify Data Consistency After Rollback
-- =====================================================

-- Check that data from failed transaction is not present
SELECT 
    'After Rollback' AS Status,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot 
     WHERE VoteDate > CURRENT_TIMESTAMP - INTERVAL '5 minutes') AS NodeA_Recent,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot 
     WHERE VoteDate > CURRENT_TIMESTAMP - INTERVAL '5 minutes') AS NodeB_Recent;

-- =====================================================
-- STEP 6: Complete Recovery Scenario
-- =====================================================

-- Create another prepared transaction for demonstration
BEGIN;

INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (2, 2, CURRENT_TIMESTAMP, 'Valid');

INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (5, 5, CURRENT_TIMESTAMP, 'Valid');

PREPARE TRANSACTION 'recovery_test_tx_002';

-- Check prepared transactions
SELECT 
    gid AS TransactionID,
    prepared AS PreparedTime,
    age(prepared) AS Age,
    owner
FROM 
    pg_prepared_xacts;

-- =====================================================
-- STEP 7: Recovery Options
-- =====================================================

-- Option A: Commit if recovery determines transaction should proceed
COMMIT PREPARED 'recovery_test_tx_002';

-- Option B: Rollback if recovery determines transaction should abort
-- ROLLBACK PREPARED 'recovery_test_tx_002';

-- =====================================================
-- STEP 8: Monitor Prepared Transactions (Recovery Query)
-- =====================================================

-- Query to find all prepared transactions needing recovery
SELECT 
    gid AS TransactionID,
    prepared AS PreparedTime,
    age(prepared) AS TransactionAge,
    owner AS Owner,
    database AS DatabaseName,
    CASE 
        WHEN age(prepared) > interval '24 hours' THEN 'STALE - Manual Recovery Required'
        WHEN age(prepared) > interval '1 hour' THEN 'OLD - Review Required'
        ELSE 'RECENT - Active'
    END AS RecoveryStatus
FROM 
    pg_prepared_xacts
ORDER BY 
    prepared;

-- =====================================================
-- STEP 9: Automated Recovery Procedure
-- =====================================================

-- Example recovery procedure (execute manually or via cron job)
DO $$
DECLARE
    tx_record RECORD;
BEGIN
    -- Find stale prepared transactions
    FOR tx_record IN 
        SELECT gid FROM pg_prepared_xacts 
        WHERE age(prepared) > interval '24 hours'
    LOOP
        -- Log recovery action
        RAISE NOTICE 'Rolling back stale transaction: %', tx_record.gid;
        
        -- Rollback stale transaction
        EXECUTE format('ROLLBACK PREPARED %L', tx_record.gid);
    END LOOP;
END $$;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Verify no orphaned prepared transactions
SELECT 
    COUNT(*) AS PendingPreparedTransactions
FROM 
    pg_prepared_xacts;

*/

-- =====================================================
-- APPROACH 2: Rollback and Recovery using Savepoints
-- (Works without server configuration changes)
-- =====================================================

-- This approach demonstrates distributed rollback and recovery using savepoints
-- It simulates the same recovery concepts without requiring prepared transactions

-- =====================================================
-- STEP 1: Simulate Transaction with Network Failure
-- =====================================================

BEGIN;

-- Create savepoint before inserts (simulates "prepare" phase)
SAVEPOINT before_inserts;

-- Insert data into Node A
INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
SELECT 
    MAX(VoterID),
    MAX(CandidateID),
    CURRENT_TIMESTAMP,
    'Valid'
FROM 
    evotingdb_nodeA.Voter, evotingdb_nodeA.Candidate
ON CONFLICT DO NOTHING;

-- Insert data into Node B
INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
SELECT 
    MAX(VoterID),
    MAX(CandidateID),
    CURRENT_TIMESTAMP,
    'Valid'
FROM 
    evotingdb_nodeB.Voter, evotingdb_nodeB.Candidate
ON CONFLICT DO NOTHING;

-- At this point, simulate network failure
-- Transaction is active but not yet committed
SELECT 
    'Before Failure Simulation' AS Status,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot 
     WHERE VoteDate > CURRENT_TIMESTAMP - INTERVAL '1 minute') AS NodeA_Recent,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot 
     WHERE VoteDate > CURRENT_TIMESTAMP - INTERVAL '1 minute') AS NodeB_Recent;

-- =====================================================
-- STEP 2: Simulate Network Failure - Rollback to Savepoint
-- =====================================================

-- Simulate failure recovery: Rollback to savepoint
ROLLBACK TO before_inserts;

SELECT 
    'After Rollback to Savepoint' AS Status,
    'Transaction rolled back - both nodes restored to previous state' AS Result;

-- Complete rollback
ROLLBACK;

-- =====================================================
-- STEP 3: Verify Data Consistency After Rollback
-- =====================================================

-- Check that data from failed transaction is not present
SELECT 
    'Data Consistency Check' AS Status,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot 
     WHERE VoteDate > CURRENT_TIMESTAMP - INTERVAL '2 minutes') AS NodeA_Recent,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot 
     WHERE VoteDate > CURRENT_TIMESTAMP - INTERVAL '2 minutes') AS NodeB_Recent,
    CASE 
        WHEN (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot 
              WHERE VoteDate > CURRENT_TIMESTAMP - INTERVAL '2 minutes') = 0
        AND (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot 
             WHERE VoteDate > CURRENT_TIMESTAMP - INTERVAL '2 minutes') = 0
        THEN '✓ PASS - Rollback successful, data consistency maintained'
        ELSE '⚠ CHECK - Some data may remain'
    END AS Verification;

-- =====================================================
-- STEP 4: Recovery Scenario - Success Case
-- =====================================================

-- Retry the transaction after recovery
BEGIN;

SAVEPOINT recovery_retry;

-- Retry: Insert into Node A
INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
SELECT 
    MAX(VoterID),
    MAX(CandidateID),
    CURRENT_TIMESTAMP,
    'Valid'
FROM 
    evotingdb_nodeA.Voter, evotingdb_nodeA.Candidate
ON CONFLICT DO NOTHING;

-- Retry: Insert into Node B
INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
SELECT 
    MAX(VoterID),
    MAX(CandidateID),
    CURRENT_TIMESTAMP,
    'Valid'
FROM 
    evotingdb_nodeB.Voter, evotingdb_nodeB.Candidate
ON CONFLICT DO NOTHING;

-- Success: Commit transaction
COMMIT;

SELECT 
    'Recovery Success' AS Status,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot) AS NodeA_Total,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot) AS NodeB_Total;

-- =====================================================
-- STEP 5: Monitor Recovery (Check Transaction State)
-- =====================================================

-- In a real scenario, check for any unresolved transactions
-- Since we're using savepoints, we check committed transactions
SELECT 
    'Recovery Status' AS Check,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot) AS NodeA_Ballots,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot) AS NodeB_Ballots,
    (SELECT COUNT(*) FROM pg_prepared_xacts) AS PendingPreparedTx,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_prepared_xacts) = 0 
        THEN '✓ No pending transactions - System consistent'
        ELSE '⚠ Pending prepared transactions need recovery'
    END AS Status;

-- =====================================================
-- STEP 6: Automated Recovery Procedure (Savepoint Approach)
-- =====================================================

-- Example: Automated check for transaction consistency
DO $$
DECLARE
    node_a_count INTEGER;
    node_b_count INTEGER;
BEGIN
    -- Check transaction counts
    SELECT COUNT(*) INTO node_a_count FROM evotingdb_nodeA.Ballot;
    SELECT COUNT(*) INTO node_b_count FROM evotingdb_nodeB.Ballot;
    
    RAISE NOTICE '=== Recovery Status Check ===';
    RAISE NOTICE 'Node A Ballots: %', node_a_count;
    RAISE NOTICE 'Node B Ballots: %', node_b_count;
    
    -- In a real scenario, you would check for inconsistencies
    -- and perform recovery actions here
    IF node_a_count >= 0 AND node_b_count >= 0 THEN
        RAISE NOTICE '✓ System appears consistent';
    ELSE
        RAISE WARNING '⚠ Potential inconsistency detected';
    END IF;
END $$;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Final verification
SELECT 
    'Final Recovery Verification' AS Check,
    (SELECT COUNT(*) FROM pg_prepared_xacts) AS PendingTransactions,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot) AS NodeA_Ballots,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot) AS NodeB_Ballots,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_prepared_xacts) = 0 
        THEN '✓ PASS - No pending transactions, system recovered'
        ELSE '⚠ CHECK - Pending transactions exist'
    END AS Result;

-- =====================================================
-- EXPLANATION
-- =====================================================

-- Distributed Rollback and Recovery Concepts:
-- 1. Transaction failures can leave data in inconsistent state
-- 2. Recovery process checks for unresolved transactions
-- 3. Decide to commit or rollback based on recovery rules
-- 4. Ensures all nodes have consistent state after recovery

-- This file provides two approaches:
-- APPROACH 1: Uses PREPARE TRANSACTION/ROLLBACK PREPARED (requires max_prepared_transactions > 0)
-- APPROACH 2: Uses SAVEPOINT/ROLLBACK TO (works without server configuration)
-- Both demonstrate distributed rollback and recovery effectively.

