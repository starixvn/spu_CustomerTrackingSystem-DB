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
			- 20220705@Long.Luu: Support Licensee VIP & BA Categories [Redmine ID: #174219]
            
        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetCCAndDangerLevel('1,2,1277,555555');
	*/ 
	DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
	DECLARE	CONST_GROUP_WRAPPER 				INT DEFAULT 100;
    DECLARE	CONST_GROUP_PROBLEM 				INT DEFAULT 0;
        
    DECLARE	CONST_LICVIP_DANGEROUSCATEGORY		INT DEFAULT 3;
    DECLARE	CONST_LICVIP_SUSPICIOUSCATEGORY		INT DEFAULT 4;
    DECLARE	CONST_LICVIP_DANGEROUSCC 			INT DEFAULT 99;
    DECLARE	CONST_VVIPCC						INT DEFAULT 100;
    DECLARE	CONST_LICVIP_SUSPICIOUSCC			INT DEFAULT 101;
    
    DECLARE	lv_LicVIP_DangerousCCName 			VARCHAR(50);
    DECLARE	lv_LicVIP_SuspiciousCCName			VARCHAR(50);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
    CREATE TEMPORARY TABLE 		Temp_CustInfo (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,	IsLicensee			BIT 
		,	IsLicenseeVIP		BIT 				
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
		,	IsDangerProbation	BIT DEFAULT 0
		,	CustomerClass		INT
        ,	CustomerClassName  	VARCHAR(50)
        ,	DangerLevel			INT
		,	DangerLevelType		SMALLINT  
    );    
    
    INSERT IGNORE INTO Temp_CustInfo (CustID,IsLicensee,IsLicenseeVIP,IsRobotException,CustomerClass)
    SELECT  tmp.CustID
		,	cus.IsLicensee
        ,	cus.IsLicenseeVIP
        ,	CASE WHEN (cus.IsLicensee = 0 AND cus.SiteID = 16) OR (cus.IsLicensee = 0 AND cus.CurrencyID IN (6,13)) THEN 1
				 ELSE 0 
			END AS IsRobotException
        , 	sp.CustomerClass
    FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID  = 0
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = tmp.CustID;
    
    SELECT CustomerClassName
    INTO lv_LicVIP_DangerousCCName
    FROM CustomerCategory
    WHERE CategoryID = CONST_LICVIP_DANGEROUSCATEGORY;
    
	SELECT CustomerClassName
    INTO lv_LicVIP_SuspiciousCCName
    FROM CustomerCategory
    WHERE CategoryID = CONST_LICVIP_SUSPICIOUSCATEGORY;
    
    INSERT INTO Temp_CustCateInfo(CustID,CategoryID,CustomerClass,CustomerClassName,DangerLevel,DangerLevelType)
    SELECT 	tmp.CustID
		,	clss.CategoryID
		,	clss.CustomerClass
        ,	clss.CustomerClassName  
        ,	dangerlvl.DangerLevel
        ,	CASE 
				WHEN dangerlvl.DangerLevel IS NULL THEN 0
				ELSE dangerlvl.DangerLevelType 
			END AS DangerLevelType
    FROM Temp_CustInfo AS tmp,
		LATERAL(SELECT 	CASE WHEN clss.SportGroupID = CONST_GROUP_PROBLEM AND tmp.CustomerClass IS NULL THEN cate.CategoryGroup 
							 ELSE NULL END AS CategoryID
					,	CASE  
							WHEN tmp.CustomerClass IS NULL 
									THEN CASE
											WHEN cate.CustomerClass = CONST_VVIPCC THEN CONST_VVIPCC
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 THEN CONST_LICVIP_SUSPICIOUSCC
                                            WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 THEN CONST_LICVIP_DANGEROUSCC
                                            ELSE cate.CustomerClass
										END
							ELSE tmp.CustomerClass 
						END AS CustomerClass
					,	CASE
							WHEN cate.CustomerClass = CONST_VVIPCC THEN cate.CustomerClassName
							WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 THEN lv_LicVIP_SuspiciousCCName
							WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 THEN lv_LicVIP_DangerousCCName
							ELSE cate.CustomerClassName
						END AS CustomerClassName
				FROM CTS_DataCenter.CTSCustomerClassification AS clss
					INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID
                WHERE clss.CustID = tmp.CustID
					AND clss.SportGroupID IN (CONST_GROUP_PROBLEM, CONST_GROUP_WRAPPER, CONST_GROUP_NORMAL)
                ORDER BY  cate.Priority ASC  
						, clss.LastModifiedDate DESC
                LIMIT 1) AS clss,
		LATERAL(SELECT 	CASE WHEN tmp.IsLicensee = 1 THEN cc.ABIDangerLevel_Licensee
							 WHEN tmp.IsLicensee = 0 THEN cc.ABIDangerLevel_Credit
						 END AS DangerLevel
                    ,	cc.DangerLevelType 
				FROM CTS_DataCenter.CTSCustomerClassification AS c
					INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON c.CategoryID = cc.CategoryID
                WHERE c.CustID = tmp.CustID
					AND c.SportGroupID IN (CONST_GROUP_PROBLEM, CONST_GROUP_NORMAL)
                ORDER BY  cc.Priority ASC  
						, c.LastModifiedDate DESC
                LIMIT 1) AS dangerlvl;
		
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