/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_ProblemAccount_GetByBatch`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_ProblemAccount_GetByBatch`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20211130@Aries.Nguyen
		Task:		Scan PA to update info AFC
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20211130@Aries.Nguyen: Created [Redmine: #164079]
        
		Param's Explanation (filtered by):   
        
        Example: 
			- CALL CTS_DC_CustClassification_ProblemAccount_GetByBatch ();
	*/	 
	DECLARE	CONST_GROUP_PROBLEM 	INT DEFAULT 0;
    DECLARE lv_LastCustID 			INT UNSIGNED;
    DECLARE lv_NextCustID 			INT UNSIGNED;
	DECLARE lv_BatchSize 			INT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust (
			CustID 		INT  UNSIGNED PRIMARY KEY
    );
	
    SELECT ParameterValue
	INTO lv_LastCustID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 64; 
    
	SELECT ParameterValue
	INTO lv_BatchSize
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 65;
	
    SET @lv_LastID = null; 
    
    INSERT IGNORE INTO Temp_Cust(CustID)
	SELECT CustID
	FROM CTS_DataCenter.CTSCustomerClassification
	WHERE CustID > lv_LastCustID
		AND SportGroupID = CONST_GROUP_PROBLEM
	ORDER BY CustID ASC
	LIMIT lv_BatchSize;
    
    SELECT MAX(CustID)
    INTO lv_NextCustID
    FROM Temp_Cust;
    
    IF lv_NextCustID IS NOT NULL THEN
		UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = lv_NextCustID
		WHERE ParameterID = 64;
	ELSE 
		UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = 0
		WHERE ParameterID = 64;
    END IF;
    
    SELECT CustID
    FROM Temp_Cust;
    
END$$
DELIMITER ;