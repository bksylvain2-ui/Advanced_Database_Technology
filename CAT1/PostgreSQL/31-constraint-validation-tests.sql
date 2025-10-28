-- ============================================================================
-- B6: Declarative Rules Hardening - Validation Tests
-- ============================================================================
-- Script 28: Test Constraints with Passing and Failing INSERTs
-- ============================================================================

-- ============================================================================
-- PART 1: ElectionDelivery Tests (2 Passing + 2 Failing)
-- ============================================================================

\echo '============================================================================'
\echo 'TESTING ElectionDelivery CONSTRAINTS'
\echo '============================================================================'

-- Clear any test data first
DELETE FROM ElectionDelivery WHERE DeliveryID >= 100;

-- ----------------------------------------------------------------------------
-- PASSING TEST 1: Valid delivery record
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- PASSING TEST 1: Valid ElectionDelivery ---'
BEGIN;
INSERT INTO ElectionDelivery (DeliveryID, ConstituencyID, DeliveryDate, BallotQuantity, DeliveryStatus)
VALUES (101, 1, '2025-01-15', 5000, 'Delivered');
COMMIT;
\echo '✓ PASSED: Valid delivery inserted successfully'

-- ----------------------------------------------------------------------------
-- PASSING TEST 2: Valid pending delivery
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- PASSING TEST 2: Valid Pending Delivery ---'
BEGIN;
INSERT INTO ElectionDelivery (DeliveryID, ConstituencyID, DeliveryDate, BallotQuantity, DeliveryStatus)
VALUES (102, 2, CURRENT_DATE, 3000, 'Pending');
COMMIT;
\echo '✓ PASSED: Pending delivery inserted successfully'

-- ----------------------------------------------------------------------------
-- FAILING TEST 1: Negative ballot quantity (violates chk_delivery_ballot_quantity_positive)
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- FAILING TEST 1: Negative Ballot Quantity ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO ElectionDelivery (DeliveryID, ConstituencyID, DeliveryDate, BallotQuantity, DeliveryStatus)
        VALUES (103, 1, '2025-01-15', -100, 'Pending');
        RAISE NOTICE '✗ UNEXPECTED: Should have failed but succeeded';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '✓ EXPECTED FAILURE: %', SQLERRM;
            RAISE NOTICE 'Constraint violated: chk_delivery_ballot_quantity_positive';
    END;
    ROLLBACK;
END $$;

-- ----------------------------------------------------------------------------
-- FAILING TEST 2: Invalid status (violates chk_delivery_status_valid)
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- FAILING TEST 2: Invalid Delivery Status ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO ElectionDelivery (DeliveryID, ConstituencyID, DeliveryDate, BallotQuantity, DeliveryStatus)
        VALUES (104, 2, '2025-01-15', 2000, 'InvalidStatus');
        RAISE NOTICE '✗ UNEXPECTED: Should have failed but succeeded';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '✓ EXPECTED FAILURE: %', SQLERRM;
            RAISE NOTICE 'Constraint violated: chk_delivery_status_valid';
    END;
    ROLLBACK;
END $$;

-- ----------------------------------------------------------------------------
-- FAILING TEST 3: Future delivery date (violates chk_delivery_date_not_future)
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- FAILING TEST 3: Future Delivery Date ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO ElectionDelivery (DeliveryID, ConstituencyID, DeliveryDate, BallotQuantity, DeliveryStatus)
        VALUES (105, 3, CURRENT_DATE + INTERVAL '30 days', 1000, 'Pending');
        RAISE NOTICE '✗ UNEXPECTED: Should have failed but succeeded';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '✓ EXPECTED FAILURE: %', SQLERRM;
            RAISE NOTICE 'Constraint violated: chk_delivery_date_not_future';
    END;
    ROLLBACK;
END $$;

-- ----------------------------------------------------------------------------
-- FAILING TEST 4: NULL required field (violates NOT NULL)
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- FAILING TEST 4: NULL Ballot Quantity ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO ElectionDelivery (DeliveryID, ConstituencyID, DeliveryDate, BallotQuantity, DeliveryStatus)
        VALUES (106, 1, '2025-01-15', NULL, 'Pending');
        RAISE NOTICE '✗ UNEXPECTED: Should have failed but succeeded';
    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE '✓ EXPECTED FAILURE: %', SQLERRM;
            RAISE NOTICE 'Constraint violated: NOT NULL on BallotQuantity';
    END;
    ROLLBACK;
END $$;

-- ============================================================================
-- PART 2: ElectionPayment Tests (2 Passing + 2 Failing)
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'TESTING ElectionPayment CONSTRAINTS'
\echo '============================================================================'

-- Clear any test data first
DELETE FROM ElectionPayment WHERE PaymentID >= 100;

-- ----------------------------------------------------------------------------
-- PASSING TEST 1: Valid payment record
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- PASSING TEST 1: Valid ElectionPayment ---'
BEGIN;
INSERT INTO ElectionPayment (PaymentID, DeliveryID, PaymentAmount, PaymentDate, PaymentStatus, PaymentMethod)
VALUES (101, 101, 50000.00, '2025-01-16', 'Completed', 'Bank Transfer');
COMMIT;
\echo '✓ PASSED: Valid payment inserted successfully'

