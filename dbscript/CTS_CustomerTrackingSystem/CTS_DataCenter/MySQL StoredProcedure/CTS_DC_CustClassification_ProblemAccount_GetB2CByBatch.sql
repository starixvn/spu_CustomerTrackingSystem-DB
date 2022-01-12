/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_ProblemAccount_GetB2CByBatch`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_ProblemAccount_GetB2CByBatch`()
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
			- CALL CTS_DC_CustClassification_ProblemAccount_GetB2CByBatch ();
	*/	 
	DECLARE	CONST_GROUP_PROBLEM 	INT DEFAULT 0;
    DECLARE lv_LastCustID 			INT UNSIGNED;
    DECLARE lv_NextCustID 			INT UNSIGNED;
	DECLARE lv_BatchSize 			INT;
    DECLARE lv_CurrentSubID 		INT UNSIGNED;
    DECLARE lv_NextSubID 			INT UNSIGNED;

    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust (
			CustID 		INT  UNSIGNED 
		,	FraudID		int
        ,	PRIMARY KEY(CustID, FraudID)
    );
	
    SELECT ParameterValue
	INTO lv_LastCustID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 64; 
    
    SELECT ParameterValue
	INTO lv_CurrentSubID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 65;
    
	SELECT ParameterValue
	INTO lv_BatchSize
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 66;
    
    INSERT IGNORE INTO Temp_Cust(CustID, FraudID)
	SELECT 	clss.CustID
		,	cate.AFCFraudID
	FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID  AND cate.AFCFraudID IS NOT NULL
	WHERE clss.CustID > lv_LastCustID
		AND clss.SportGroupID = CONST_GROUP_PROBLEM
        AND clss.SubscriberID = lv_CurrentSubID
	ORDER BY clss.CustID ASC
	LIMIT lv_BatchSize;
    
    IF NOT EXISTS (SELECT 1 FROM Temp_Cust) THEN
		SELECT ItemID
        INTO lv_NextSubID
		FROM CTS_DataCenter.StaticList  AS sub
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON sub.ItemID = clss.SubscriberID AND clss.SportGroupID = 0
		WHERE ListID = 15 
			AND ItemID > lv_CurrentSubID
		ORDER BY ItemID ASC
		LIMIT 1; 
    END IF;
    
    IF lv_NextSubID IS NOT NULL THEN
		INSERT IGNORE INTO Temp_Cust(CustID, FraudID)
		SELECT 	clss.CustID
			,	cate.AFCFraudID
		FROM CTS_DataCenter.CTSCustomerClassification AS clss
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.AFCFraudID IS NOT NULL
		WHERE clss.CustID > 0
			AND clss.SportGroupID = CONST_GROUP_PROBLEM
			AND clss.SubscriberID = lv_NextSubID
		ORDER BY clss.CustID ASC
		LIMIT lv_BatchSize;
        
	ELSE
		SET lv_NextSubID = lv_CurrentSubID;
	END IF;
    
    SELECT MAX(CustID)
    INTO lv_NextCustID
    FROM Temp_Cust;
		
    IF lv_NextCustID IS NOT NULL THEN
		INSERT IGNORE INTO Temp_Cust(CustID, FraudID)
		SELECT 	clss.CustID
			,	cate.AFCFraudID
		FROM CTS_DataCenter.CTSCustomerClassification AS clss
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.AFCFraudID IS NOT NULL 
		WHERE clss.CustID = lv_NextCustID;
        
		UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = lv_NextCustID
		WHERE ParameterID = 64;
        
        UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = lv_NextSubID
		WHERE ParameterID = 65;
	ELSE 
		SELECT ItemID
        INTO lv_NextSubID
		FROM CTS_DataCenter.StaticList 
		WHERE ListID = 15 
		ORDER BY ItemID ASC 
		LIMIT 1;
        
		UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = 0
		WHERE ParameterID = 64;
        
        UPDATE CTS_DataCenter.SystemParameter 
        SET ParameterValue = lv_NextSubID
		WHERE ParameterID = 65;
    END IF;
    
    SELECT 	CustID
		,	GROUP_CONCAT(FraudID) AS FraudID
    FROM Temp_Cust
    GROUP BY CustID;
    
END$$
DELIMITER ;