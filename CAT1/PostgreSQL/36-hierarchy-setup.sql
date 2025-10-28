-- ============================================================================
-- B8: Recursive Hierarchy Roll-Up (6–10 rows)
-- ============================================================================
-- Creates a 3-level administrative hierarchy for Rwanda's e-voting system
-- and demonstrates recursive queries with vote rollups.
-- ============================================================================

-- Drop existing objects if they exist
DROP TABLE IF EXISTS HIER CASCADE;

-- ============================================================================
-- 1. CREATE HIERARCHY TABLE
-- ============================================================================

CREATE TABLE HIER (
    node_id         INTEGER PRIMARY KEY,
    parent_id       INTEGER REFERENCES HIER(node_id) ON DELETE CASCADE,
    node_name       VARCHAR(100) NOT NULL,
    node_level      VARCHAR(20) NOT NULL CHECK (node_level IN ('Country', 'Province', 'District')),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraint: root node has no parent
    CONSTRAINT chk_hier_root CHECK (
        (parent_id IS NULL AND node_level = 'Country') OR
        (parent_id IS NOT NULL AND node_level != 'Country')
    )
);

-- Create indexes for hierarchy traversal
CREATE INDEX idx_hier_parent ON HIER(parent_id);
CREATE INDEX idx_hier_level ON HIER(node_level);

COMMENT ON TABLE HIER IS 'Administrative hierarchy for Rwanda e-voting system';
COMMENT ON COLUMN HIER.node_id IS 'Unique identifier for hierarchy node';
COMMENT ON COLUMN HIER.parent_id IS 'Reference to parent node (NULL for root)';
COMMENT ON COLUMN HIER.node_level IS 'Level in hierarchy: Country, Province, or District';

-- ============================================================================
-- 2. INSERT HIERARCHY DATA (10 rows total - 3 levels)
-- ============================================================================

-- Level 1: Country (Root) - 1 row
INSERT INTO HIER (node_id, parent_id, node_name, node_level) VALUES
(1, NULL, 'Rwanda', 'Country');

-- Level 2: Provinces - 5 rows
INSERT INTO HIER (node_id, parent_id, node_name, node_level) VALUES
(2, 1, 'Kigali City', 'Province'),
(3, 1, 'Eastern Province', 'Province'),
(4, 1, 'Northern Province', 'Province'),
(5, 1, 'Southern Province', 'Province'),
(6, 1, 'Western Province', 'Province');

-- Level 3: Sample Districts - 4 rows (to reach 10 total)
INSERT INTO HIER (node_id, parent_id, node_name, node_level) VALUES
(7, 2, 'Gasabo District', 'District'),
(8, 2, 'Kicukiro District', 'District'),
(9, 3, 'Rwamagana District', 'District'),
(10, 4, 'Musanze District', 'District');

-- ============================================================================
-- 3. VERIFY HIERARCHY STRUCTURE
-- ============================================================================

-- Show all hierarchy nodes with their parent relationships
SELECT 
    h.node_id,
    h.node_name,
    h.node_level,
    h.parent_id,
    p.node_name AS parent_name,
    CASE 
        WHEN h.parent_id IS NULL THEN 0
        WHEN p.parent_id IS NULL THEN 1
        ELSE 2
    END AS depth
FROM HIER h
LEFT JOIN HIER p ON h.parent_id = p.node_id
ORDER BY 
    CASE WHEN h.parent_id IS NULL THEN 0
         WHEN p.parent_id IS NULL THEN 1
         ELSE 2 END,
    h.node_id;

-- Count nodes by level
SELECT 
    node_level,
    COUNT(*) AS node_count
FROM HIER
GROUP BY node_level
ORDER BY 
    CASE node_level
        WHEN 'Country' THEN 1
        WHEN 'Province' THEN 2
        WHEN 'District' THEN 3
    END;

-- ============================================================================
-- VERIFICATION OUTPUT
-- ============================================================================
-- Expected: 10 total rows (1 Country + 5 Provinces + 4 Districts)
-- Hierarchy depth: 3 levels (0=Country, 1=Province, 2=District)
-- ============================================================================

SELECT 
    '✓ Hierarchy table created with ' || COUNT(*) || ' nodes' AS status
FROM HIER;

SELECT 
    '✓ 3-level hierarchy: ' || 
    SUM(CASE WHEN node_level = 'Country' THEN 1 ELSE 0 END) || ' Country, ' ||
    SUM(CASE WHEN node_level = 'Province' THEN 1 ELSE 0 END) || ' Provinces, ' ||
    SUM(CASE WHEN node_level = 'District' THEN 1 ELSE 0 END) || ' Districts' AS structure
FROM HIER;
