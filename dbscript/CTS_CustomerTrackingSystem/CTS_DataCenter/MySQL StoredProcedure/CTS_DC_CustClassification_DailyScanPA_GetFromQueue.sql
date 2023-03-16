/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_DailyScanPA_GetFromQueue`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_DailyScanPA_GetFromQueue`(
      IN ip_MaxScanTime		DATETIME
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20230313@Jonas.Huynh
		Task:  Return PA category for daily scan PA
		DB: CTS_DataCenter
		Original:
		Revisions:
            - 20230313@Jonas.Huynh: Get PA category for daily scan PA [Redmine ID: #184772]
            
		Param's Explanation (filtered by):    
			CALL CTS_DC_CustClassification_DailyScanPA_GetFromQueue('2023-03-24 00:00:00')
	*/ 
   
    DECLARE lv_BatchSize 			INT;
	
	SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 87;
	
    SELECT DISTINCT TOP(lv_BatchSize) CustID
	FROM CTS_DataCenter.CTSCustomerClassification_DailyPAQueue
    WHERE CreatedTime <= ip_MaxScanTime
    ORDER BY ID ASC;
    
END$$
DELIMITER ;