DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `DCS_ST_ArchiveProcessedTransaction`(IN ip_NumOfDays int)
BEGIN
	/*
		Created: 20200408@Terry.Nguyen
		Task : Archive processed raw transaction
		DB: ProcessedTransaction
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
    
	DECLARE v_fromDate DATETIME;
    DECLARE v_executedDate DATETIME;
	DECLARE v_createdDate DATETIME;
    DECLARE v_bkTotalDay INT;
    
    SET v_fromDate = DATE_SUB(current_date(), INTERVAL ip_NumOfDays DAY);
    SET v_executedDate = NOW();
    
    INSERT 
		INTO DCS_RawTransaction.ArchiveTransactionLog(ExecutedDate,IsCompleted, StartTime, EndTime)
		VALUES(v_executedDate, false, NOW(), NOW());     
    
    #====================== 
    # Keep data in 2 days
    CREATE TABLE IF NOT EXISTS DCS_RawTransaction.ProcessedTransaction_BK LIKE DCS_RawTransaction.ProcessedTransaction;
    
    SELECT MAX(CreatedDate) INTO v_createdDate FROM DCS_RawTransaction.ProcessedTransaction_BK;    
    SET v_bkTotalDay = DATEDIFF(Current_DATE(), DATE(v_createdDate));
    IF v_bkTotalDay >= 2 THEN
		TRUNCATE TABLE DCS_RawTransaction.ProcessedTransaction_BK;
    END IF;
    
    INSERT INTO DCS_RawTransaction.ProcessedTransaction_BK
    SELECT * FROM DCS_RawTransaction.ProcessedTransaction 
	WHERE DATE(CreatedDate) < v_fromDate;
    #======================
    
    DELETE 
		FROM DCS_RawTransaction.ProcessedTransaction 
	WHERE DATE(CreatedDate) < v_fromDate;
    
    UPDATE DCS_RawTransaction.ArchiveTransactionLog 
		SET IsCompleted = true,
			EndTime = NOW()
	WHERE ExecutedDate = v_executedDate;       
END$$
DELIMITER ;
