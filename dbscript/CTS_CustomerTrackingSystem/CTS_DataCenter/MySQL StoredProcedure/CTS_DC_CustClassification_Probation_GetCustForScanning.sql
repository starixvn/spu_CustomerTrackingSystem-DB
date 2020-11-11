USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_GetCustForScanning`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_GetCustForScanning`(IN ip_NoOfRecord int)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200918@Harvey.Nguyen
		Task:		Return the Probation list for scanning
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- [20200923@Irena.Vo][141755]: Enhance SP.
            - [20201111@Irena.Vo][145028]: Update ScanTime = 20 Last Days
            
		Param's Explanation (filtered by):
         CALL CTS_DC_CustClassification_Probation_GetCustForScanning (100);
	*/
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    SET SQL_SAFE_UPDATES = 0;
    
    SELECT 			 cate.CustID 			  AS CustId
				   , cate.SportGroupID	      AS SportGroupId
				   , CASE WHEN DATE(cate.LastModifiedDate) = DATE_SUB(CURRENT_DATE(), INTERVAL 20 DAY) THEN 1 -- Re-categories -> call sp Final
                          ELSE 0  -- Update Margin -> call sp Loser
					 END AS Is20Day
    FROM			CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN		CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE			cate.CategoryID in (10, 206)   
                    AND cate.LastScannedDate <= DATE_SUB(CURRENT_DATE(), INTERVAL cc.ScanIntervalInSecond SECOND) -- only scan after 2 weeks
                    AND (	DATE(cate.LastModifiedDate) = DATE_SUB(CURRENT_DATE(), INTERVAL 20 DAY) -- = 20 last days
                            OR	( DATE(cate.LastModifiedDate) > DATE_SUB(CURRENT_DATE(), INTERVAL 20 DAY) 
                                  AND DATE(cate.LastModifiedDate) < DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY) ) ) -- > 20 last days and < 3 first days
	LIMIT			ip_NoOfRecord; 
     
	SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;