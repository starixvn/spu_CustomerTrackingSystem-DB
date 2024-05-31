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
            - 20240423@Thomas.Nguyen: Classify Initial Group Betting - Return list Cust to get Remark for Initial GB [RedmineID: #200854]
			- 20240531@Thomas.Nguyen: Classify Initial Smart - Return list Cust to get Remark for Initial Smart [RedmineID: #199345]

		Param's Explanation (filtered by):    
			CALL CTS_DC_CustClassification_DailyScanPA_GetFromQueue()
	*/ 
   
    DECLARE lv_BatchSize 			INT;
    DECLARE lv_LastScannedTime		DATETIME;
	DECLARE	CONST_CATEGORYID_INITIALGB	 				INT DEFAULT 67;
	DECLARE	CONST_CATEGORYID_INITIALGB_LOSING			INT DEFAULT 107; 
	DECLARE	CONST_CATEGORYID_INITIALSMART		 		INT DEFAULT 66;
    DECLARE	CONST_CATEGORYID_INITIALSMART_LOSING		INT DEFAULT 106;

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

	/*Return list Cust to get Remark for Initial GB, Initial Smart*/
	SELECT	cust.CustID
		,	CASE WHEN cate.CategoryID IN (CONST_CATEGORYID_INITIALGB, CONST_CATEGORYID_INITIALGB_LOSING) THEN 1
				 WHEN cate.CategoryID IN (CONST_CATEGORYID_INITIALSMART, CONST_CATEGORYID_INITIALSMART_LOSING) THEN 2 END AS RemarkSourceType
	FROM Temp_Customers AS cust
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = cust.CustID
	WHERE cate.CategoryID IN (CONST_CATEGORYID_INITIALGB, CONST_CATEGORYID_INITIALGB_LOSING, CONST_CATEGORYID_INITIALSMART, CONST_CATEGORYID_INITIALSMART_LOSING);

END$$
DELIMITER ;