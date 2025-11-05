-- ============================================================================
-- A4: Two-Phase Commit & Recovery Setup
-- ============================================================================
-- This script sets up tables for demonstrating 2PC in the e-voting system
-- We'll use ElectionDelivery (local on Node_A) and ElectionPayment (remote on Node_B)

-- ============================================================================
-- STEP 1: Create ElectionDelivery table on Node_A (local)
-- ============================================================================
-- Tracks ballot delivery to polling stations

DROP TABLE IF EXISTS ElectionDelivery CASCADE;

CREATE TABLE ElectionDelivery (
    DeliveryID SERIAL PRIMARY KEY,
    ConstituencyID INTEGER NOT NULL,
    DeliveryDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    BallotCount INTEGER NOT NULL CHECK (BallotCount > 0),
    DeliveryStatus VARCHAR(20) NOT NULL CHECK (DeliveryStatus IN ('Pending', 'Delivered', 'Confirmed')),
    DeliveryOfficer VARCHAR(100) NOT NULL,
    FOREIGN KEY (ConstituencyID) REFERENCES Constituencies(ConstituencyID) ON DELETE CASCADE
);

COMMENT ON TABLE ElectionDelivery IS 'Tracks ballot delivery to polling stations (Node_A)';

-- ============================================================================
-- STEP 2: Create ElectionPayment table on Node_B (remote)
-- ============================================================================
-- Tracks election-related payments (polling station fees, etc.)

DROP TABLE IF EXISTS ElectionPayment CASCADE;

CREATE TABLE ElectionPayment (
    PaymentID SERIAL PRIMARY KEY,
    ConstituencyID INTEGER NOT NULL,
    PaymentDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Amount DECIMAL(10,2) NOT NULL CHECK (Amount > 0),
    PaymentType VARCHAR(50) NOT NULL CHECK (PaymentType IN ('Polling Station Fee', 'Staff Salary', 'Equipment Rental', 'Security')),
    PaymentStatus VARCHAR(20) NOT NULL CHECK (PaymentStatus IN ('Pending', 'Completed', 'Failed')),
    TransactionRef VARCHAR(50) UNIQUE NOT NULL,
    FOREIGN KEY (ConstituencyID) REFERENCES Constituencies(ConstituencyID) ON DELETE CASCADE
);

COMMENT ON TABLE ElectionPayment IS 'Tracks election-related payments (Node_B)';

-- ============================================================================
-- STEP 3: Create foreign table for ElectionPayment on Node_A
-- ============================================================================
-- This allows Node_A to access ElectionPayment@proj_link (on Node_B)

DROP FOREIGN TABLE IF EXISTS ElectionPayment_Remote CASCADE;

CREATE FOREIGN TABLE ElectionPayment_Remote (
    PaymentID INTEGER,
    ConstituencyID INTEGER,
    PaymentDate TIMESTAMP,
    Amount DECIMAL(10,2),
    PaymentType VARCHAR(50),
    PaymentStatus VARCHAR(20),
    TransactionRef VARCHAR(50)
)
SERVER proj_link
OPTIONS (schema_name 'public', table_name 'ElectionPayment');

COMMENT ON FOREIGN TABLE ElectionPayment_Remote IS 'Remote access to ElectionPayment on Node_B';

-- ============================================================================
-- STEP 4: Enable prepared transactions (required for 2PC)
-- ============================================================================
-- PostgreSQL requires max_prepared_transactions > 0 for 2PC
-- This would typically be set in postgresql.conf:
-- max_prepared_transactions = 10

-- Check current setting
SHOW max_prepared_transactions;

-- Note: If max_prepared_transactions = 0, you need to:
-- 1. Edit postgresql.conf: max_prepared_transactions = 10
-- 2. Restart PostgreSQL server
-- 3. Verify with: SHOW max_prepared_transactions;

-- ============================================================================
-- STEP 5: Create monitoring view for prepared transactions
-- ============================================================================
-- PostgreSQL equivalent of Oracle's DBA_2PC_PENDING

CREATE OR REPLACE VIEW Pending_2PC_Transactions AS
SELECT 
    gid AS transaction_id,
    prepared AS prepare_time,
    owner,
    database,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - prepared)) AS seconds_pending
FROM pg_prepared_xacts
ORDER BY prepared DESC;

COMMENT ON VIEW Pending_2PC_Transactions IS 'PostgreSQL equivalent of DBA_2PC_PENDING - shows in-doubt transactions';

-- ============================================================================
-- STEP 6: Create helper functions for 2PC operations
-- ============================================================================

-- Function to check if a transaction is prepared
CREATE OR REPLACE FUNCTION is_transaction_prepared(txn_id TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM pg_prepared_xacts WHERE gid = txn_id
    );
END;
$$ LANGUAGE plpgsql;

-- Function to get count of prepared transactions
CREATE OR REPLACE FUNCTION get_prepared_transaction_count()
RETURNS INTEGER AS $$
BEGIN
    RETURN (SELECT COUNT(*) FROM pg_prepared_xacts);
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'ElectionDelivery table created on Node_A' AS status;
SELECT 'ElectionPayment table created on Node_B' AS status;
SELECT 'Foreign table ElectionPayment_Remote created' AS status;
SELECT 'Prepared transaction monitoring view created' AS status;
SELECT 'Helper functions created' AS status;

-- Check prepared transactions setting
SELECT 
    CASE 
        WHEN CAST(current_setting('max_prepared_transactions') AS INTEGER) > 0 
        THEN '✓ Prepared transactions ENABLED (max: ' || current_setting('max_prepared_transactions') || ')'
        ELSE '✗ Prepared transactions DISABLED - Please enable in postgresql.conf'
    END AS prepared_transactions_status;

-- Show current prepared transactions (should be empty initially)
SELECT 
    COALESCE(COUNT(*)::TEXT, '0') || ' prepared transactions currently pending' AS current_status
FROM pg_prepared_xacts;
