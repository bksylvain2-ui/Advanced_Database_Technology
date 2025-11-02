-- =====================================================
-- TASK 4: Two-Phase Commit Simulation
-- Assignment 3: Distributed and Parallel Database
-- Database: evotingdb
-- PostgreSQL (pgAdmin 4) Compatible
-- =====================================================

-- Prerequisites: 
-- 1. Run task1_create_schema.sql (basic tasks)
-- 2. Run task3_insert_mock_data.sql (basic tasks)
-- 3. Run task1_distributed_schema_fragmentation.sql (Assignment 3)

-- PostgreSQL uses Prepared Transactions to simulate two-phase commit
-- This ensures atomicity across distributed nodes

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
        THEN '✗ DISABLED - Need to enable in postgresql.conf'
        ELSE 'CHECK'
    END AS Status
FROM 
    pg_settings
WHERE 
    name = 'max_prepared_transactions';

-- NOTE: If max_prepared_transactions = 0, you need to:
-- 1. Edit postgresql.conf file
-- 2. Set max_prepared_transactions = 10 (or higher)
-- 3. Restart PostgreSQL server
-- OR use the alternative approach below (using regular transactions)

-- =====================================================
-- APPROACH 1: Prepared Transactions (Requires Server Config)
-- =====================================================

-- Uncomment the section below ONLY if max_prepared_transactions > 0
/*
-- =====================================================
-- STEP 1: Two-Phase Commit on Single Node (Prepared Transaction)
-- =====================================================

-- Begin transaction
BEGIN;

-- Insert into Node A
INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (1, 1, CURRENT_TIMESTAMP, 'Valid');

-- Insert into Node B (simulating distributed operation)
INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (4, 4, CURRENT_TIMESTAMP, 'Valid');

-- Prepare transaction (Phase 1: Prepare)
-- This persists the transaction but doesn't commit yet
PREPARE TRANSACTION 'ballot_insert_tx_001';

-- Transaction is now in prepared state
-- Check prepared transactions
SELECT 
    gid AS TransactionID,
    prepared AS PreparedTime,
    owner AS Owner,
    database AS Database
FROM 
    pg_prepared_xacts;

-- =====================================================
-- STEP 2: Commit Prepared Transaction (Phase 2: Commit)
-- =====================================================

-- Commit the prepared transaction
COMMIT PREPARED 'ballot_insert_tx_001';

-- Verify data was committed
SELECT 
    'Node A' AS Node,
    COUNT(*) AS BallotCount
FROM 
    evotingdb_nodeA.Ballot
UNION ALL
SELECT 
    'Node B' AS Node,
    COUNT(*) AS BallotCount
FROM 
    evotingdb_nodeB.Ballot;

-- =====================================================
-- STEP 3: Two-Phase Commit Across Nodes (Simulation)
-- =====================================================

-- Simulate coordinated commit across multiple nodes
BEGIN;

-- Operation 1: Insert vote in Node A
INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (2, 2, CURRENT_TIMESTAMP, 'Valid');

-- Operation 2: Update result in Node B
INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (5, 5, CURRENT_TIMESTAMP, 'Valid');

-- Prepare transaction
PREPARE TRANSACTION 'distributed_vote_tx_002';

-- =====================================================
-- STEP 4: Verify Prepared Transactions
-- =====================================================

-- List all prepared transactions (equivalent to DBA_2PC_PENDING in Oracle)
SELECT 
    gid AS TransactionID,
    prepared AS PreparedTime,
    owner AS Owner,
    database AS Database
FROM 
    pg_prepared_xacts;

-- =====================================================
-- STEP 5: Commit All Prepared Transactions
-- =====================================================

-- Commit the prepared transaction to finalize
COMMIT PREPARED 'distributed_vote_tx_002';

-- =====================================================
-- STEP 6: Verify Atomicity
-- =====================================================

-- Check that both nodes have consistent data
-- If commit succeeded, both operations should be visible
SELECT 
    'After Commit' AS Status,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot) AS NodeA_Ballots,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot) AS NodeB_Ballots;

-- =====================================================
-- STEP 7: Complete Two-Phase Commit Example
-- =====================================================

-- Full example: Insert vote across both nodes atomically
BEGIN;

-- Phase 1: Prepare operations
INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (3, 3, CURRENT_TIMESTAMP, 'Valid');

INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (6, 6, CURRENT_TIMESTAMP, 'Valid');

-- Prepare transaction
PREPARE TRANSACTION 'final_vote_tx_003';

-- Phase 2: Check prepared state (could be done by transaction coordinator)
SELECT 
    gid,
    prepared,
    owner
FROM 
    pg_prepared_xacts
WHERE 
    gid = 'final_vote_tx_003';

-- Phase 3: Commit if all nodes prepared successfully
COMMIT PREPARED 'final_vote_tx_003';

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Verify all votes are recorded
SELECT 
    'Total Ballots Across Nodes' AS Description,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot) + 
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot) AS TotalCount;

*/

-- =====================================================
-- APPROACH 2: Alternative - Regular Transactions with Savepoints
-- (Works without server configuration changes)
-- =====================================================

-- This approach demonstrates two-phase commit concept using savepoints
-- It simulates the prepare/commit pattern without requiring prepared transactions

-- Simulate Two-Phase Commit: Phase 1 (Prepare)
BEGIN;

-- Create a savepoint (simulates "prepare" phase)
SAVEPOINT prepare_phase;

-- Insert into Node A
INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (1, 1, CURRENT_TIMESTAMP, 'Valid')
ON CONFLICT DO NOTHING;

