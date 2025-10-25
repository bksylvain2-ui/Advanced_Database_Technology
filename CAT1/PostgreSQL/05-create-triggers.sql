-- ============================================================================
-- Script 05: Create Triggers
-- ============================================================================
-- Trigger: Prevent multiple votes from the same voter
-- This ensures one voter can only vote once
-- ============================================================================
-- Create the trigger function
CREATE OR REPLACE FUNCTION fn_prevent_duplicate_vote()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the voter has already cast a vote
    IF EXISTS (
        SELECT 1 
        FROM Ballot 
        WHERE VoterID = NEW.VoterID
    ) THEN
        RAISE EXCEPTION 'Voter with ID % has already cast a vote. Multiple voting is not allowed.', NEW.VoterID;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trg_prevent_duplicate_vote
BEFORE INSERT ON Ballot
FOR EACH ROW
EXECUTE FUNCTION fn_prevent_duplicate_vote();

-- ============================================================================
-- Trigger: Auto-update result totals when ballot is inserted
-- This keeps the Result table synchronized with Ballot table
-- ============================================================================

-- Create the trigger function for insert
CREATE OR REPLACE FUNCTION fn_update_result_on_ballot_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- Only count valid ballots
    IF NEW.Validity = 'Valid' THEN
        UPDATE Result
        SET TotalVotes = TotalVotes + 1
        WHERE CandidateID = NEW.CandidateID;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trg_update_result_on_ballot_insert
AFTER INSERT ON Ballot
FOR EACH ROW
EXECUTE FUNCTION fn_update_result_on_ballot_insert();

-- ============================================================================
-- Trigger: Validate voter status before allowing vote
-- Ensures only active voters can cast ballots
-- ============================================================================

-- Create the trigger function
CREATE OR REPLACE FUNCTION fn_validate_voter_status()
RETURNS TRIGGER AS $$
DECLARE
    voter_status VARCHAR(20);
BEGIN
    -- Get the voter's status
    SELECT Status INTO voter_status
    FROM Voter
    WHERE VoterID = NEW.VoterID;
    
    -- Check if voter is active
    IF voter_status != 'Active' THEN
        RAISE EXCEPTION 'Voter with ID % has status "%" and cannot vote. Only Active voters are allowed.', 
            NEW.VoterID, voter_status;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trg_validate_voter_status
BEFORE INSERT ON Ballot
FOR EACH ROW
EXECUTE FUNCTION fn_validate_voter_status();

-- ============================================================================
-- Trigger: Log vote timestamp automatically
-- Ensures VoteDate is always set to current timestamp
-- ============================================================================

-- Create the trigger function
CREATE OR REPLACE FUNCTION fn_set_vote_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.VoteDate := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trg_set_vote_timestamp
BEFORE INSERT ON Ballot
FOR EACH ROW
EXECUTE FUNCTION fn_set_vote_timestamp();

-- ============================================================================
-- Triggers Creation Complete
-- ============================================================================

-- Test the duplicate vote prevention trigger
-- This should fail with an error message
-- Uncomment to test:
-- INSERT INTO Ballot (VoterID, CandidateID, Validity) VALUES (1, 1, 'Valid');
