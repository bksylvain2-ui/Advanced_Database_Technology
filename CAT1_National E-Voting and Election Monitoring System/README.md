# E-Voting Database System for Rwanda

PostgreSQL database schema for a National E-Voting and Election Monitoring System, adapted for Rwanda's context.

## Database Setup

### Prerequisites
- PostgreSQL installed
- pgAdmin 4 installed

### Steps to Run

1. **Open pgAdmin 4** and connect to your PostgreSQL server

2. **Create the Database**
   ```sql
   CREATE DATABASE evotingdb;
   ```

3. **Run SQL Scripts in Order**
   - In pgAdmin 4, right-click on `evotingdb` → Query Tool
   - Execute each task file in sequence:
     - `task1_create_schema.sql` - Creates all tables
     - `task2_cascade_delete.sql` - Applies CASCADE DELETE
     - `task3_insert_mock_data.sql` - Inserts sample data
     - `task4_total_votes_per_candidate.sql` - Query votes
     - `task5_update_declared_results.sql` - Update results
     - `task6_winning_candidate_per_region.sql` - Find winners
     - `task7_create_party_vote_view.sql` - Create view
     - `task8_prevent_duplicate_vote_trigger.sql` - Create trigger

## Database Structure

### Tables
- **Party**: Political parties (RPF, PSD, PL)
- **Constituency**: Voting regions (Gasabo, Nyarugenge)
- **Voter**: Registered voters
- **Candidate**: Election candidates
- **Ballot**: Individual votes
- **Result**: Election results

### Relationships
- Constituency → Voter (1:N)
- Party → Candidate (1:N)
- Constituency → Candidate (1:N)
- Candidate → Ballot (1:N) with CASCADE DELETE
- Candidate → Result (1:1)

## File Structure

Each task has its own SQL file:

- **task1_create_schema.sql** - Build schema with PK, FK, and domain constraints
- **task2_cascade_delete.sql** - Apply CASCADE DELETE from Candidate → Ballot
- **task3_insert_mock_data.sql** - Insert mock data (3 parties, 2 constituencies)
- **task4_total_votes_per_candidate.sql** - Retrieve total votes per candidate per constituency
- **task5_update_declared_results.sql** - Update declared results after tally
- **task6_winning_candidate_per_region.sql** - Identify winning candidate per region
- **task7_create_party_vote_view.sql** - Create view summarizing total votes per party
- **task8_prevent_duplicate_vote_trigger.sql** - Implement trigger preventing duplicate votes

## Features Implemented

✅ Primary Keys, Foreign Keys, and Domain Constraints  
✅ CASCADE DELETE from Candidate to Ballot  
✅ Sample Rwandan data (3 parties, 2 constituencies)  
✅ Queries for vote totals per candidate/constituency  
✅ Result update mechanism  
✅ Winning candidate identification per region  
✅ View for party vote summary  
✅ Trigger preventing duplicate votes

## Sample Queries

### View Party Vote Summary
```sql
SELECT * FROM PartyVoteSummary;
```

### Check Winning Candidates
Run `task6_winning_candidate_per_region.sql`

### Test Duplicate Vote Prevention
```sql
-- This should fail (voter already voted)
INSERT INTO Ballot (VoterID, CandidateID, VoteDate, Validity) 
VALUES (1, 2, CURRENT_TIMESTAMP, 'Valid');
```

## Notes

- All syntax is PostgreSQL compatible
- Uses Rwandan context (names, constituencies, parties)
- Beginner-friendly with clear comments
- Includes data validation constraints