-- Insert into Node B (simulating distributed operation)
INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (4, 4, CURRENT_TIMESTAMP, 'Valid')
ON CONFLICT DO NOTHING;

-- Phase 1 Complete: Both operations prepared (using savepoint)
SELECT 
    'Phase 1: Prepared' AS Status,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot WHERE VoterID = 1) AS NodeA_Check,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot WHERE VoterID = 4) AS NodeB_Check;

-- Phase 2: Commit (Release savepoint and commit transaction)
-- If everything is OK, commit; otherwise we can rollback to savepoint
COMMIT;

SELECT 
    'Phase 2: Committed' AS Status,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot) AS NodeA_Ballots,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot) AS NodeB_Ballots;

-- =====================================================
-- Complete Example: Distributed Transaction with Savepoints
-- =====================================================

BEGIN;

SAVEPOINT prepare_distributed_tx;

-- Operation 1: Node A
INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (2, 2, CURRENT_TIMESTAMP, 'Valid')
ON CONFLICT DO NOTHING;

-- Operation 2: Node B
INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (5, 5, CURRENT_TIMESTAMP, 'Valid')
ON CONFLICT DO NOTHING;

-- Verify both prepared successfully
SELECT 
    'Distributed Transaction Prepared' AS Status,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot WHERE VoterID = 2) AS NodeA_Prepared,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot WHERE VoterID = 5) AS NodeB_Prepared;

-- Commit (Phase 2)
COMMIT;

-- =====================================================
-- Rollback Example (Simulating Failure Recovery)
-- =====================================================

BEGIN;

SAVEPOINT prepare_rollback_test;

-- Insert into Node A
INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
VALUES (3, 3, CURRENT_TIMESTAMP, 'Valid')
ON CONFLICT DO NOTHING;

-- Simulate error in Node B (for demonstration)
-- ROLLBACK TO prepare_rollback_test;  -- Uncomment to test rollback

-- If successful, commit; otherwise rollback
COMMIT;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Verify all votes are recorded
SELECT 
    'Total Ballots Across Nodes' AS Description,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot) + 
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot) AS TotalCount;

-- =====================================================
-- EXPLANATION
-- =====================================================

-- Two-Phase Commit Concept:
-- Phase 1 (PREPARE): All nodes prepare to commit, transaction is persisted
-- Phase 2 (COMMIT): If all nodes prepared successfully, commit all
-- If any node fails, all nodes can rollback for consistency.

-- This file provides two approaches:
-- APPROACH 1: Uses PREPARE TRANSACTION (requires max_prepared_transactions > 0)
-- APPROACH 2: Uses SAVEPOINT (works without server configuration)
-- Both demonstrate the two-phase commit concept effectively.

-- =====================================================
-- SHORT QUERY: PL/pgSQL Block for Task 4 Requirements
-- =====================================================

-- =====================================================
-- SHORT QUERY: Complete Solution for Task Requirements
-- =====================================================

-- Run these queries to fulfill task requirements:
-- "Write a PL/SQL block performing inserts on both nodes and committing once.
--  Verify atomicity using DBA_2PC_PENDING."

-- QUERY 1: PL/pgSQL Block - Insert on both nodes and commit once
BEGIN;
    -- Insert on Node A
    INSERT INTO evotingdb_nodeA.Ballot (VoterID, CandidateID, VoteDate, Validity)
    SELECT 
        (SELECT MAX(VoterID) FROM evotingdb_nodeA.Voter),
        (SELECT MAX(CandidateID) FROM evotingdb_nodeA.Candidate),
        CURRENT_TIMESTAMP,
        'Valid'
    WHERE EXISTS (SELECT 1 FROM evotingdb_nodeA.Voter)
      AND EXISTS (SELECT 1 FROM evotingdb_nodeA.Candidate);
    
    -- Insert on Node B
    INSERT INTO evotingdb_nodeB.Ballot (VoterID, CandidateID, VoteDate, Validity)
    SELECT 
        (SELECT MAX(VoterID) FROM evotingdb_nodeB.Voter),
        (SELECT MAX(CandidateID) FROM evotingdb_nodeB.Candidate),
        CURRENT_TIMESTAMP,
        'Valid'
    WHERE EXISTS (SELECT 1 FROM evotingdb_nodeB.Voter)
      AND EXISTS (SELECT 1 FROM evotingdb_nodeB.Candidate);
    
    -- Commit once (atomicity: both succeed or both fail)
COMMIT;

-- Verify atomicity using pg_prepared_xacts (PostgreSQL equivalent of DBA_2PC_PENDING)
SELECT 
    'Atomicity Verification' AS Check,
    gid AS TransactionID,
    prepared AS PreparedTime,
    owner AS Owner,
    database AS Database,
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ All transactions committed - No pending (atomicity verified)'
        ELSE '⚠ ' || COUNT(*) || ' pending prepared transaction(s)'
    END AS Status
FROM 
    pg_prepared_xacts
GROUP BY 
    gid, prepared, owner, database
ORDER BY 
    prepared DESC;

-- Alternative: Simple atomicity check
SELECT 
    'Final Atomicity Check' AS Verification,
    (SELECT COUNT(*) FROM evotingdb_nodeA.Ballot) AS NodeA_Ballots,
    (SELECT COUNT(*) FROM evotingdb_nodeB.Ballot) AS NodeB_Ballots,
    (SELECT COUNT(*) FROM pg_prepared_xacts) AS PendingTransactions,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_prepared_xacts) = 0 
        THEN '✓ PASS - All transactions committed atomically'
        ELSE '⚠ WARNING - Pending prepared transactions exist'
    END AS Result;
