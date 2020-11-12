/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
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
    DECLARE lv_CurrentDate DATE DEFAULT CURRENT_DATE();
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    SET SQL_SAFE_UPDATES = 0;
    
    SELECT 			 pro.CustID 			  AS CustId
				   , pro.SportGroupID	      AS SportGroupId
				   , CASE WHEN pro.CreatedDate = DATE_SUB(lv_CurrentDate, INTERVAL 20 DAY) THEN 1 -- Update to Smart, High Risk, VIP & Normal
                          ELSE 0  -- Update to VIP & Normal
					 END AS Is20Days
    FROM			CTS_DataCenter.ProbationAccountMonitor AS pro
	WHERE			pro.CreatedDate = DATE_SUB(lv_CurrentDate, INTERVAL 20 DAY) -- From Now - CreatedDate = 20 (days)
                    OR	( pro.CreatedDate > DATE_SUB(lv_CurrentDate, INTERVAL 20 DAY) 
                          AND pro.CreatedDate < DATE_SUB(lv_CurrentDate, INTERVAL 3 DAY) )   -- From Now - CreatedDate < 20 (days)
	LIMIT			ip_NoOfRecord; 
     
	SET SQL_SAFE_UPDATES = 1; 
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
END$$

DELIMITER ;