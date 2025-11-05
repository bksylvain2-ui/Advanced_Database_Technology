-- prerequisite (example)
CREATE TABLE STAFF_SUPERVISOR (
    EMPLOYEE VARCHAR2(50), 
    SUPERVISOR VARCHAR2(50)
    );
    
-- sample data (small demo)
INSERT INTO STAFF_SUPERVISOR VALUES ('Alice',   'Bob');
INSERT INTO STAFF_SUPERVISOR VALUES ('Bob',     'Carol');
INSERT INTO STAFF_SUPERVISOR VALUES ('Carol',   'Diana');
INSERT INTO STAFF_SUPERVISOR VALUES ('Eve',     'Bob');
INSERT INTO STAFF_SUPERVISOR VALUES ('Frank',   'Eve');
INSERT INTO STAFF_SUPERVISOR VALUES ('Diana',   'Diana'); -- self-supervised (to test cycle guard)
COMMIT;


-- Recursive query
WITH SUPERS (EMP, SUP, HOPS, PATH) AS (
  -- Anchor part: Start with all direct reports to Diana
  -- These are the first level of the supervision hierarchy
  SELECT EMPLOYEE,           -- Current employee in the chain
         SUPERVISOR,         -- Ultimate supervisor (Diana at this level)
         1,                  -- Initial hop count (direct report)
         EMPLOYEE || ' -> ' || SUPERVISOR  -- Build initial path string
  FROM STAFF_SUPERVISOR
  WHERE SUPERVISOR = 'Diana'           -- Only include Diana's direct reports
    AND EMPLOYEE != SUPERVISOR         -- Exclude self-supervision to prevent cycles
  
  UNION ALL
  
  -- Recursive part: Find people who report to employees already in the chain
  -- This expands the hierarchy level by level
  SELECT S.EMPLOYEE,         -- New employee to add to chain
         T.SUP,              -- Carry forward the ultimate supervisor (Diana)
         T.HOPS + 1,         -- Increment hop count (one level deeper)
         S.EMPLOYEE || ' -> ' || T.PATH  -- Prepend new employee to existing path
  FROM STAFF_SUPERVISOR S
  -- Join: Find employees (S) who report to employees (T.EMP) already in our result set
  JOIN SUPERS T ON S.SUPERVISOR = T.EMP
  WHERE S.EMPLOYEE != S.SUPERVISOR     -- Prevent infinite loops from self-reports
)
-- Oracle cycle detection: Automatically stops if employee appears twice in same path
CYCLE EMP SET IS_CYCLE TO 'Y' DEFAULT 'N'

-- Final selection: Display the complete supervision chains
SELECT EMP,                   -- Employee at the end of each chain
       SUP AS TOP_SUPERVISOR, -- Ultimate supervisor (always Diana in this case)
       HOPS,                  -- Number of levels from Diana to this employee
       PATH                   -- Complete supervision path from employee up to Diana
FROM SUPERS
-- Order by hop count (closest to Diana first) then by employee name
ORDER BY HOPS, EMP;
