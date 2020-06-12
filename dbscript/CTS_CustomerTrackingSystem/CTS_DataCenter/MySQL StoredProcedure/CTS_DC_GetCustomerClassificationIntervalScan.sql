DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerClassificationIntervalScan$$
CREATE DEFINER=fps@`%` PROCEDURE CTS_DataCenter.CTS_DC_GetCustomerClassificationIntervalScan(IN ip_NoOfRecord INT, IN ip_Batch INT)
BEGIN
	/*
		Created:	[20200612@Casey.Huynh][135324]
		Task:		Return the auto tag customer list that reach to scanning schedule (interval refer to CTS_DataCenter.CustomerCategory.IntervalScan
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
	*/
    DECLARE vrScanTime DATETIME;
    DECLARE vrScanDate DATETIME;    
    DECLARE vrLastScanTime DATETIME;
    DECLARE vrLastScanDate DATETIME;
    DECLARE vrLastCustID BIGINT UNSIGNED;
    DECLARE vrTotalRecord BIGINT UNSIGNED;
	DECLARE vrBatch INT UNSIGNED DEFAULT 1;
	
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
    DROP TEMPORARY TABLE IF EXISTS temp_scanList;
	CREATE TEMPORARY TABLE temp_scanList(
		CustID BIGINT UNSIGNED
        , SportGroupID SMALLINT UNSIGNED
        , CategoryID	SMALLINT UNSIGNED    
        , BatchID		INT
        
        ,INDEX	IX_temp_scanList_BatchID(BatchID)
    );
    
	SET vrScanTime = CURRENT_TIME();
    SET vrLastScanTime = (SELECT MAX(ScanTime) FROM CTS_DataCenter.CTSCustomerClassification_ScanStatus);
	SET vrScanDate = DATE(vrScanTime);
    SET vrLastScanDate = DATE(vrLastScanTime);
    
    IF(vrLastScanDate != vrScanDate)
    THEN
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_ScanStatus(ScanTime, LastCustID, ScanStatus)
		VALUES(vrScanTime, 0, 0);
	ELSE	
		SET vrScanTime = vrLastScanTime;
    END IF;
	SET vrLastCustID = (	SELECT 	LastCustID
							FROM 	CTS_DataCenter.CTSCustomerClassification_ScanStatus  
							WHERE 	ScanTime = vrScanTime);   

	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SET vrTotalRecord =ip_Batch * ip_NoOfRecord ;
    
	INSERT INTO temp_scanList (CustID, SportGroupID, CategoryID)
	SELECT 		ccl.CustID 			AS CustID
				, ccl.SportGroupID	AS SportGroupID
                , ccl.CategoryID	AS CategoryID
    FROM		CTS_DataCenter.CTSCustomerClassification AS ccl
    INNER JOIN	CTS_DataCenter.CustomerCategory AS cat
				ON ccl.CategoryID = cat.CategoryID
	WHERE		cat.IsActive = 1
				AND cat.IsUsedManually = 0
                AND cat.ScanIntervalInSecond > 0
                AND	ccl.CustID > vrLastCustID
				AND DATE_ADD(ccl.LastScannedDate, INTERVAL cat.ScanIntervalInSecond SECOND) <= vrScanDate
	ORDER BY 	ccl.CustID
	LIMIT		vrTotalRecord;    

	WHILE (EXISTS (SELECT (1) FROM temp_scanList WHERE BatchID IS NULL LIMIT 1)) DO
		  UPDATE 	temp_scanList
		  SET		BatchID = vrBatch
		  WHERE		BatchID IS NULL 
		  LIMIT 	ip_NoOfRecord;    
		  SET vrBatch = vrBatch + 1;
	END WHILE;

	SELECT 		tmpList.BatchID
				, tmpList.CustID 		
				, tmpList.SportGroupID	
				, tmpList.CategoryID
				, tmpList.BatchID
	FROM 		temp_scanList	AS tmpList;     

	UPDATE 		CTS_DataCenter.CTSCustomerClassification AS ccl
	INNER JOIN 	temp_scanList	AS tmpList
				ON ccl.CustID = tmpList.CustID
				AND ccl.SportGroupID = ccl.SportGroupID
	SET			ccl.LastScannedDate = vrScanDate;
		
	IF NOT EXISTS (SELECT 1 FROM temp_scanList LIMIT 1)
    THEN
		UPDATE CTS_DataCenter.CTSCustomerClassification_ScanStatus
        SET		ScanStatus = 1
        WHERE	ScanTime = vrScanTime;
    END IF;
		
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
END$$
DELIMITER ;

