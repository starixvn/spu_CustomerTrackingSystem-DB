/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_ProblemAccount_Scan`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_ProblemAccount_Scan`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20211130@Aries.Nguyen
		Task:		Scan PA to update info AFC
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20211130@Aries.Nguyen:	Created - [Redmine: #164079 ]
        
		Param's Explanation (filtered by):   
        
        Example: 
			- CALL CTS_DC_CustClassification_ProblemAccount_Scan ();
	*/	 
	DECLARE	CONST_GROUP_PROBLEM 	INT DEFAULT 0;
    DECLARE lv_LastCustID 			INT UNSIGNED;
	DECLARE lv_BatchSize 			INT;
    
	
    SELECT ParameterValue
	INTO lv_LastCustID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 64; 
    
	SELECT ParameterValue
	INTO lv_BatchSize
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 65;
	
    SET @lv_LastID = null; 
    
	SELECT @lv_LastID := CustID AS CustID
	FROM CTS_DataCenter.CTSCustomerClassification
	WHERE CustID > lv_LastCustID
		AND SportGroupID = CONST_GROUP_PROBLEM
	ORDER BY CustID ASC
	LIMIT lv_BatchSize;
    
    IF @lv_LastID IS NOT NULL THEN
		UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = @lv_LastID
		WHERE ParameterID = 64;
	ELSE 
		UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = 0
		WHERE ParameterID = 64;
    END IF;
    
END$$
DELIMITER ;