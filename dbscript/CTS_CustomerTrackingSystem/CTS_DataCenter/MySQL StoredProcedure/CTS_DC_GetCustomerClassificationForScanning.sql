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
    
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS ccl
    INNER JOIN	CTS_DataCenter.CustomerCategory AS cat
				ON ccl.CategoryID = cat.CategoryID
	SET			ccl.LastScannedDate = @updatedList := vrScannedDate
	WHERE		cat.IsActive = 1
				AND cat.IsUsedManually = 0
				AND DATE_ADD(ccl.LastScannedDate, INTERVAL cat.ScanIntervalInSecond SECOND) <= CURRENT_DATE();  
                
    SELECT  @updatedList;
    
END$$
DELIMITER ;