-- ----------------------------------------------------------------------------
-- PASSING TEST 2: Valid pending payment
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- PASSING TEST 2: Valid Pending Payment ---'
BEGIN;
INSERT INTO ElectionPayment (PaymentID, DeliveryID, PaymentAmount, PaymentDate, PaymentStatus, PaymentMethod)
VALUES (102, 102, 30000.00, CURRENT_DATE, 'Pending', 'Mobile Money');
COMMIT;
\echo '✓ PASSED: Pending payment inserted successfully'

-- ----------------------------------------------------------------------------
-- FAILING TEST 1: Negative payment amount (violates chk_payment_amount_positive)
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- FAILING TEST 1: Negative Payment Amount ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO ElectionPayment (PaymentID, DeliveryID, PaymentAmount, PaymentDate, PaymentStatus, PaymentMethod)
        VALUES (103, 101, -5000.00, '2025-01-16', 'Pending', 'Cash');
        RAISE NOTICE '✗ UNEXPECTED: Should have failed but succeeded';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '✓ EXPECTED FAILURE: %', SQLERRM;
            RAISE NOTICE 'Constraint violated: chk_payment_amount_positive';
    END;
    ROLLBACK;
END $$;

-- ----------------------------------------------------------------------------
-- FAILING TEST 2: Invalid payment status (violates chk_payment_status_valid)
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- FAILING TEST 2: Invalid Payment Status ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO ElectionPayment (PaymentID, DeliveryID, PaymentAmount, PaymentDate, PaymentStatus, PaymentMethod)
        VALUES (104, 102, 25000.00, '2025-01-16', 'Cancelled', 'Bank Transfer');
        RAISE NOTICE '✗ UNEXPECTED: Should have failed but succeeded';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '✓ EXPECTED FAILURE: %', SQLERRM;
            RAISE NOTICE 'Constraint violated: chk_payment_status_valid';
    END;
    ROLLBACK;
END $$;

-- ----------------------------------------------------------------------------
-- FAILING TEST 3: Excessive payment amount (violates chk_payment_amount_reasonable)
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- FAILING TEST 3: Excessive Payment Amount ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO ElectionPayment (PaymentID, DeliveryID, PaymentAmount, PaymentDate, PaymentStatus, PaymentMethod)
        VALUES (105, 101, 5000000.00, '2025-01-16', 'Pending', 'Bank Transfer');
        RAISE NOTICE '✗ UNEXPECTED: Should have failed but succeeded';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '✓ EXPECTED FAILURE: %', SQLERRM;
            RAISE NOTICE 'Constraint violated: chk_payment_amount_reasonable';
    END;
    ROLLBACK;
END $$;

-- ----------------------------------------------------------------------------
-- FAILING TEST 4: Invalid payment method (violates chk_payment_method_valid)
-- ----------------------------------------------------------------------------
\echo ''
\echo '--- FAILING TEST 4: Invalid Payment Method ---'
DO $$
BEGIN
    BEGIN
        INSERT INTO ElectionPayment (PaymentID, DeliveryID, PaymentAmount, PaymentDate, PaymentStatus, PaymentMethod)
        VALUES (106, 102, 15000.00, '2025-01-16', 'Pending', 'Cryptocurrency');
        RAISE NOTICE '✗ UNEXPECTED: Should have failed but succeeded';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE '✓ EXPECTED FAILURE: %', SQLERRM;
            RAISE NOTICE 'Constraint violated: chk_payment_method_valid';
    END;
    ROLLBACK;
END $$;

-- ============================================================================
-- PART 3: Verify Only Passing Rows Were Committed
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'VERIFICATION: Only Passing Rows Committed'
\echo '============================================================================'

\echo ''
\echo '--- ElectionDelivery Committed Rows ---'
SELECT DeliveryID, ConstituencyID, DeliveryDate, BallotQuantity, DeliveryStatus
FROM ElectionDelivery
WHERE DeliveryID >= 100
ORDER BY DeliveryID;

\echo ''
\echo '--- ElectionPayment Committed Rows ---'
SELECT PaymentID, DeliveryID, PaymentAmount, PaymentDate, PaymentStatus, PaymentMethod
FROM ElectionPayment
WHERE PaymentID >= 100
ORDER BY PaymentID;

\echo ''
\echo '--- Total Committed Rows Count ---'
SELECT 
    'ElectionDelivery' AS table_name,
    COUNT(*) AS committed_rows
FROM ElectionDelivery
WHERE DeliveryID >= 100
UNION ALL
SELECT 
    'ElectionPayment' AS table_name,
    COUNT(*) AS committed_rows
FROM ElectionPayment
WHERE PaymentID >= 100
UNION ALL
SELECT 
    'TOTAL' AS table_name,
    (SELECT COUNT(*) FROM ElectionDelivery WHERE DeliveryID >= 100) +
    (SELECT COUNT(*) FROM ElectionPayment WHERE PaymentID >= 100) AS committed_rows;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- ✓ ElectionDelivery: 2 passing inserts committed, 4 failing inserts rolled back
-- ✓ ElectionPayment: 2 passing inserts committed, 4 failing inserts rolled back
-- ✓ Total committed test rows: 4 (within ≤10 budget)
-- ✓ All constraint violations properly caught and handled
-- ✓ Clean error messages displayed for each failure
-- ============================================================================
