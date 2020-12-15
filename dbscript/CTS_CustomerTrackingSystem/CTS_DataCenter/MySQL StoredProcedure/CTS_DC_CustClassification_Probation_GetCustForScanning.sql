/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_GetCustForScanning`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_GetCustForScanning`(IN ip_NoOfRecord int)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20200918@Harvey.Nguyen
		Task:		Return the Probation list for scanning
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- [20200923@Irena.Vo][141755]: Enhance SP.
            - [20201111@Irena.Vo][145028]: Update ScanTime = 20 Last Days
			- 20201214@Irena.Vo: Ignore Pin category [RedmineID: #145951] 
            
		Param's Explanation (filtered by):
         CALL CTS_DC_CustClassification_Probation_GetCustForScanning (100);
	*/
    DECLARE lv_LimitedDay DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY);
    DECLARE lv_ProbationLastDay DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 20 DAY);
    
    SELECT 			 pro.CustID 			  AS CustId
				   , pro.SportGroupID	      AS SportGroupId
				   , CASE WHEN pro.CreatedDate = lv_ProbationLastDay THEN 1 -- Update to Smart, High Risk, VIP & Normal
                          ELSE 0  -- Update to VIP & Normal
					 END AS IsProbationLastDay
    FROM			CTS_DataCenter.ProbationAccountMonitor AS pro
    LEFT JOIN       CTS_DataCenter.PinCustomerCategory AS pin ON pin.CustID = pro.CustID
	WHERE			pin.CustID IS NULL 
                    AND (pro.LastScannedDate IS NULL OR pro.LastScannedDate < CURRENT_DATE())
                    AND (pro.CreatedDate = lv_ProbationLastDay -- From Now - CreatedDate = 20 (days)
						 OR	( pro.CreatedDate > lv_ProbationLastDay AND pro.CreatedDate < lv_LimitedDay) )  -- From Now - CreatedDate < 20 (days)
	LIMIT			ip_NoOfRecord; 
    
END$$

DELIMITER ;