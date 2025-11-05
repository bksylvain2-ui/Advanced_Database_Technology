-- prerequisites (minimal)
CREATE TABLE BILL (ID NUMBER PRIMARY KEY, TOTAL NUMBER(12,2));      
CREATE TABLE BILL_ITEM(
    BILL_ID NUMBER, 
    AMOUNT NUMBER(12,2), 
    UPDATED_AT DATE,                                                    
    CONSTRAINT FK_BILL_ITEM_BILL FOREIGN KEY (BILL_ID) REFERENCES BILL(ID)
    );

CREATE TABLE BILL_AUDIT(
    BILL_ID NUMBER, 
    OLD_TOTAL NUMBER(12,2),
    NEW_TOTAL NUMBER(12,2), 
    CHANGED_AT DATE
    );
 
 -- BUGGY: row-level, recomputes per row, references :NEW even on DELETE
 CREATE OR REPLACE TRIGGER TRG_BILL_TOTAL
 AFTER INSERT OR UPDATE OR DELETE ON BILL_ITEM
 FOR EACH ROW
 BEGIN
  UPDATE BILL b
     SET b.TOTAL = (SELECT NVL(SUM(AMOUNT),0)
     FROM BILL_ITEM i 
     WHERE i.BILL_ID = :NEW.BILL_ID);
 END;
 /
 -- Students: replace with a statement-level trigger named TRG_BILL_TOTAL_STMT
 -- (or a compound trigger named TRG_BILL_TOTAL_CMP) that:
 -- 1) collects affected BILL_IDs; 2) recomputes once per bill; 3) inserts an audit row.
 
 -- Compound trigger
CREATE OR REPLACE TRIGGER TRG_BILL_TOTAL_CMP
FOR INSERT OR UPDATE OR DELETE ON BILL_ITEM
COMPOUND TRIGGER

  -- Declare a collection to store affected bill IDs
  TYPE t_bill_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  g_bill_ids t_bill_ids;
  g_count INTEGER := 0;

  -- Before or after each row
  AFTER EACH ROW IS
  BEGIN
    -- Handle :NEW and :OLD safely
    IF INSERTING OR UPDATING THEN
      g_count := g_count + 1;
      g_bill_ids(g_count) := :NEW.BILL_ID;
    ELSIF DELETING THEN
      g_count := g_count + 1;
      g_bill_ids(g_count) := :OLD.BILL_ID;
    END IF;
  END AFTER EACH ROW;

  -- After statement finishes, recompute totals once per affected bill
  AFTER STATEMENT IS
  BEGIN
    FOR i IN 1 .. g_count LOOP
      DECLARE
        v_bill_id NUMBER := g_bill_ids(i);
        v_old_total NUMBER(12,2);
        v_new_total NUMBER(12,2);
      BEGIN
        -- Get the old total
        SELECT NVL(TOTAL, 0) INTO v_old_total FROM BILL WHERE ID = v_bill_id;

        -- Compute new total
        SELECT NVL(SUM(AMOUNT), 0)
          INTO v_new_total
          FROM BILL_ITEM
         WHERE BILL_ID = v_bill_id;

        -- Update the BILL table
        UPDATE BILL
           SET TOTAL = v_new_total
         WHERE ID = v_bill_id;

        -- Record the change in the audit table
        INSERT INTO BILL_AUDIT (BILL_ID, OLD_TOTAL, NEW_TOTAL, CHANGED_AT)
        VALUES (v_bill_id, v_old_total, v_new_total, SYSDATE);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL; -- Ignore if BILL row doesn't exist
      END;
    END LOOP;
  END AFTER STATEMENT;
END TRG_BILL_TOTAL_CMP;
/


--*******************************************************************
-- PREPARE SAMPLE DATA
-- *******************************************************************
-- Create a bill
INSERT INTO BILL VALUES (1, 0);

-- Add bill items
INSERT INTO BILL_ITEM VALUES (1, 100, SYSDATE);
INSERT INTO BILL_ITEM VALUES (1, 50, SYSDATE);
-- After this, BILL.TOTAL should become 150
SELECT TOTAL FROM BILL WHERE ID = 1;


-- Performing UPDATE TEST
-- Update one item
UPDATE BILL_ITEM SET AMOUNT = 75 WHERE BILL_ID = 1 AND AMOUNT = 50;
-- BILL.TOTAL should now be 175
SELECT TOTAL FROM BILL WHERE ID = 1;

-- Performing delete test
-- Delete an item
DELETE FROM BILL_ITEM WHERE BILL_ID = 1 AND AMOUNT = 100;
-- BILL.TOTAL should now be 75

SELECT TOTAL FROM BILL WHERE ID = 1;


SELECT * FROM BILL;
SELECT * FROM BILL_AUDIT;
