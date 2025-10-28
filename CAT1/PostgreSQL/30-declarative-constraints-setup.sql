-- ============================================================================
-- B6: Declarative Rules Hardening (≤10 committed rows)
-- ============================================================================
-- Script 27: Add NOT NULL and CHECK Constraints to ElectionDelivery and ElectionPayment
-- ============================================================================

-- Ensure tables exist from previous 2PC setup
-- ElectionDelivery and ElectionPayment should already exist

-- ============================================================================
-- PART 1: Add Constraints to ElectionDelivery (Node_A)
-- ============================================================================

-- Add NOT NULL constraints
ALTER TABLE ElectionDelivery 
  ALTER COLUMN DeliveryID SET NOT NULL,
  ALTER COLUMN ConstituencyID SET NOT NULL,
  ALTER COLUMN DeliveryDate SET NOT NULL,
  ALTER COLUMN BallotQuantity SET NOT NULL,
  ALTER COLUMN DeliveryStatus SET NOT NULL;

-- Add CHECK constraints with consistent naming
ALTER TABLE ElectionDelivery
  ADD CONSTRAINT chk_delivery_ballot_quantity_positive 
    CHECK (BallotQuantity > 0),
  ADD CONSTRAINT chk_delivery_status_valid 
    CHECK (DeliveryStatus IN ('Pending', 'In Transit', 'Delivered', 'Cancelled')),
  ADD CONSTRAINT chk_delivery_date_not_future 
    CHECK (DeliveryDate <= CURRENT_DATE);

-- Add optional received date validation (if received, must be after delivery date)
ALTER TABLE ElectionDelivery
  ADD COLUMN ReceivedDate DATE,
  ADD CONSTRAINT chk_delivery_received_after_delivery 
    CHECK (ReceivedDate IS NULL OR ReceivedDate >= DeliveryDate);

COMMENT ON CONSTRAINT chk_delivery_ballot_quantity_positive ON ElectionDelivery 
  IS 'Ensures ballot quantity is always positive';
COMMENT ON CONSTRAINT chk_delivery_status_valid ON ElectionDelivery 
  IS 'Restricts delivery status to valid values';
COMMENT ON CONSTRAINT chk_delivery_date_not_future ON ElectionDelivery 
  IS 'Prevents delivery dates in the future';

-- ============================================================================
-- PART 2: Add Constraints to ElectionPayment (Node_B)
-- ============================================================================

-- Add NOT NULL constraints
ALTER TABLE ElectionPayment 
  ALTER COLUMN PaymentID SET NOT NULL,
  ALTER COLUMN DeliveryID SET NOT NULL,
  ALTER COLUMN PaymentAmount SET NOT NULL,
  ALTER COLUMN PaymentDate SET NOT NULL,
  ALTER COLUMN PaymentStatus SET NOT NULL;

-- Add CHECK constraints with consistent naming
ALTER TABLE ElectionPayment
  ADD CONSTRAINT chk_payment_amount_positive 
    CHECK (PaymentAmount > 0),
  ADD CONSTRAINT chk_payment_status_valid 
    CHECK (PaymentStatus IN ('Pending', 'Completed', 'Failed', 'Refunded')),
  ADD CONSTRAINT chk_payment_date_not_future 
    CHECK (PaymentDate <= CURRENT_DATE),
  ADD CONSTRAINT chk_payment_amount_reasonable 
    CHECK (PaymentAmount <= 1000000); -- Max 1M RWF per payment

-- Add payment method validation
ALTER TABLE ElectionPayment
  ADD COLUMN PaymentMethod VARCHAR(50) DEFAULT 'Bank Transfer',
  ADD CONSTRAINT chk_payment_method_valid 
    CHECK (PaymentMethod IN ('Bank Transfer', 'Mobile Money', 'Cash', 'Credit Card'));

COMMENT ON CONSTRAINT chk_payment_amount_positive ON ElectionPayment 
  IS 'Ensures payment amount is always positive';
COMMENT ON CONSTRAINT chk_payment_status_valid ON ElectionPayment 
  IS 'Restricts payment status to valid values';
COMMENT ON CONSTRAINT chk_payment_date_not_future ON ElectionPayment 
  IS 'Prevents payment dates in the future';
COMMENT ON CONSTRAINT chk_payment_amount_reasonable ON ElectionPayment 
  IS 'Prevents unreasonably large payment amounts';

-- ============================================================================
-- PART 3: Verify Constraints
-- ============================================================================

-- List all constraints on ElectionDelivery
SELECT 
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'ElectionDelivery'::regclass
ORDER BY conname;

-- List all constraints on ElectionPayment
SELECT 
    conname AS constraint_name,
    contype AS constraint_type,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid = 'ElectionPayment'::regclass
ORDER BY conname;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- ✓ Added NOT NULL constraints to all required columns
-- ✓ Added CHECK constraints for positive amounts
-- ✓ Added CHECK constraints for valid status values
-- ✓ Added CHECK constraints for date logic (no future dates)
-- ✓ Added domain-specific business rules (reasonable amounts, valid methods)
-- ✓ All constraints follow consistent naming convention: chk_table_column_rule
-- ============================================================================
