-- Database Triggers for Rwanda E-Voting System
-- Implements voting prevention and automatic result updates

-- ============================================
-- TRIGGER 1: Prevent Duplicate Voting
-- ============================================
-- This trigger prevents a voter from casting more than one vote
-- It checks if the voter has already voted before allowing a new vote

CREATE OR REPLACE FUNCTION prevent_duplicate_voting()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the voter has already voted
    IF EXISTS (
        SELECT 1 
        FROM Votes 
        WHERE VoterID = NEW.VoterID
    ) THEN
        RAISE EXCEPTION 'Voter with ID % has already cast a vote. Duplicate voting is not allowed.', NEW.VoterID;
    END IF;
    
    -- Check if the voter's HasVoted flag is already set to TRUE
    IF EXISTS (
        SELECT 1 
        FROM Voters 
        WHERE VoterID = NEW.VoterID 
        AND HasVoted = TRUE
    ) THEN
        RAISE EXCEPTION 'Voter with ID % is marked as having already voted.', NEW.VoterID;
    END IF;
    
    -- If all checks pass, allow the vote to be inserted
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the Votes table
DROP TRIGGER IF EXISTS trigger_prevent_duplicate_voting ON Votes;
CREATE TRIGGER trigger_prevent_duplicate_voting
    BEFORE INSERT ON Votes
    FOR EACH ROW
    EXECUTE FUNCTION prevent_duplicate_voting();

-- ============================================
-- TRIGGER 2: Update Voter Status After Voting
-- ============================================
-- Automatically updates the HasVoted flag in the Voters table
-- when a vote is successfully cast

CREATE OR REPLACE FUNCTION update_voter_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the HasVoted flag for the voter
    UPDATE Voters
    SET HasVoted = TRUE
    WHERE VoterID = NEW.VoterID;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the Votes table
DROP TRIGGER IF EXISTS trigger_update_voter_status ON Votes;
CREATE TRIGGER trigger_update_voter_status
    AFTER INSERT ON Votes
    FOR EACH ROW
    EXECUTE FUNCTION update_voter_status();

-- ============================================
-- TRIGGER 3: Update Results Table Automatically
-- ============================================
-- Automatically updates the Results table when a vote is cast
-- Increments vote count and recalculates percentages

CREATE OR REPLACE FUNCTION update_results_table()
RETURNS TRIGGER AS $$
DECLARE
    total_votes_in_constituency INT;
BEGIN
    -- Calculate total votes in the constituency
    SELECT COUNT(*) INTO total_votes_in_constituency
    FROM Votes
    WHERE ConstituencyID = NEW.ConstituencyID;
    
    -- Check if a result record exists for this candidate and constituency
    IF EXISTS (
        SELECT 1 
        FROM Results 
        WHERE CandidateID = NEW.CandidateID 
        AND ConstituencyID = NEW.ConstituencyID
    ) THEN
        -- Update existing result record
        UPDATE Results
        SET 
            TotalVotes = TotalVotes + 1,
            VotePercentage = ROUND(
                ((TotalVotes + 1)::DECIMAL / total_votes_in_constituency::DECIMAL) * 100, 
                2
            ),
            LastUpdated = CURRENT_TIMESTAMP
        WHERE 
            CandidateID = NEW.CandidateID 
            AND ConstituencyID = NEW.ConstituencyID;
    ELSE
        -- Insert new result record
        INSERT INTO Results (CandidateID, ConstituencyID, TotalVotes, VotePercentage, LastUpdated)
        VALUES (
            NEW.CandidateID,
            NEW.ConstituencyID,
            1,
            ROUND((1::DECIMAL / total_votes_in_constituency::DECIMAL) * 100, 2),
            CURRENT_TIMESTAMP
        );
    END IF;
    
    -- Recalculate percentages for all candidates in this constituency
    UPDATE Results
    SET 
        VotePercentage = ROUND(
            (TotalVotes::DECIMAL / total_votes_in_constituency::DECIMAL) * 100, 
            2
        ),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE ConstituencyID = NEW.ConstituencyID;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the Votes table
DROP TRIGGER IF EXISTS trigger_update_results ON Votes;
CREATE TRIGGER trigger_update_results
    AFTER INSERT ON Votes
    FOR EACH ROW
    EXECUTE FUNCTION update_results_table();

