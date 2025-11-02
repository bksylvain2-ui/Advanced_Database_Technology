# Task 8: Three-Tier Client-Server Architecture Design

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    TIER 1: PRESENTATION LAYER                    │
│                    (Client / Frontend)                            │
├─────────────────────────────────────────────────────────────────┤
│  • Web Browser / Mobile App                                     │
│  • User Interface (HTML/CSS/JavaScript)                          │
│  • React/Vue/Angular Application                                 │
│  • Displays:                                                     │
│    - Voter registration                                          │
│    - Candidate information                                       │
│    - Voting interface                                            │
│    - Election results                                            │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTP/HTTPS
                             │ REST API / GraphQL
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  TIER 2: APPLICATION LAYER                       │
│              (Business Logic / Middleware)                        │
├─────────────────────────────────────────────────────────────────┤
│  • Application Server (Node.js / Python / Java)                 │
│  • API Gateway / REST Services                                  │
│  • Business Logic:                                              │
│    - Vote validation                                             │
│    - Duplicate vote prevention                                   │
│    - Election result calculation                                 │
│    - Authentication & Authorization                              │
│  • Database Connection Pool                                     │
│  • Transaction Management                                        │
│  • Security & Rate Limiting                                      │
└────────────────────────────┬────────────────────────────────────┘
                             │ SQL Queries
                             │ PostgreSQL Protocol
                             │ FDW Connections
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    TIER 3: DATABASE LAYER                        │
│                      (Data Storage)                               │
├─────────────────────────────────────────────────────────────────┤
│  PostgreSQL Database: evotingdb                                 │
│  ┌──────────────────────┐  ┌──────────────────────┐            │
│  │   Node A Schema      │  │   Node B Schema      │            │
│  │  (Gasabo District)   │  │ (Nyarugenge District)│            │
│  │                      │  │                      │            │
│  │ • Voter              │  │ • Voter              │            │
│  │ • Candidate          │◄─┼─│ • Candidate          │            │
│  │ • Ballot             │FDW│ • Ballot             │            │
│  │ • Party              │  │ • Party              │            │
│  │ • Constituency       │  │ • Constituency       │            │
│  └──────────────────────┘  └──────────────────────┘            │
│                                                                    │
│  • Foreign Data Wrapper (FDW) connections                        │
│  • Two-Phase Commit for distributed transactions                │
│  • Parallel query execution                                     │
│  • Replication & Backup                                           │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow Example: Casting a Vote

### Step 1: User Input (Presentation Layer)
```
User submits vote through web interface
  ↓
POST /api/votes
  {
    "voterID": 1,
    "candidateID": 1,
    "constituencyID": 1
  }
```

### Step 2: Business Logic (Application Layer)
```
API Endpoint: /api/votes
  ↓
1. Validate voter eligibility
2. Check for duplicate votes (using trigger)
3. Begin transaction
4. Insert vote into appropriate node based on constituency
5. Update election results
6. Commit transaction
  ↓
Return success/failure response to client
```

### Step 3: Database Operations (Database Layer)
```
Application Layer sends SQL:
  BEGIN;
  INSERT INTO evotingdb_nodeA.Ballot (...) VALUES (...);
  
  PREPARE TRANSACTION 'vote_tx_001';
  COMMIT PREPARED 'vote_tx_001';
  
  Trigger fires: prevent_duplicate_vote()
    ↓
  Success: Vote recorded
  Failure: Rollback and return error
```

## Technology Stack

### Presentation Layer
- **Frontend Framework**: React / Vue.js / Angular
- **UI Components**: Material-UI / Bootstrap
- **State Management**: Redux / Vuex
- **Communication**: HTTP/REST API, WebSockets for real-time updates

### Application Layer
- **Runtime**: Node.js / Python (Django/FastAPI) / Java (Spring Boot)
- **API Framework**: Express.js / FastAPI / Spring REST
- **Database Driver**: pg (Node.js) / psycopg2 (Python) / JDBC (Java)
- **Connection Pooling**: pg-pool / SQLAlchemy / HikariCP
- **Security**: JWT Authentication, Rate Limiting, Input Validation

### Database Layer
- **RDBMS**: PostgreSQL 14+
- **FDW Extension**: postgres_fdw
- **Connection Method**: TCP/IP, SSL/TLS encrypted
- **Transaction Management**: Two-Phase Commit (PREPARE TRANSACTION)
- **Replication**: Streaming Replication (for high availability)

## Distributed Architecture Benefits

1. **Scalability**: 
   - Horizontal fragmentation distributes data across nodes
   - Parallel query execution improves performance
   - Load balancing across application servers

2. **Reliability**:
   - Two-phase commit ensures data consistency
   - Automatic failover and recovery mechanisms
   - Transaction rollback prevents partial updates

3. **Performance**:
   - Data locality (queries run closer to data)
   - Parallel processing reduces query time
   - Connection pooling reduces overhead

4. **Security**:
   - Separation of concerns (tiers isolated)
   - Database credentials not exposed to clients
   - Encryption in transit (HTTPS, SSL/TLS)

## Database Link Integration (FDW)

```
Application Server
  ↓
Connection Pool
  ↓
PostgreSQL Client (Node A)
  ↓
FDW Connection ───┐
  ↓               │
Node A Tables     │ Query
  ↓               │ Remote Tables
Join Query ──────┘
  ↓
Node B Tables (via FDW)
  ↓
Return Results
```

## Example Code Structure

### Presentation Layer (React)
```javascript
// VoteForm.jsx
async function castVote(voterID, candidateID) {
  const response = await fetch('/api/votes', {
    method: 'POST',
    body: JSON.stringify({ voterID, candidateID })
  });
  return response.json();
}
```

### Application Layer (Node.js/Express)
```javascript
// routes/votes.js
app.post('/api/votes', async (req, res) => {
  const { voterID, candidateID } = req.body;
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    await client.query(
      'INSERT INTO Ballot (VoterID, CandidateID) VALUES ($1, $2)',
      [voterID, candidateID]
    );
    await client.query('COMMIT');
    res.json({ success: true });
  } catch (error) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
});
```

### Database Layer (PostgreSQL)
```sql
-- Trigger prevents duplicate votes
CREATE TRIGGER check_duplicate_vote
BEFORE INSERT ON Ballot
FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_vote();
```

## Summary

This three-tier architecture provides:
- **Clear Separation**: Each tier has distinct responsibilities
- **Scalability**: Easy to scale individual tiers independently
- **Maintainability**: Changes in one tier don't affect others
- **Security**: Database credentials and logic protected in middle tier
- **Distributed Processing**: FDW enables seamless cross-node queries
- **Fault Tolerance**: Two-phase commit ensures atomicity across nodes


