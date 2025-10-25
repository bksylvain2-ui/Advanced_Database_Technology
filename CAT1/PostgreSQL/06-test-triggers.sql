-- ============================================================================
-- Script 06: Test Triggers and Constraints
-- ============================================================================
-- Test 1: Attempt to insert duplicate vote (should fail)
-- ============================================================================
DO $$
BEGIN
    BEGIN
        INSERT INTO Ballot (VoterID, CandidateID, Validity) 
        VALUES (1, 1, 'Valid');
        
        RAISE NOTICE 'ERROR: Duplicate vote was allowed! Trigger failed.';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'SUCCESS: Duplicate vote prevented. Error message: %', SQLERRM;
    END;
END $$;

-- ============================================================================
-- Test 2: Attempt to vote with inactive voter (should fail)
-- ============================================================================

-- First, create an inactive voter for testing
INSERT INTO Voter (FullName, NationalID, Gender, ConstituencyID, Status) 
VALUES ('Test Inactive User', '1199999999999999', 'M', 1, 'Inactive');

DO $$
DECLARE
    inactive_voter_id INTEGER;
BEGIN
    -- Get the inactive voter ID
    SELECT VoterID INTO inactive_voter_id 
    FROM Voter 
    WHERE NationalID = '1199999999999999';
    
    BEGIN
        INSERT INTO Ballot (VoterID, CandidateID, Validity) 
        VALUES (inactive_voter_id, 1, 'Valid');
        
        RAISE NOTICE 'ERROR: Inactive voter was allowed to vote! Trigger failed.';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'SUCCESS: Inactive voter prevented from voting. Error message: %', SQLERRM;
    END;
END $$;

-- Clean up test data
DELETE FROM Voter WHERE NationalID = '1199999999999999';

-- ============================================================================
-- Test 3: Verify auto-update of results when new ballot is inserted
-- ============================================================================

-- Check current result for candidate 1
SELECT 
    c.FullName AS Candidate,
    r.TotalVotes AS VotesBeforeTest
FROM Result r
INNER JOIN Candidate c ON r.CandidateID = c.CandidateID
WHERE c.CandidateID = 1;

-- Insert a new voter and have them vote
INSERT INTO Voter (FullName, NationalID, Gender, ConstituencyID, Status) 
VALUES ('Test New Voter', '1199888888888888', 'F', 1, 'Active');

-- Get the new voter's ID and cast a vote
DO $$
DECLARE
    new_voter_id INTEGER;
    votes_before INTEGER;
    votes_after INTEGER;
BEGIN
    SELECT VoterID INTO new_voter_id 
    FROM Voter 
    WHERE NationalID = '1199888888888888';
    
    -- Get votes before
    SELECT TotalVotes INTO votes_before 
    FROM Result 
    WHERE CandidateID = 1;
    
    -- Cast vote
    INSERT INTO Ballot (VoterID, CandidateID, Validity) 
    VALUES (new_voter_id, 1, 'Valid');
    
    -- Get votes after
    SELECT TotalVotes INTO votes_after 
    FROM Result 
    WHERE CandidateID = 1;
    
    IF votes_after = votes_before + 1 THEN
        RAISE NOTICE 'SUCCESS: Result auto-updated. Votes before: %, Votes after: %', votes_before, votes_after;
    ELSE
        RAISE NOTICE 'ERROR: Result not updated correctly. Votes before: %, Votes after: %', votes_before, votes_after;
    END IF;
END $$;

-- Clean up test data
DELETE FROM Ballot WHERE VoterID = (SELECT VoterID FROM Voter WHERE NationalID = '1199888888888888');
DELETE FROM Voter WHERE NationalID = '1199888888888888';

-- ============================================================================
-- Test 4: Verify CASCADE DELETE from Candidate to Ballot
-- ============================================================================

-- Create a test candidate
INSERT INTO Candidate (PartyID, ConstituencyID, FullName, Manifesto) 
VALUES (1, 1, 'Test Candidate For Deletion', 'Test manifesto');

-- Get the test candidate ID
DO $$
DECLARE
    test_candidate_id INTEGER;
    test_voter_id INTEGER;
    ballots_before INTEGER;
    ballots_after INTEGER;
BEGIN
    SELECT CandidateID INTO test_candidate_id 
    FROM Candidate 
    WHERE FullName = 'Test Candidate For Deletion';
    
    -- Create a test voter
    INSERT INTO Voter (FullName, NationalID, Gender, ConstituencyID, Status) 
    VALUES ('Test Voter For Cascade', '1199777777777777', 'M', 1, 'Active');
    
    SELECT VoterID INTO test_voter_id 
    FROM Voter 
    WHERE NationalID = '1199777777777777';
    
    -- Cast a vote for the test candidate
    INSERT INTO Ballot (VoterID, CandidateID, Validity) 
    VALUES (test_voter_id, test_candidate_id, 'Valid');
    
    -- Count ballots before deletion
    SELECT COUNT(*) INTO ballots_before 
    FROM Ballot 
    WHERE CandidateID = test_candidate_id;
    
    -- Delete the candidate (should cascade to ballot)
    DELETE FROM Candidate WHERE CandidateID = test_candidate_id;
    
    -- Count ballots after deletion
    SELECT COUNT(*) INTO ballots_after 
    FROM Ballot 
    WHERE CandidateID = test_candidate_id;
    
    IF ballots_before > 0 AND ballots_after = 0 THEN
        RAISE NOTICE 'SUCCESS: CASCADE DELETE working. Ballots before: %, Ballots after: %', ballots_before, ballots_after;
    ELSE
        RAISE NOTICE 'ERROR: CASCADE DELETE not working. Ballots before: %, Ballots after: %', ballots_before, ballots_after;
    END IF;
    
    -- Clean up test voter
    DELETE FROM Voter WHERE VoterID = test_voter_id;
END $$;

-- ============================================================================
-- Trigger Tests Complete
-- ============================================================================
