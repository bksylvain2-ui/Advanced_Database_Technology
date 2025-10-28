-- ============================================================================
-- A4: Two-Phase Commit - FAILURE Scenario with In-Doubt Transaction
-- ============================================================================
-- This demonstrates a FAILED 2PC transaction that creates an in-doubt state

-- ============================================================================
-- STEP 1: Pre-failure state
-- ============================================================================

SELECT '=== BEFORE FAILURE SCENARIO ===' AS step;

-- Count existing rows
SELECT COUNT(*) AS delivery_count_before FROM ElectionDelivery;
SELECT COUNT(*) AS payment_count_before FROM ElectionPayment;

-- Check for any pending prepared transactions
SELECT * FROM Pending_2PC_Transactions;

-- ============================================================================
-- STEP 2: Execute Two-Phase Commit with PREPARE (for failure demonstration)
-- ============================================================================

DO $$
DECLARE
    v_transaction_id TEXT := 'evoting_2pc_' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISS');
    v_constituency_id INTEGER := 2; -- Kicukiro District
BEGIN
    RAISE NOTICE '[v0] Starting 2PC transaction with PREPARE: %', v_transaction_id;
    
    -- ========================================================================
    -- PHASE 1: LOCAL INSERT (Node_A)
    -- ========================================================================
    RAISE NOTICE '[v0] Phase 1: Inserting into ElectionDelivery (local)...';
    
    INSERT INTO ElectionDelivery (
        ConstituencyID,
        DeliveryDate,
        BallotCount,
        DeliveryStatus,
        DeliveryOfficer
    ) VALUES (
        v_constituency_id,
        CURRENT_TIMESTAMP,
        3000,
        'Pending',
        'Marie Claire Uwase'
    );
    
    RAISE NOTICE '[v0] ✓ Local insert successful (not yet committed)';
    
    -- ========================================================================
    -- PREPARE TRANSACTION: Create in-doubt state
    -- ========================================================================
    RAISE NOTICE '[v0] Preparing transaction (creating in-doubt state)...';
    
    -- This creates a prepared transaction that can be committed or rolled back later
    EXECUTE 'PREPARE TRANSACTION ' || quote_literal(v_transaction_id);
    
    RAISE NOTICE '[v0] ⚠ Transaction PREPARED (in-doubt state created)';
    RAISE NOTICE '[v0] Transaction ID: %', v_transaction_id;
    RAISE NOTICE '[v0] This transaction is now in-doubt and requires manual resolution';
    
END $$;

-- ============================================================================
-- STEP 3: Query DBA_2PC_PENDING equivalent (pg_prepared_xacts)
-- ============================================================================

SELECT '=== IN-DOUBT TRANSACTION DETECTED ===' AS step;

-- Show pending prepared transactions (PostgreSQL equivalent of DBA_2PC_PENDING)
SELECT 
    '⚠ PENDING PREPARED TRANSACTION' AS status,
    gid AS transaction_id,
    prepared AS prepare_time,
    owner,
    database,
    ROUND(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - prepared))::NUMERIC, 2) AS seconds_pending
FROM pg_prepared_xacts
WHERE gid LIKE 'evoting_2pc_%'
ORDER BY prepared DESC;

-- Detailed view
SELECT * FROM Pending_2PC_Transactions;

-- ============================================================================
-- STEP 4: Check data state during in-doubt transaction
-- ============================================================================

SELECT '=== DATA STATE DURING IN-DOUBT TRANSACTION ===' AS step;

-- The local insert is NOT visible because transaction is prepared (not committed)
SELECT 
    COUNT(*) AS delivery_count_during_indoubt,
    'Prepared row NOT visible in normal queries' AS note
FROM ElectionDelivery;

-- Remote table unchanged (no insert attempted yet)
SELECT 
    COUNT(*) AS payment_count_during_indoubt,
    'No remote insert attempted' AS note
FROM ElectionPayment;

-- ============================================================================
-- STEP 5: Simulate failure - attempt remote insert that fails
-- ============================================================================

SELECT '=== SIMULATING REMOTE INSERT FAILURE ===' AS step;

-- In a real scenario, the remote insert would fail due to:
-- - Network failure
-- - Remote database unavailable
-- - Constraint violation
-- - Timeout

-- For demonstration, we'll show what would happen if remote insert fails
DO $$
BEGIN
    RAISE NOTICE '[v0] Attempting remote insert to ElectionPayment...';
    RAISE NOTICE '[v0] ✗ SIMULATED FAILURE: Remote database connection lost';
    RAISE NOTICE '[v0] ✗ Unable to complete Phase 2 of 2PC';
    RAISE NOTICE '[v0] ⚠ Transaction remains in PREPARED state (in-doubt)';
END $$;

-- ============================================================================
-- STEP 6: Show in-doubt transaction summary
-- ============================================================================

SELECT 
    '⚠ IN-DOUBT TRANSACTION SUMMARY' AS status,
    (SELECT COUNT(*) FROM pg_prepared_xacts WHERE gid LIKE 'evoting_2pc_%') AS prepared_transactions,
    'Manual intervention required: COMMIT PREPARED or ROLLBACK PREPARED' AS action_needed;

-- ============================================================================
-- EXPECTED OUTPUT AT THIS POINT
-- ============================================================================
-- ✓ One prepared transaction visible in pg_prepared_xacts
-- ✓ Local insert NOT visible (transaction prepared, not committed)
-- ✓ Remote insert NOT attempted (failure before Phase 2)
-- ✓ System in in-doubt state requiring manual resolution
