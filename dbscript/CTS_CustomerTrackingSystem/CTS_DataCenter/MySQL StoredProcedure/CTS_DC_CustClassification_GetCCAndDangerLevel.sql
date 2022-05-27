/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_GetCCAndDangerLevel`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetCCAndDangerLevel`(
	IN ip_CustIDs TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201214@Irena.Vo	
		Task :		Get Customers' latest Customer Class 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201214@Irena.Vo: Created [RedmineID: #145951]
        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetCCAndDangerLevel('1,2,1277,555555');
	*/ 
	DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
    DECLARE	CONST_GROUP_PROBLEM 				INT DEFAULT 0;
    DECLARE	CONST_GROUP_ROBOTUSER 				INT DEFAULT 61;
    
	DECLARE	CONST_CATEGORYID_GOODROBOTUSERS 	INT DEFAULT 164;
    DECLARE	CONST_CATEGORYID_GOODROBOTBETTING 	INT DEFAULT 166;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
    CREATE TEMPORARY TABLE 		Temp_CustInfo (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,	IsLicensee			BIT 		
		,	IsRobotException 	BIT 
		,   CustomerClass       INT  
        ,	CustomerClassName	VARCHAR(50)
		,	DangerLevel			INT  
		,	DangerLevelType		INT  
    );    
    
    INSERT IGNORE INTO Temp_CustInfo (CustID,IsLicensee,IsRobotException,CustomerClass)
    SELECT  tmp.CustID
		,	cus.IsLicensee
        ,	CASE WHEN (cus.IsLicensee = 0 AND cus.SubscriberID IN (2,130)) OR (cus.IsLicensee = 0 AND cus.CurrencyID IN (13,78)) THEN 1
				 ELSE 0 
			END AS IsRobotException
        , 	sp.CustomerClass
    FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID  = 0
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = tmp.CustID;
    
    SELECT 	tmp.CustID
		,	clss.CategoryID
		,	clss.CustomerClass
        ,	clss.DangerLevel
        ,	CASE WHEN clss.DangerLevel IS NULL THEN 0
			ELSE clss.DangerLevelType END AS DangerLevelType
    FROM Temp_CustInfo AS tmp,
		LATERAL(SELECT 	cate.CategoryID
					,	CASE  WHEN cate.CategoryID IN (CONST_CATEGORYID_GOODROBOTUSERS,CONST_CATEGORYID_GOODROBOTBETTING) AND tmp.IsRobotException = 1 THEN cate.CustomerClassException
							  ELSE cate.CustomerClass 
						END AS CustomerClass
					,	cate.CustomerClassName
					,	CASE WHEN cate.CategoryID IN (CONST_CATEGORYID_GOODROBOTUSERS,CONST_CATEGORYID_GOODROBOTBETTING) AND tmp.IsRobotException = 1 AND tmp.IsLicensee = 1 THEN cate.ABIDangerLevelException_Licensee
							 WHEN cate.CategoryID IN (CONST_CATEGORYID_GOODROBOTUSERS,CONST_CATEGORYID_GOODROBOTBETTING) AND tmp.IsRobotException = 1 AND tmp.IsLicensee = 0 THEN cate.ABIDangerLevelException_Credit
							 WHEN tmp.IsLicensee = 1 THEN cate.ABIDangerLevel_Licensee
							 WHEN tmp.IsLicensee = 0 THEN cate.ABIDangerLevel_Credit
						 END AS DangerLevel
                    ,	cate.DangerLevelType 
				FROM CTS_DataCenter.CTSCustomerClassification AS clss
					INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID
                WHERE clss.CustID = tmp.CustID
                ORDER BY  cate.Priority ASC  
						, clss.LastModifiedDate DESC
                LIMIT 1) AS clss;
END$$

DELIMITER ;