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
			- 20230313@Jonas.Huynh: 	Get PA category for daily scan PA [Redmine ID: #184772]
			- 20240423@Thomas.Nguyen: 	Classify Initial Group Betting - Return list Cust to get Remark for Initial GB [RedmineID: #200854]
			- 20240531@Thomas.Nguyen: 	Classify Initial Smart - Return list Cust to get Remark for Initial Smart [RedmineID: #199345]
			- 20240705@Victoria.le:		Renovate CC Phase2 - Not return RemarkSourceType [[RedmineID: #205317] 

		Param's Explanation (filtered by):    
			CALL CTS_DC_CustClassification_DailyScanPA_GetFromQueue()
	*/ 
   
    DECLARE lv_BatchSize 			INT;
    DECLARE lv_LastScannedTime		DATETIME;

	DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
	CREATE TEMPORARY TABLE Temp_Customers(
			CustID					BIGINT UNSIGNED
	);

	SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 87;
    
    SELECT ParameterValue 
    INTO lv_LastScannedTime 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 88;
	
    SET lv_LastScannedTime = DATE_ADD(lv_LastScannedTime, INTERVAL 24 HOUR);
    
	INSERT INTO Temp_Customers(CustID)
	WITH cte AS ( 
		SELECT ID, CustID
		FROM CTS_DataCenter.CTSCustomerClassification_DailyPAQueue
		WHERE CreatedTime <= lv_LastScannedTime
		ORDER BY ID ASC
		LIMIT lv_BatchSize)
	SELECT DISTINCT CustID
    FROM cte;
    
	SELECT CustID
	FROM Temp_Customers;

END$$
DELIMITER ;