-- ============================================
-- TRIGGER 4: Validate Vote Constituency Match
-- ============================================
-- Ensures that a voter can only vote for candidates in their constituency

CREATE OR REPLACE FUNCTION validate_constituency_match()
RETURNS TRIGGER AS $$
DECLARE
    voter_constituency_id INT;
    candidate_constituency_id INT;
BEGIN
    -- Get the voter's constituency
    SELECT ConstituencyID INTO voter_constituency_id
    FROM Voters
    WHERE VoterID = NEW.VoterID;
    
    -- Get the candidate's constituency
    SELECT ConstituencyID INTO candidate_constituency_id
    FROM Candidates
    WHERE CandidateID = NEW.CandidateID;
    
    -- Check if they match
    IF voter_constituency_id != candidate_constituency_id THEN
        RAISE EXCEPTION 'Voter (ID: %) from constituency % cannot vote for candidate (ID: %) from constituency %',
            NEW.VoterID, voter_constituency_id, NEW.CandidateID, candidate_constituency_id;
    END IF;
    
    -- Also verify that the vote's constituency matches
    IF NEW.ConstituencyID != voter_constituency_id THEN
        RAISE EXCEPTION 'Vote constituency (%) does not match voter constituency (%)',
            NEW.ConstituencyID, voter_constituency_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the Votes table
DROP TRIGGER IF EXISTS trigger_validate_constituency ON Votes;
CREATE TRIGGER trigger_validate_constituency
    BEFORE INSERT ON Votes
    FOR EACH ROW
    EXECUTE FUNCTION validate_constituency_match();

-- ============================================
-- TRIGGER 5: Audit Trail for Vote Deletion
-- ============================================
-- Creates an audit log if votes are deleted (for security monitoring)

-- First, create an audit table
CREATE TABLE IF NOT EXISTS VoteAuditLog (
    AuditID SERIAL PRIMARY KEY,
    VoteID INT NOT NULL,
    VoterID INT NOT NULL,
    CandidateID INT NOT NULL,
    ConstituencyID INT NOT NULL,
    OriginalVoteTimestamp TIMESTAMP,
    DeletedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    DeletedBy VARCHAR(100) DEFAULT CURRENT_USER
);

CREATE OR REPLACE FUNCTION audit_vote_deletion()
RETURNS TRIGGER AS $$
BEGIN
    -- Log the deleted vote
    INSERT INTO VoteAuditLog (
        VoteID, 
        VoterID, 
        CandidateID, 
        ConstituencyID, 
        OriginalVoteTimestamp
    )
    VALUES (
        OLD.VoteID,
        OLD.VoterID,
        OLD.CandidateID,
        OLD.ConstituencyID,
        OLD.VoteTimestamp
    );
    
    -- Reset the voter's HasVoted status
    UPDATE Voters
    SET HasVoted = FALSE
    WHERE VoterID = OLD.VoterID;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger on the Votes table
DROP TRIGGER IF EXISTS trigger_audit_vote_deletion ON Votes;
CREATE TRIGGER trigger_audit_vote_deletion
    BEFORE DELETE ON Votes
    FOR EACH ROW
    EXECUTE FUNCTION audit_vote_deletion();

-- ============================================
-- Test Scenarios (commented out - uncomment to test)
-- ============================================

-- Test 1: Try to insert a valid vote
-- INSERT INTO Votes (VoterID, CandidateID, ConstituencyID) 
-- VALUES (1, 1, 1);

-- Test 2: Try to insert a duplicate vote (should fail)
-- INSERT INTO Votes (VoterID, CandidateID, ConstituencyID) 
-- VALUES (1, 2, 1);

-- Test 3: Try to vote for a candidate in a different constituency (should fail)
-- INSERT INTO Votes (VoterID, CandidateID, ConstituencyID) 
-- VALUES (2, 3, 1);  -- Assuming voter 2 is not in constituency 1

-- Test 4: Check if Results table is updated automatically
-- SELECT * FROM Results WHERE ConstituencyID = 1;

-- Test 5: Check if voter status is updated
-- SELECT VoterID, VoterName, HasVoted FROM Voters WHERE VoterID = 1;

-- Test 6: View audit log
-- SELECT * FROM VoteAuditLog;
