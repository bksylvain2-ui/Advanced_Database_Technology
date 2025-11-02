# E-Voting Database System for Rwanda

PostgreSQL database schema for a National E-Voting and Election Monitoring System, adapted for Rwanda's context.

## Database Setup

### Prerequisites
- PostgreSQL installed
- pgAdmin 4 installed

### Assignment 3: Distributed and Parallel Database Management

Advanced database management concepts covering distributed and parallel processing, transaction management, and performance optimization.

**📁 Location**: All tasks are in the `Assignment 3/` directory

**🔗 Detailed Guide**: See `Assignment 3/README.md` for comprehensive documentation

#### Overview

Assignment 3 demonstrates 10 advanced database management tasks:

1. **Distributed Database Design**
   - Schema fragmentation across multiple nodes
   - Database links and distributed queries
   - Cross-node data access and joins

2. **Parallel Processing**
   - Parallel query execution
   - Parallel data loading and ETL
   - Performance optimization

3. **Transaction Management**
   - Two-phase commit protocol
   - Distributed rollback and recovery
   - Transaction atomicity across nodes

4. **Concurrency Control**
   - Lock management across distributed nodes
   - Deadlock prevention
   - Concurrent update handling

5. **Performance Analysis**
   - Query optimization strategies
   - Performance benchmarking
   - Centralized vs Parallel vs Distributed comparison

#### Task List

| Task | File | Description | Key Concepts |
|------|------|-------------|--------------|
| 1 | `task1_distributed_schema_fragmentation.sql` | Horizontal fragmentation | Node A (Gasabo), Node B (Nyarugenge), Schema splitting |
| 2 | `task2_database_links_fdw.sql` | Database links using FDW | Foreign Data Wrapper, Remote queries, Cross-node joins |
| 3 | `task3_parallel_query_execution.sql` | Parallel query execution | Workers, Parallel scans, Performance comparison |
| 4 | `task4_two_phase_commit.sql` | Two-phase commit | Transaction atomicity, SAVEPOINT, Prepared transactions |
| 5 | `task5_distributed_rollback_recovery.sql` | Distributed rollback | Transaction failure, Recovery procedures, Data consistency |
| 6 | `task6_distributed_concurrency_control.sql` | Concurrency control | Lock management, pg_locks, Deadlock prevention |
| 7 | `task7_parallel_data_loading.sql` | Parallel ETL | Bulk loading, Staging tables, Parallel INSERT |
| 8 | `task8_three_tier_architecture.md` | Architecture design | Presentation, Application, Database tiers |
| 9 | `task9_distributed_query_optimization.sql` | Query optimization | Index creation, EXPLAIN PLAN, Optimization strategies |
| 10 | `task10_performance_benchmark.sql` | Performance comparison | Centralized vs Parallel vs Distributed modes |

#### Prerequisites

Before running Assignment 3:

1. **Complete Basic Tasks First**:
   - `task1_create_schema.sql` - Creates all base tables
   - `task3_insert_mock_data.sql` - Inserts sample data

2. **PostgreSQL Setup**:
   - PostgreSQL 9.6+ installed
   - pgAdmin 4 installed
   - Database `evotingdb` created

3. **Optional Extensions** (some tasks):
   - `postgres_fdw` - For Foreign Data Wrapper (Task 2)
   - `pg_stat_statements` - For query statistics (Task 9, optional)

#### Execution Order

**⚠️ IMPORTANT**: Run tasks sequentially (1 → 2 → 3 → ... → 10) as they build upon each other.

```sql
-- Step 1: Complete basic tasks (from main directory)
-- Execute: task1_create_schema.sql
-- Execute: task3_insert_mock_data.sql

-- Step 2: Execute Assignment 3 tasks in order
-- Navigate to Assignment 3/ directory in pgAdmin 4

-- 1. Create distributed schema fragments
Execute: task1_distributed_schema_fragmentation.sql

-- 2. Set up database links (FDW)
Execute: task2_database_links_fdw.sql

-- 3. Enable parallel query execution
Execute: task3_parallel_query_execution.sql

-- 4. Demonstrate two-phase commit
Execute: task4_two_phase_commit.sql

-- 5. Test distributed rollback and recovery
Execute: task5_distributed_rollback_recovery.sql

-- 6. Manage distributed concurrency control
Execute: task6_distributed_concurrency_control.sql

-- 7. Perform parallel data loading
Execute: task7_parallel_data_loading.sql

-- 8. Review three-tier architecture
Open: task8_three_tier_architecture.md (markdown file)

-- 9. Optimize distributed queries
Execute: task9_distributed_query_optimization.sql

-- 10. Benchmark performance
Execute: task10_performance_benchmark.sql
```

