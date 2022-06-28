/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_GetCCAndDangerLevel`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetCCAndDangerLevel`(
	IN ip_CustIDs TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220526@Aries.Nguyen	
		Task :		Renovate PA Process
		DB:			CTS_DataCenter  
		Original: 
		Revisions:
			- 20220526@Aries.Nguyen: Created [RedmineID: #172561]
            - 20220628@Aries.Nguyen: Update robot classification rule [Redmine ID: #174430]
            
        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetCCAndDangerLevel('1,2,1277,555555');
	*/ 
	DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
    DECLARE	CONST_GROUP_PROBLEM 				INT DEFAULT 0;
    
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCateInfo;
    CREATE TEMPORARY TABLE 		Temp_CustCateInfo (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 	
		,	CategoryID			INT
		,	CustomerClass		INT
        ,	CustomerClassName  	VARCHAR(50)
        ,	DangerLevel			INT
		,	DangerLevelType		SMALLINT  
    );    
    
    INSERT IGNORE INTO Temp_CustInfo (CustID,IsLicensee,IsRobotException,CustomerClass)
    SELECT  tmp.CustID
		,	cus.IsLicensee
        ,	CASE WHEN (cus.IsLicensee = 0 AND cus.SiteID = 16) OR (cus.IsLicensee = 0 AND cus.CurrencyID IN (6,13)) THEN 1
				 ELSE 0 
			END AS IsRobotException
        , 	sp.CustomerClass
    FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID  = 0
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = tmp.CustID;
    
    INSERT INTO Temp_CustCateInfo(CustID,CategoryID,CustomerClass,CustomerClassName,DangerLevel,DangerLevelType)
    SELECT 	tmp.CustID
		,	clss.CategoryID
		,	clss.CustomerClass
        ,	clss.CustomerClassName  
        ,	clss.DangerLevel
        ,	CASE WHEN clss.DangerLevel IS NULL THEN 0
			ELSE clss.DangerLevelType END AS DangerLevelType
    FROM Temp_CustInfo AS tmp,
		LATERAL(SELECT 	CASE WHEN clss.SportGroupID =  CONST_GROUP_PROBLEM AND  tmp.CustomerClass IS NULL THEN  CategoryGroup 
							 ELSE NULL END AS CategoryID
					,	CASE  WHEN tmp.CustomerClass IS NOT NULL THEN tmp.CustomerClass
							  ELSE cate.CustomerClass END AS CustomerClass
					,	cate.CustomerClassName
					,	CASE WHEN tmp.IsLicensee = 1 THEN cate.ABIDangerLevel_Licensee
							 WHEN tmp.IsLicensee = 0 THEN cate.ABIDangerLevel_Credit
						 END AS DangerLevel
                    ,	cate.DangerLevelType 
				FROM CTS_DataCenter.CTSCustomerClassification AS clss
					INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID
                WHERE clss.CustID = tmp.CustID
                ORDER BY  cate.Priority ASC  
						, clss.LastModifiedDate DESC
                LIMIT 1) AS clss;
		
	SELECT 	tmp.CustID
		,	cate.CategoryID
		,	IFNULL(cate.CustomerClass,-1) AS CustomerClass
        ,	cate.CustomerClassName  
        ,	cate.DangerLevel
        ,	cate.DangerLevelType 
    FROM Temp_CustInfo AS tmp
		LEFT JOIN Temp_CustCateInfo AS cate ON tmp.CustID = cate.CustID;
END$$

DELIMITER ;