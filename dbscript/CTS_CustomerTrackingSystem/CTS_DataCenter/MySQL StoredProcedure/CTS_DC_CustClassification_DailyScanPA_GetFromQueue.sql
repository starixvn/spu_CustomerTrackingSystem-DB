/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_DailyScanPA_GetFromQueue`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_DailyScanPA_GetFromQueue`(
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
			CALL CTS_DC_CustClassification_DailyScanPA_GetFromQueue()
	*/ 
   
    DECLARE lv_BatchSize 			INT;
    DECLARE lv_LastScannedTime		DATETIME;
	
	SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 87;
    
    SELECT ParameterValue 
    INTO lv_LastScannedTime 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 88;
	
    SET lv_LastScannedTime = DATE_ADD(lv_LastScannedTime, INTERVAL 24 HOUR);
    
	WITH cte AS ( 
		SELECT ID, CustID
		FROM CTS_DataCenter.CTSCustomerClassification_DailyPAQueue
		WHERE CreatedTime <= lv_LastScannedTime
		ORDER BY ID ASC
		LIMIT lv_BatchSize)
	SELECT DISTINCT CustID 
    FROM cte;
    
END$$
DELIMITER ;