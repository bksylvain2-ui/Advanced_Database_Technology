-- =====================================================
-- TASK 13: Distributed Rollback and Recovery
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: 
-- 1. Run task1_create_schema.sql
-- 2. Run task9_distributed_schema_fragmentation.sql
-- 3. Run task12_two_phase_commit.sql (for prepared transactions)

-- Simulate network failure during distributed transaction and recovery

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

-- Explanation:
-- Distributed rollback ensures transaction atomicity:
-- 1. Prepared transactions persist across failures
-- 2. Recovery process checks pg_prepared_xacts
-- 3. Decide to COMMIT PREPARED or ROLLBACK PREPARED
-- 4. Ensures all nodes have consistent state after recovery

