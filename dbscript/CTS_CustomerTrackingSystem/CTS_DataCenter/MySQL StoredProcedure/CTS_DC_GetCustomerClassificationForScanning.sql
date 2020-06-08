DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerClassificationForScanning$$
CREATE DEFINER=fps@`%` PROCEDURE CTS_DataCenter.CTS_DC_GetCustomerClassificationForScanning()
BEGIN
	/*
		Created:	20200604@Casey.Huynh
		Task:		Return the auto tag customer list that reach to scanning schedule (interval refer to CTS_DataCenter.CustomerCategory.IntervalScan
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
	*/
    DECLARE vrScannedDate DATETIME DEFAULT CURRENT_DATE();
	
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
    DROP TEMPORARY TABLE IF EXISTS temp_scanList;
	CREATE TEMPORARY TABLE temp_scanList(
		CustID BIGINT UNSIGNED
        , SportGroupID SMALLINT UNSIGNED
        , CategoryID	SMALLINT UNSIGNED    
    );
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	INSERT INTO temp_scanList
	SELECT 		ccl.CustID 			AS CustID
				, ccl.SportGroupID	AS SportGroupID
                , ccl.CategoryID	AS CategoryID
    FROM		CTS_DataCenter.CTSCustomerClassification AS ccl
    INNER JOIN	CTS_DataCenter.CustomerCategory AS cat
				ON ccl.CategoryID = cat.CategoryID
	WHERE		cat.IsActive = 1
				AND cat.IsUsedManually = 0
                AND cat.ScanIntervalInSecond > 0
				AND DATE_ADD(ccl.LastScannedDate, INTERVAL cat.ScanIntervalInSecond SECOND) <= CURRENT_DATE();
    
    SELECT 		tmpList.CustID 		
				, tmpList.SportGroupID	
                , tmpList.CategoryID
	FROM 		temp_scanList	AS tmpList;     
    
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS ccl
    INNER JOIN 	temp_scanList	AS tmpList
				ON ccl.CustID = tmpList.CustID
                AND ccl.SportGroupID = ccl.SportGroupID
	SET			ccl.LastScannedDate = vrScannedDate;
    
END$$
DELIMITER ;

