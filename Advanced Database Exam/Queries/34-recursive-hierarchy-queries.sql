-- ============================================================================
-- B8: Recursive Hierarchy Queries with Vote Roll-Ups
-- ============================================================================
-- Demonstrates recursive WITH queries to traverse hierarchy and compute
-- vote aggregations at each level.
-- ============================================================================

-- ============================================================================
-- 1. BASIC RECURSIVE HIERARCHY TRAVERSAL
-- ============================================================================
-- Produces (child_id, root_id, depth) for all nodes

WITH RECURSIVE HierarchyPath AS (
    -- Base case: Start with root nodes (Country level)
    SELECT 
        node_id AS child_id,
        node_id AS root_id,
        node_name AS child_name,
        node_name AS root_name,
        0 AS depth,
        node_name AS path
    FROM HIER
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Recursive case: Find children
    SELECT 
        h.node_id AS child_id,
        hp.root_id,
        h.node_name AS child_name,
        hp.root_name,
        hp.depth + 1 AS depth,
        hp.path || ' → ' || h.node_name AS path
    FROM HIER h
    INNER JOIN HierarchyPath hp ON h.parent_id = hp.child_id
)
SELECT 
    child_id,
    child_name,
    root_id,
    root_name,
    depth,
    path AS hierarchy_path
FROM HierarchyPath
ORDER BY depth, child_id;

-- ============================================================================
-- 2. HIERARCHY WITH VOTE ROLL-UPS
-- ============================================================================
-- Join hierarchy to Constituencies and aggregate votes by hierarchy level

-- First, create a mapping between Districts and Constituencies
-- (Using Province from Constituencies table to match with HIER)

WITH RECURSIVE HierarchyPath AS (
    -- Base case: Root nodes
    SELECT 
        node_id AS child_id,
        node_id AS root_id,
        node_name AS child_name,
        0 AS depth
    FROM HIER
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Recursive case
    SELECT 
        h.node_id AS child_id,
        hp.root_id,
        h.node_name AS child_name,
        hp.depth + 1 AS depth
    FROM HIER h
    INNER JOIN HierarchyPath hp ON h.parent_id = hp.child_id
),
VotesByHierarchy AS (
    -- Aggregate votes by matching Province names
    SELECT 
        hp.child_id,
        hp.child_name,
        hp.root_id,
        hp.depth,
        COUNT(DISTINCT c.ConstituencyID) AS constituency_count,
        COUNT(v.VoteID) AS total_votes,
        COUNT(DISTINCT v.VoterID) AS unique_voters
    FROM HierarchyPath hp
    LEFT JOIN Constituencies c ON c.Province LIKE '%' || hp.child_name || '%'
    LEFT JOIN Votes v ON v.ConstituencyID = c.ConstituencyID
    GROUP BY hp.child_id, hp.child_name, hp.root_id, hp.depth
)
SELECT 
    child_id,
    child_name AS administrative_unit,
    depth AS hierarchy_level,
    constituency_count,
    total_votes,
    unique_voters,
    CASE 
        WHEN constituency_count > 0 
        THEN ROUND(total_votes::NUMERIC / constituency_count, 2)
        ELSE 0 
    END AS avg_votes_per_constituency
FROM VotesByHierarchy
ORDER BY depth, child_id;

-- ============================================================================
-- 3. HIERARCHICAL VOTE ROLL-UP WITH SUBTOTALS
-- ============================================================================
-- Shows votes at each level with cumulative totals up the hierarchy

WITH RECURSIVE HierarchyRollup AS (
    -- Base case: Leaf nodes (Districts)
    SELECT 
        h.node_id,
        h.node_name,
        h.parent_id,
        h.node_level,
        0 AS depth,
        COALESCE(SUM(r.TotalVotes), 0) AS direct_votes,
        COALESCE(SUM(r.TotalVotes), 0) AS total_votes_with_children
    FROM HIER h
    LEFT JOIN Constituencies c ON c.Province LIKE '%' || h.node_name || '%'
    LEFT JOIN Results r ON r.ConstituencyID = c.ConstituencyID
    WHERE NOT EXISTS (SELECT 1 FROM HIER child WHERE child.parent_id = h.node_id)
    GROUP BY h.node_id, h.node_name, h.parent_id, h.node_level
    
    UNION ALL
    
    -- Recursive case: Parent nodes aggregate children
    SELECT 
        h.node_id,
        h.node_name,
        h.parent_id,
        h.node_level,
        hr.depth + 1 AS depth,
        COALESCE(SUM(r.TotalVotes), 0) AS direct_votes,
        COALESCE(SUM(r.TotalVotes), 0) + COALESCE(SUM(hr.total_votes_with_children), 0) AS total_votes_with_children
    FROM HIER h
    LEFT JOIN HierarchyRollup hr ON hr.parent_id = h.node_id
    LEFT JOIN Constituencies c ON c.Province LIKE '%' || h.node_name || '%'
    LEFT JOIN Results r ON r.ConstituencyID = c.ConstituencyID
    GROUP BY h.node_id, h.node_name, h.parent_id, h.node_level, hr.depth
)
SELECT 
    node_id,
    node_name,
    node_level,
    depth,
    direct_votes,
    total_votes_with_children AS total_votes_including_children,
    CASE 
        WHEN total_votes_with_children > 0 
        THEN ROUND((direct_votes::NUMERIC / total_votes_with_children) * 100, 2)
        ELSE 0 
    END AS pct_direct_vs_total
FROM HierarchyRollup
ORDER BY depth DESC, node_id;

-- ============================================================================
-- 4. CONTROL AGGREGATION - VALIDATE ROLLUP CORRECTNESS
-- ============================================================================

-- Verify that sum of all leaf nodes equals root total
WITH LeafNodes AS (
    SELECT 
        h.node_id,
        h.node_name,
        COALESCE(SUM(r.TotalVotes), 0) AS leaf_votes
    FROM HIER h
    LEFT JOIN Constituencies c ON c.Province LIKE '%' || h.node_name || '%'
    LEFT JOIN Results r ON r.ConstituencyID = c.ConstituencyID
    WHERE NOT EXISTS (SELECT 1 FROM HIER child WHERE child.parent_id = h.node_id)
    GROUP BY h.node_id, h.node_name
),
RootTotal AS (
    SELECT 
        SUM(r.TotalVotes) AS root_votes
    FROM Results r
)
SELECT 
    (SELECT SUM(leaf_votes) FROM LeafNodes) AS sum_of_leaf_nodes,
    (SELECT root_votes FROM RootTotal) AS total_votes_in_system,
    CASE 
        WHEN (SELECT SUM(leaf_votes) FROM LeafNodes) = (SELECT root_votes FROM RootTotal)
        THEN '✓ Rollup validation PASSED'
        ELSE '✗ Rollup validation FAILED'
    END AS validation_status;

-- ============================================================================
-- 5. HIERARCHY STATISTICS SUMMARY
-- ============================================================================

SELECT 
    '✓ Recursive queries executed successfully' AS status,
    (SELECT COUNT(*) FROM HIER) AS total_hierarchy_nodes,
    (SELECT COUNT(*) FROM HIER WHERE parent_id IS NULL) AS root_nodes,
    (SELECT MAX(depth) + 1 FROM (
        WITH RECURSIVE Depths AS (
            SELECT node_id, 0 AS depth FROM HIER WHERE parent_id IS NULL
            UNION ALL
            SELECT h.node_id, d.depth + 1 FROM HIER h JOIN Depths d ON h.parent_id = d.node_id
        ) SELECT depth FROM Depths
    ) sub) AS max_depth;
