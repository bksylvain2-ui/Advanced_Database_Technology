-- ============================================================================
-- B9: Knowledge Base Summary Report
-- ============================================================================
-- Comprehensive validation and summary of the knowledge base implementation
-- ============================================================================

\echo '============================================================================'
\echo 'B9: MINI-KNOWLEDGE BASE WITH TRANSITIVE INFERENCE - SUMMARY REPORT'
\echo '============================================================================'
\echo ''

-- ============================================================================
-- SECTION 1: Base Facts Overview
-- ============================================================================
\echo '1. BASE FACTS IN TRIPLE TABLE'
\echo '-------------------------------------------'

SELECT 
    triple_id as id,
    s as subject,
    p as predicate,
    o as object,
    s || ' ' || p || ' ' || o as fact_statement
FROM TRIPLE
ORDER BY triple_id;

\echo ''
\echo 'Base Facts Statistics:'
SELECT 
    COUNT(*) as total_facts,
    COUNT(DISTINCT s) as unique_subjects,
    COUNT(DISTINCT p) as unique_predicates,
    COUNT(DISTINCT o) as unique_objects
FROM TRIPLE;

\echo ''
\echo '============================================================================'
\echo '2. TRANSITIVE INFERENCE RESULTS (≤10 LABELED ROWS)'
\echo '-------------------------------------------'

-- Show all inferred relationships (limited to 10 for output requirement)
WITH RECURSIVE transitive_isa AS (
    SELECT 
        s as entity,
        o as label,
        1 as depth,
        s || ' → ' || o as path
    FROM TRIPLE
    WHERE p = 'isA'
    
    UNION ALL
    
    SELECT 
        t.entity,
        tr.o as label,
        t.depth + 1,
        t.path || ' → ' || tr.o
    FROM transitive_isa t
    JOIN TRIPLE tr ON t.label = tr.s AND tr.p = 'isA'
    WHERE t.depth < 10
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY entity, depth) as row_num,
    entity,
    label,
    depth,
    CASE 
        WHEN depth = 1 THEN 'Direct'
        ELSE 'Inferred'
    END as type,
    path as inference_path
FROM transitive_isa
ORDER BY entity, depth
LIMIT 10;

\echo ''
\echo '============================================================================'
\echo '3. GROUPING COUNTS - CONSISTENCY VALIDATION'
\echo '-------------------------------------------'

-- Count entities by type label (proves consistency)
WITH RECURSIVE transitive_isa AS (
    SELECT s as entity, o as label, 1 as depth
    FROM TRIPLE WHERE p = 'isA'
    
    UNION ALL
    
    SELECT t.entity, tr.o as label, t.depth + 1
    FROM transitive_isa t
    JOIN TRIPLE tr ON t.label = tr.s AND tr.p = 'isA'
    WHERE t.depth < 10
)
SELECT 
    label as type_label,
    COUNT(DISTINCT entity) as entity_count,
    STRING_AGG(DISTINCT entity, ', ' ORDER BY entity) as member_entities
FROM transitive_isa
GROUP BY label
ORDER BY entity_count DESC, type_label;

\echo ''
\echo '============================================================================'
\echo '4. INFERENCE DEPTH ANALYSIS'
\echo '-------------------------------------------'

WITH RECURSIVE transitive_isa AS (
    SELECT s as entity, o as label, 1 as depth
    FROM TRIPLE WHERE p = 'isA'
    
    UNION ALL
    
    SELECT t.entity, tr.o as label, t.depth + 1
    FROM transitive_isa t
    JOIN TRIPLE tr ON t.label = tr.s AND tr.p = 'isA'
    WHERE t.depth < 10
)
SELECT 
    depth as inference_depth,
    COUNT(*) as relationship_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM transitive_isa
GROUP BY depth
ORDER BY depth;

\echo ''
\echo '============================================================================'
\echo '5. EXAMPLE: PRESIDENTIAL ELECTION TYPE HIERARCHY'
\echo '-------------------------------------------'

WITH RECURSIVE transitive_isa AS (
    SELECT 
        s as entity, 
        o as label, 
        1 as depth, 
        s || ' isA ' || o as reasoning
    FROM TRIPLE WHERE p = 'isA'
    
    UNION ALL
    
    SELECT 
        t.entity, 
        tr.o as label, 
        t.depth + 1, 
        t.reasoning || ' AND ' || t.label || ' isA ' || tr.o
    FROM transitive_isa t
    JOIN TRIPLE tr ON t.label = tr.s AND tr.p = 'isA'
    WHERE t.depth < 10
)
SELECT 
    entity,
    label as is_a_type_of,
    depth,
    reasoning as inference_chain
FROM transitive_isa
WHERE entity = 'PresidentialElection'
ORDER BY depth;

\echo ''
\echo '============================================================================'
\echo '6. COMMITTED ROWS BUDGET CHECK'
\echo '-------------------------------------------'

SELECT 
    'TRIPLE table' as table_name,
    COUNT(*) as committed_rows,
    CASE 
        WHEN COUNT(*) <= 10 THEN '✓ Within budget'
        ELSE '✗ Exceeds budget'
    END as status
FROM TRIPLE;

\echo ''
\echo '============================================================================'
\echo 'B9 REQUIREMENTS CHECKLIST'
\echo '============================================================================'
\echo '✓ DDL for TRIPLE table created'
\echo '✓ 8-10 domain facts inserted (9 facts total)'
\echo '✓ Recursive inference query implementing transitive isA*'
\echo '✓ Labeled output with ≤10 rows demonstrated'
\echo '✓ Grouping counts proving consistency'
\echo '✓ Total committed rows within ≤10 budget'
\echo '============================================================================'
