create user c##HEALTHNET identified by health2025;                      -- create a new database
grant unlimited tablespace to c##HEALTHNET;                             -- grant table creation permissions
grant resource, dba, connect to c##HEALTHNET;                           -- grant resource access permissions

-- Use schema: HEALTHNET-- 
ALTER SESSION SET CURRENT_SCHEMA = c##HEALTHNET;
-- prerequisite (minimal)
CREATE TABLE PATIENT (
ID NUMBER PRIMARY KEY, 
NAME VARCHAR2(100) NOT NULL
);

-- BUGGY: commas, NOT NULLs, CHECK parentheses, and date rule wording
 CREATE TABLE PATIENT_MED (
  PATIENT_MED_ID NUMBER PRIMARY KEY,                                   -- unique id
  PATIENT_ID NUMBER REFERENCES PATIENT(ID),                            -- must reference an existing patient
  MED_NAME VARCHAR2(80) NOT NULL,                                      -- should be NOT NULL
  DOSE_MG NUMBER(6,2) CHECK (DOSE_MG >= 0),                            -- missing parentheses
  START_DT DATE,
  END_DT   DATE,
  CONSTRAINT CK_RX_DATES CHECK (START_DT <= END_DT)                    -- corrected phrase
 );
 
-- FFIRST FAILED INSERT
-- TESTING AN INTEGRITY CONSTRAINT  (A MISSING PATIENT IN  PATIENT TABLE)
INSERT INTO PATIENT_MED (PATIENT_MED_ID,PATIENT_ID, MED_NAME,DOSE_MG, START_DT, END_DT)
VALUES(1,2, 'Bufen',10,DATE '2025-01-1', DATE '2025-10-10');

-- SECOND FAILED INSERT - CHECK CONSTRAINT ON DOSAGE
-- TESTING A NEGATIVE NUMBER
INSERT INTO PATIENT_MED (PATIENT_MED_ID,PATIENT_ID, MED_NAME,DOSE_MG, START_DT, END_DT)
VALUES (1,2, 'Bufen',-10,DATE '2025-01-1', DATE '2025-10-10');

-- insert patient record into patient table
INSERT INTO PATIENT (ID,NAME)
VALUES(2,'Zaka Chikhosi');

select * from patient;

-- SECOND SUCCESSFUL INSERT
-- TESTING AN INTEGRITY CONSTRAINT  (PRESENT PATIENT ID IN THE PATIENT TABLE)
INSERT INTO PATIENT_MED (PATIENT_MED_ID,PATIENT_ID, MED_NAME,DOSE_MG, START_DT, END_DT)
VALUES(1,2, 'Bufen',10,DATE '2025-01-1', DATE '2025-10-10');

SELECT * FROM PATIENT_MED;

-- SECOND success INSERT - CHECK CONSTRAINT ON DOSAGE with non-negative input
-- TESTING A NEGATIVE NUMBER
INSERT INTO PATIENT_MED (PATIENT_MED_ID,PATIENT_ID, MED_NAME,DOSE_MG, START_DT, END_DT)
VALUES (2,2, 'Bufen',10,DATE '2025-01-1', DATE '2025-10-10');
