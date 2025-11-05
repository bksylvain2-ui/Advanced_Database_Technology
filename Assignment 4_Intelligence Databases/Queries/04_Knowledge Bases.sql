-- Create the triple table
CREATE TABLE TRIPLE (S VARCHAR2(100), P VARCHAR2(50), O VARCHAR2(100));

-- Insert sample data ( 8 triples as requested)
INSERT INTO TRIPLE VALUES ('Influenza', 'isA', 'ViralInfection');
INSERT INTO TRIPLE VALUES ('ViralInfection', 'isA', 'InfectiousDisease');
INSERT INTO TRIPLE VALUES ('BacterialPneumonia', 'isA', 'InfectiousDisease');
INSERT INTO TRIPLE VALUES ('CommonCold', 'isA', 'ViralInfection');
INSERT INTO TRIPLE VALUES ('patient1', 'hasDiagnosis', 'Influenza');
INSERT INTO TRIPLE VALUES ('patient2', 'hasDiagnosis', 'BacterialPneumonia');
INSERT INTO TRIPLE VALUES ('patient3', 'hasDiagnosis', 'CommonCold');
INSERT INTO TRIPLE VALUES ('patient4', 'hasDiagnosis', 'Hypertension'); -- Non-infectious for contrast
COMMIT;


-- DEBUGGED SOLUTION
WITH ISA(CHILD, ANCESTOR) AS (
  /* ANCHOR: Start with direct parent-child relationships in taxonomy
     Example: ('Influenza', 'isA', 'ViralInfection') -> CHILD='Influenza', ANCESTOR='ViralInfection' */
  SELECT S AS CHILD, O AS ANCESTOR
  FROM TRIPLE 
  WHERE P = 'isA'
  
  UNION ALL
  
  /* RECURSIVE: Build transitive closure - if X isA Y and Y isA Z, then X isA Z
     Fixed bug: Original had T.O = I.ANCESTOR (wrong direction) */
  SELECT T.S AS CHILD, I.ANCESTOR
  FROM TRIPLE T
  JOIN ISA I ON T.O = I.CHILD  -- Correct: T's parent (O) is I's child
  WHERE T.P = 'isA'
),
INFECTIOUS_PATIENTS AS (
  /* Find patients whose diagnosis ultimately rolls up to InfectiousDisease
     Fixed bug: Original compared ISA.CHILD instead of ISA.ANCESTOR */
  SELECT DISTINCT T.S AS PATIENT_ID
  FROM TRIPLE T
  JOIN ISA ON T.O = ISA.CHILD  -- Patient's diagnosis is the child in taxonomy
  WHERE T.P = 'hasDiagnosis'
    AND ISA.ANCESTOR = 'InfectiousDisease'  -- And it has InfectiousDisease as ancestor
)
-- Final result: Patients with infectious diseases
SELECT PATIENT_ID 
FROM INFECTIOUS_PATIENTS
ORDER BY PATIENT_ID;

-- **************************************************************************************
-- Taxonomy closure (Child, Ancestor
-- **************************************************************************************
-- Display the full 'isA' transitive closure
WITH ISA(CHILD, ANCESTOR) AS (
  SELECT S, O FROM TRIPLE WHERE P = 'isA'
  UNION ALL
  SELECT T.S, I.ANCESTOR
  FROM TRIPLE T
  JOIN ISA I ON T.O = I.CHILD
  WHERE T.P = 'isA'
)
SELECT CHILD, ANCESTOR 
FROM ISA
ORDER BY CHILD, ANCESTOR;
