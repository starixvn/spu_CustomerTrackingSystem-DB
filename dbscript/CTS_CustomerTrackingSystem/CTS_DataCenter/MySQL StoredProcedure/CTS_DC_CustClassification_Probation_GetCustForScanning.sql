USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_GetCustForScanning`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsService`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_GetCustForScanning`(IN ip_NoOfRecord INT)
BEGIN
	/*
		Created:	20200918@Harvey.Nguyen
		Task:		Return the Probation list for scanning
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- [20200923@Irena.Vo][141755]: Enhance SP.
            
		Param's Explanation (filtered by):
         CALL CTS_DC_CustClassification_Probation_GetCustForScanning (100);
	*/
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    SET SQL_SAFE_UPDATES = 0;
    
    SELECT 	DISTINCT pro.CustID 			  AS CustId
				   , pro.SportGroupID	      AS SportGroupId
                   , pro.TargetCategoryID     AS CategoryId 
    FROM			CTS_DataCenter.ProbationAccountMonitor AS pro 
    INNER JOIN		CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = pro.CustID
    INNER JOIN		CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE			cate.CategoryID in (10,206)
					AND cate.LastScannedDate <= DATE_SUB(current_date(), INTERVAL cc.ScanIntervalInSecond SECOND)
                    AND pro.CreatedDate = DATE_SUB(current_date(), INTERVAL 60 DAY)
	LIMIT			ip_NoOfRecord; 
    
     
	SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;