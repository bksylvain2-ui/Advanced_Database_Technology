# Intelligence Databases - Debugging SQL codes

## Project Overview
This folder contains solutions for the Intelligent Databases topic, focusing on using declarative constraints as the database’s primary method for ensuring the validity of prescriptions before any application code executes. The assignment addresses the following questions:
(1) debugging the declarative constraints,
(2)active databases, 
(3) deductive databases, 
(4) knowledge bases, and 
(5) spatial databases.
  
## One by one solving the questions 
### 1) Rules (Declarative Constraints): Safe Prescriptions
**Objective**: Implement declarative constraints as the database's first line of defense for prescription validation.

**Features**:
- Non-negative dosing constraints
- Mandatory field enforcement
- Referential integrity to PATIENT table
- Sensible date logic (start date not after end date)
- Compiling table definition that rejects bad rows at insert time

### 2) Active Databases (E-C-A Trigger): Bill Totals That Stay Correct
**Objective**: Practice Event-Condition-Action logic to maintain derived totals automatically using statement-level triggers.

**Features**:
- Statement-level trigger `TRG_BILL_TOTAL_STMT`
- Avoids mutating-table issues
- Single computation per bill ID
- Audit trail in `BILL_AUDIT` table
- Handles INSERT/UPDATE/DELETE operations efficiently

### 3) Deductive Databases (Recursive WITH): Referral/Supervision Chain
**Objective**: Use recursive subquery factoring to derive supervision hierarchies from atomic facts.

**Features**:
- Computes employee's top supervisor and hop count
- Gracefully handles cycles in supervision chains
- Proper join directions and hop counter implementation
- Cycle detection using Oracle's built-in CYCLE clause

### 4) Knowledge Bases (Triples & Ontology): Infectious-Disease Roll-Up
**Objective**: Demonstrate ontology-aware querying using triples and transitive closure.

**Features**:
- Triple store implementation with subject-predicate-object model
- Transitive closure computation for 'isA' relationships
- Patient diagnosis classification using ontology hierarchy
- Fixed directionality errors in recursive queries

### 5) Spatial Databases (Geography & Distance): Radius & Nearest-3
**Objective**: Apply spatial reasoning for clinic location queries using Oracle Spatial.

**Features**:
- Clinic locations stored with proper WGS84 SRID (4326)
- Spatial indexing for performance optimization
- Radius queries within 1 km distance
- Nearest-neighbor queries with distance calculations
- Correct coordinate order (longitude, latitude) and unit specifications

## Conclusion
- It has been created for educational purposes to facilitate learning and understanding of the concepts.
