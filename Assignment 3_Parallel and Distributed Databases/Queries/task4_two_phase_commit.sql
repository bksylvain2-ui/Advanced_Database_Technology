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

-- Explanation:
-- Two-Phase Commit ensures atomicity in distributed transactions:
-- Phase 1 (PREPARE): All nodes prepare to commit, transaction is persisted
-- Phase 2 (COMMIT PREPARED): If all nodes prepared successfully, commit all
-- If any node fails, all nodes can rollback for consistency.