#### Key Concepts Covered

**Distributed Database**:
- Horizontal fragmentation across nodes
- Database links and remote access
- Distributed transaction coordination
- Cross-node query optimization

**Parallel Processing**:
- Parallel query execution with multiple workers
- Parallel data loading and ETL operations
- Performance tuning and optimization
- Scalability analysis

**Transaction Management**:
- Two-phase commit (2PC) protocol
- Distributed rollback procedures
- Transaction recovery mechanisms
- Atomicity guarantees

**Concurrency Control**:
- Lock management across nodes
- Deadlock detection and prevention
- Concurrent update handling
- Isolation levels

#### Verification

After completing all tasks:

1. **Quick Verification** (`quick_verification_queries.sql`):
   - Fast one-line checks for each task
   - Summary report at the end
   - Recommended for quick status check

2. **Comprehensive Verification** (`verify_assignment3_tasks.sql`):
   - Detailed verification for each task
   - Schema and table verification
   - Performance metrics
   - Complete summary report

#### Sample Queries

**View Data from Both Nodes**:
```sql
-- View parties from both distributed nodes
SELECT 'Node A' AS Node, * FROM evotingdb_nodeA.Party
UNION ALL
SELECT 'Node B' AS Node, * FROM evotingdb_nodeB.Party;
```

**Check Parallel Execution**:
```sql
-- Enable parallel execution
SET max_parallel_workers_per_gather = 4;

-- Check if parallel workers are used
EXPLAIN (ANALYZE, TIMING)
SELECT COUNT(*) FROM Ballot;
-- Look for "Workers Launched: X" in output
```

**Distributed Join Query**:
```sql
-- Cross-node join example
SELECT 
    a.FullName AS CandidateA,
    b.FullName AS CandidateB,
    a.ConstituencyID
FROM evotingdb_nodeA.Candidate a
INNER JOIN evotingdb_nodeB.Candidate b 
    ON a.ConstituencyID = b.ConstituencyID;
```

#### Common Issues

**Issue**: "prepared transactions are disabled"
- **Solution**: Tasks 4 and 5 use `SAVEPOINT` approach by default (works without config)

**Issue**: "column tablename does not exist"
- **Solution**: Use `relname` instead of `tablename` in `pg_stat_user_tables` queries (already fixed)

**Issue**: "server does not exist" (FDW)
- **Solution**: Task 2 uses direct schema queries by default (no FDW needed)

**Issue**: "Voter has already cast a vote"
- **Solution**: Task 7 uses 'Invalid' votes to avoid trigger conflicts (expected behavior)

For more details, see `Assignment 3/README.md`

## Features Implemented

### Basic Features (Tasks 1-8)
✅ Primary Keys, Foreign Keys, and Domain Constraints  
✅ CASCADE DELETE from Candidate to Ballot  
✅ Sample Rwandan data (3 parties, 2 constituencies)  
✅ Queries for vote totals per candidate/constituency  
✅ Result update mechanism  
✅ Winning candidate identification per region  
✅ View for party vote summary  
✅ Trigger preventing duplicate votes

### Advanced Features (Assignment 3)
✅ **Distributed Database Design**
  - Horizontal fragmentation across Node A and Node B
  - Database links using Foreign Data Wrapper (FDW)
  - Cross-node queries and distributed joins
  - Schema-based fragmentation (Gasabo & Nyarugenge districts)

✅ **Parallel Processing**
  - Parallel query execution with multiple workers
  - Parallel data loading and ETL operations
  - Performance optimization strategies
  - Scalability analysis and benchmarking

✅ **Transaction Management**
  - Two-phase commit (2PC) protocol simulation
  - Distributed rollback and recovery procedures
  - Transaction atomicity across nodes
  - Savepoint-based transaction control

✅ **Concurrency Control**
  - Lock management across distributed nodes
  - Deadlock detection and prevention
  - Concurrent update handling
  - System lock queries (pg_locks)

✅ **Performance Optimization**
  - Query optimization with EXPLAIN ANALYZE
  - Index creation and utilization
  - Performance benchmarking (Centralized/Parallel/Distributed)
  - Query statistics and metrics

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

