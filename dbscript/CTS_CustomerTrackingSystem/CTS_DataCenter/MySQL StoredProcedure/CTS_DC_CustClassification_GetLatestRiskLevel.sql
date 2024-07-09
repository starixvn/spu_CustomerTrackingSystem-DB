/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_GetLatestRiskLevel`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetLatestRiskLevel`(
		IN ip_SubscriberID	INT
    ,	IN ip_MaxID			BIGINT UNSIGNED
    ,	IN ip_BatchSize		INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20240708@Casey.Huynh	
		Task :		Get the latest Risk Level 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20240708@Casey.Huynh: Created [RedmineID: #206486]
        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetLatestRiskLevel(169, 1, 1000);
	*/ 
    
	DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
    DECLARE	CONST_GROUP_PROBLEM 				INT DEFAULT 0;
    DECLARE	CONST_GROUP_ROBOTUSER 				INT DEFAULT 61;
    DECLARE	CONST_CATEGORY_BADROBOTUSER 		INT DEFAULT 163;
    DECLARE	CONST_CATEGORY_GOODROBOTUSER 		INT DEFAULT 164;
    
    DECLARE lv_CurrentDateTime		DATETIME DEFAULT CURRENT_TIMESTAMP();
    DECLARE lv_LastModifiedDate BIGINT UNSIGNED;
        
    DROP TEMPORARY TABLE IF EXISTS Temp_ClassificationHistory;    
    CREATE TEMPORARY TABLE Temp_ClassificationHistory(
			ID 					BIGINT UNSIGNED PRIMARY KEY
		,	LastModifiedDate	DATETIME
        ,	CustID				BIGINT UNSIGNED
        ,	RegisterName		VARCHAR(50)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
    CREATE TEMPORARY TABLE 		Temp_Customer (
			CustMaxID			BIGINT UNSIGNED
		,	LastModifiedDate	DATETIME
		,	CustID          	BIGINT UNSIGNED PRIMARY KEY
		,	RegisterName		VARCHAR(50)
        
    );  
    /*=========Get Customer =========================*/
    
    SET lv_LastModifiedDate = TIMESTAMPADD(Minute, -1, NOW());
 
    INSERT INTO Temp_ClassificationHistory(ID, CustID, RegisterName)
    SELECT	his.ID
		,	his.CustID
        ,	cus.RegisterName
	FROM CTS_DataCenter.CTSCustomerClassification_History_Original AS his 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON his.CustID = cus.CustID AND cus.CustSubID = 0 AND cus.SubscriberID = ip_SubscriberID
        INNER JOIN CTS_DataCenter.CustDCSAccount AS ds ON cus.CTSCustID = ds.CTSCustID
	WHERE	his.ID > ip_MaxID
		AND his.LastModifiedDate <= lv_LastModifiedDate
	ORDER BY his.ID ASC
	LIMIT ip_BatchSize;

    INSERT IGNORE INTO Temp_Customer(CustMaxID, CustID, RegisterName)
    SELECT DISTINCT
			tmpCls.ID
		,	tmpCls.CustID
		,	tmpCls.RegisterName
    FROM Temp_ClassificationHistory AS tmpCls
    ORDER BY tmpCls.ID DESC;      
    
    SELECT	tmpCus.CustMaxID AS ID
		,	ltr.LastModifiedDate
        ,	tmpCus.RegisterName
        ,	ltr.CustomerClass
        ,	ltr.SabaIntelligent_RiskLevel        
		,	tmpCus.CustID
    FROM Temp_Customer AS tmpCus,
		LATERAL(SELECT cat.CustomerClass, cat.SabaIntelligent_RiskLevel, cls.LastModifiedDate
				FROM CTS_DataCenter.CTSCustomerClassification_Original AS cls
					INNER JOIN CTS_DataCenter.CustomerCategory_Original AS cat ON cls.CategoryID = cat.CategoryID
                WHERE cls.CustID = tmpCus.CustID
                ORDER BY cat.Priority ASC, cls.LastModifiedDate DESC		
                LIMIT 1) AS ltr;       

END$$
DELIMITER;

CALL CTS_DataCenter.CTS_DC_CustClassification_GetLatestRiskLevel(169, 1, 1000);