-- ============================================================================
-- B9: Transitive Inference Queries
-- ============================================================================
-- Implements recursive queries for transitive closure of isA relationships
-- ============================================================================

-- ============================================================================
-- QUERY 1: Basic Transitive Closure (isA*)
-- ============================================================================
-- Computes all direct and inferred isA relationships using recursion

WITH RECURSIVE transitive_isa AS (
    -- Base case: Direct isA relationships
    SELECT 
        s as descendant,
        o as ancestor,
        1 as depth,
        s || ' → ' || o as path
    FROM TRIPLE
    WHERE p = 'isA'
    
    UNION ALL
    
    -- Recursive case: Transitive relationships
    -- If A isA B and B isA C, then A isA C
    SELECT 
        t.descendant,
        tr.o as ancestor,
        t.depth + 1 as depth,
        t.path || ' → ' || tr.o as path
    FROM transitive_isa t
    JOIN TRIPLE tr ON t.ancestor = tr.s AND tr.p = 'isA'
    WHERE t.depth < 10  -- Prevent infinite recursion
)
SELECT 
    descendant,
    ancestor,
    depth,
    path,
    CASE 
        WHEN depth = 1 THEN 'Direct'
        ELSE 'Inferred (depth ' || depth || ')'
    END as relationship_type
FROM transitive_isa
ORDER BY descendant, depth;

-- ============================================================================
-- QUERY 2: Labeled Entities with All Ancestors
-- ============================================================================
-- Shows each entity with all its ancestor types (labels)

WITH RECURSIVE transitive_isa AS (
    SELECT 
        s as entity,
        o as label,
        1 as depth
    FROM TRIPLE
    WHERE p = 'isA'
    
    UNION ALL
    
    SELECT 
        t.entity,
        tr.o as label,
        t.depth + 1
    FROM transitive_isa t
    JOIN TRIPLE tr ON t.label = tr.s AND tr.p = 'isA'
    WHERE t.depth < 10
)
SELECT 
    entity,
    label,
    depth,
    CASE 
        WHEN depth = 1 THEN '✓ Direct type'
        ELSE '✓ Inferred type (level ' || depth || ')'
    END as inference_note
FROM transitive_isa
ORDER BY entity, depth
LIMIT 10;

-- ============================================================================
-- QUERY 3: Entity Type Summary (Grouping Counts)
-- ============================================================================
-- Counts how many entities belong to each type (direct + inferred)

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
    COUNT(*) as total_relationships,
    ROUND(AVG(depth), 2) as avg_depth,
    STRING_AGG(DISTINCT entity, ', ' ORDER BY entity) as entities
FROM transitive_isa
GROUP BY label
ORDER BY entity_count DESC, type_label;

-- ============================================================================
-- QUERY 4: Full Type Hierarchy Tree
-- ============================================================================
-- Shows the complete type hierarchy with indentation

WITH RECURSIVE type_tree AS (
    -- Root nodes (entities that are not objects in any isA relationship)
    SELECT 
        s as entity,
        s as root,
        0 as level,
        s as path
    FROM TRIPLE
    WHERE p = 'isA' 
      AND s NOT IN (SELECT o FROM TRIPLE WHERE p = 'isA')
    
    UNION ALL
    
    -- Child nodes
    SELECT 
        tr.s as entity,
        tt.root,
        tt.level + 1 as level,
        tt.path || ' → ' || tr.s as path
    FROM type_tree tt
    JOIN TRIPLE tr ON tt.entity = tr.o AND tr.p = 'isA'
    WHERE tt.level < 10
)
SELECT 
    REPEAT('  ', level) || entity as hierarchy_tree,
    level,
    root as root_type,
    path
FROM type_tree
ORDER BY root, level, entity;

-- ============================================================================
-- QUERY 5: Consistency Validation
-- ============================================================================
-- Validates that inferred relationships are consistent

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
    'Total base facts' as metric,
    COUNT(*)::TEXT as value
FROM TRIPLE
WHERE p = 'isA'

UNION ALL

SELECT 
    'Total inferred relationships' as metric,
    COUNT(*)::TEXT as value
FROM (
    SELECT DISTINCT entity, label
    FROM transitive_isa
    WHERE depth > 1
) inferred

UNION ALL

SELECT 
    'Total relationships (direct + inferred)' as metric,
    COUNT(*)::TEXT as value
FROM (
    SELECT DISTINCT entity, label
    FROM transitive_isa
) all_rels

UNION ALL

SELECT 
    'Unique entities with types' as metric,
    COUNT(DISTINCT entity)::TEXT as value
FROM transitive_isa

UNION ALL

SELECT 
    'Maximum inference depth' as metric,
    MAX(depth)::TEXT as value
FROM transitive_isa;

-- ============================================================================
-- QUERY 6: Specific Entity Type Check
-- ============================================================================
-- Check what types a specific entity belongs to (example: PresidentialElection)

WITH RECURSIVE transitive_isa AS (
    SELECT s as entity, o as label, 1 as depth, s || ' isA ' || o as reasoning
    FROM TRIPLE WHERE p = 'isA'
    
    UNION ALL
    
    SELECT t.entity, tr.o as label, t.depth + 1, 
           t.reasoning || ' AND ' || t.label || ' isA ' || tr.o
    FROM transitive_isa t
    JOIN TRIPLE tr ON t.label = tr.s AND tr.p = 'isA'
    WHERE t.depth < 10
)
SELECT 
    entity,
    label as "is_a_type_of",
    depth,
    reasoning as "inference_chain"
FROM transitive_isa
WHERE entity = 'PresidentialElection'
ORDER BY depth;
