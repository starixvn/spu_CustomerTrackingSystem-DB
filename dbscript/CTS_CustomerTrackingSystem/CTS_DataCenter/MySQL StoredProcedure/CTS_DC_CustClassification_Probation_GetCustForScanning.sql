DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_Probation_GetCustForScanning$$
CREATE DEFINER=ctsService@`%` PROCEDURE CTS_DataCenter.CTS_DC_CustClassification_Probation_GetCustForScanning(IN ip_NoOfRecord INT) 
BEGIN
	/*
		Created:	20200918@Harvey.Nguyen
		Task:		Return the Probation list for scanning
		DB:			CTS_DataCenter
        
		Original:

		Revisions:
			
		Param's Explanation (filtered by):
         ip_CategoryIDList: ex: '1,2,3'       
         CALL CTS_DC_CustClassification_Probation_GetCustForScanning (100);
	*/
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT 		ccl.CustID 			AS CustID
				, ccl.SportGroupID	AS SportGroupID
                , ccl.CreatedDate > DATE_SUB(current_date(), INTERVAL 60 DAY) AS IsIn60Days
    FROM		CTS_DataCenter.CTSCustomerClassification AS ccl
    INNER JOIN	CTS_DataCenter.CustomerCategory AS cat
				ON ccl.CategoryID = cat.CategoryID
	WHERE		ccl.CategoryID in (10,206)
				AND	cat.IsActive = 1
				AND cat.IsUsedManually = 0
				AND cat.ScanIntervalInSecond > 0
				AND ccl.LastScannedDate <= DATE_SUB(current_date(), INTERVAL cat.ScanIntervalInSecond SECOND)
	LIMIT		ip_NoOfRecord;
END$$
DELIMITER ;

