-- ============================================================================
-- B9: Mini-Knowledge Base with Transitive Inference (≤10 facts)
-- ============================================================================
-- Creates a TRIPLE table for semantic facts and demonstrates transitive
-- inference using recursive queries for the Rwanda E-Voting domain.
-- ============================================================================

-- Drop existing table if it exists
DROP TABLE IF EXISTS TRIPLE CASCADE;

-- Create TRIPLE table for semantic facts (Subject-Predicate-Object)
CREATE TABLE TRIPLE (
    triple_id SERIAL PRIMARY KEY,
    s VARCHAR(64) NOT NULL,  -- Subject
    p VARCHAR(64) NOT NULL,  -- Predicate
    o VARCHAR(64) NOT NULL,  -- Object
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_triple UNIQUE (s, p, o)
);

-- Create indexes for efficient querying
CREATE INDEX idx_triple_subject ON TRIPLE(s);
CREATE INDEX idx_triple_predicate ON TRIPLE(p);
CREATE INDEX idx_triple_object ON TRIPLE(o);
CREATE INDEX idx_triple_sp ON TRIPLE(s, p);

-- Insert domain facts for Rwanda E-Voting system (8-10 facts)
-- These facts form a type hierarchy with transitive isA relationships

INSERT INTO TRIPLE (s, p, o) VALUES
    -- Election type hierarchy
    ('PresidentialElection', 'isA', 'NationalElection'),
    ('ParliamentaryElection', 'isA', 'NationalElection'),
    ('NationalElection', 'isA', 'Election'),
    ('LocalElection', 'isA', 'Election'),
    ('Election', 'isA', 'DemocraticProcess'),
    
    -- Participant hierarchy
    ('Candidate', 'isA', 'Voter'),
    ('Voter', 'isA', 'Citizen'),
    ('Citizen', 'isA', 'Person'),
    
    -- Additional domain fact
    ('ElectionOfficial', 'isA', 'Citizen');

-- Verify insertion
SELECT 
    COUNT(*) as total_facts,
    COUNT(DISTINCT s) as unique_subjects,
    COUNT(DISTINCT p) as unique_predicates,
    COUNT(DISTINCT o) as unique_objects
FROM TRIPLE;

-- Show all base facts
SELECT 
    triple_id,
    s || ' ' || p || ' ' || o as fact,
    s as subject,
    p as predicate,
    o as object
FROM TRIPLE
ORDER BY triple_id;

COMMENT ON TABLE TRIPLE IS 'Semantic triple store for e-voting domain knowledge';
COMMENT ON COLUMN TRIPLE.s IS 'Subject of the triple (entity)';
COMMENT ON COLUMN TRIPLE.p IS 'Predicate of the triple (relationship)';
COMMENT ON COLUMN TRIPLE.o IS 'Object of the triple (target entity)';
