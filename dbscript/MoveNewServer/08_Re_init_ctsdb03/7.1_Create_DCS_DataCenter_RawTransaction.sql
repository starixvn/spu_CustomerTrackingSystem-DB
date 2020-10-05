-- Step 1: Create DCS_DataCenter.RawTransaction from DCS_RawTransaction.RawTransaction
USE DCS_DataCenter;
CREATE TABLE DCS_DataCenter.RawTransaction LIKE DCS_RawTransaction.RawTransaction;

-- Step 2: Create DCS_DataCenter.ProcessedTransaction from DCS_RawTransaction.ProcessedTransaction
CREATE TABLE DCS_DataCenter.ProcessedTransaction LIKE DCS_RawTransaction.ProcessedTransaction;

-- Step 3: Create partition for DCS_DataCenter.RawTransaction
ALTER  TABLE DCS_DataCenter.RawTransaction  
                PARTITION BY RANGE (yearweek(CreatedDate,0)) (
                PARTITION pw202036 VALUES LESS THAN (202036),
                PARTITION pw202037 VALUES LESS THAN (202037),
                PARTITION pw202038 VALUES LESS THAN (202038),
                PARTITION pw202039 VALUES LESS THAN (202039),
                PARTITION pw202040 VALUES LESS THAN (202040),
                PARTITION pw999999 VALUES LESS THAN MAXVALUE);
                
--Step 4: Set AUTO_INCREMENT for TransID
-- ALTER TABLE DCS_DataCenter.RawTransaction AUTO_INCREMENT={[MaxTransID(RawTransaction)] + 1}, ALGORITHM=INPLACE, LOCK=NONE;  

             

