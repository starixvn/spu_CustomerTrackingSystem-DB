/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Common_GetCCAndDangerLevel`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Common_GetCCAndDangerLevel`(
	IN ip_CustIDs LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN 
	/*
		Created:	20220930@Aries.Nguyen	
		Task :		Renovate Association Detection
		DB:			CTS_DataCenter  
		Original: 
		Revisions:
			- 20220930@Aries.Nguyen: 	Created [RedmineID: #178311]
			- 20230118@Victoria.Le: 	Return ParentID & TaggingType to definite whether Customer is Problem Account/Normal Categories links with PA [RedmineID: #181995]
			- 20240319@Casey.Huynh: 	Classify Danger Score [Redmine ID: #201358]
            - 20240424@Thomas.Nguyen:	Classify Initial Group Betting - Add ParentID = 150, SportGroupID = 150 [Redmine ID: #200854]
			- 20240628@Thomas.Nguyen:	Renovate CC phase 2 - Remove hardcode ParentID [Redmine ID: #205317]

        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_Common_GetCCAndDangerLevel('1,2,1277,555555');
	*/ 
	DECLARE	CONST_PARENTID_PA 					INT;
	DECLARE	CONST_PARENTID_POTENTIALPA 			INT;
	DECLARE	CONST_PARENTID_WRAPPER				INT;
    
	DECLARE	CONST_CATEID_VVIP					INT;
	DECLARE	CONST_CATEID_LICBA					INT;
	DECLARE	CONST_CATEID_LICVIPSUSPICIOUS		INT;
	DECLARE	CONST_CATEID_LICVIPDANGEROUS		INT;

    DECLARE	lv_LicVIP_DangerousCCName 			VARCHAR(50);
    DECLARE	lv_LicVIP_SuspiciousCCName			VARCHAR(50);
    DECLARE	lv_LicBACC_Name						VARCHAR(50);
    DECLARE lv_LicBACC							SMALLINT UNSIGNED;
    DECLARE lv_LicBAPriority					SMALLINT UNSIGNED;
    DECLARE lv_LicVIPCC_Danger					SMALLINT UNSIGNED;
    DECLARE lv_LicVIPCC_Suspicious				SMALLINT UNSIGNED;
    DECLARE lv_VVIPCC							SMALLINT UNSIGNED;
    
	SET CONST_PARENTID_PA 				    	= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
    SET CONST_PARENTID_POTENTIALPA 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_POTENTIALPA');
	SET CONST_PARENTID_WRAPPER 					= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_CATEID_VVIP 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	SET CONST_CATEID_LICBA 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
	SET CONST_CATEID_LICVIPSUSPICIOUS 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_CATEID_LICVIPDANGEROUS 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');

    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
    CREATE TEMPORARY TABLE 		Temp_CustInfo (
        	CustID						BIGINT UNSIGNED PRIMARY KEY 
		,	IsLicensee					BIT 
		,	IsLicenseeVIP				BIT 
		,	IsLicenseeBA				BIT 				
		,	IsRobotException 			BIT 
		,   SpecialCC	       			INT  
        ,	SpecialCCName				VARCHAR(50)
		,   SpecialCCPriority   		SMALLINT DEFAULT -1
		,   SpecialCCDangerProbation   	BIT DEFAULT NULL
		,	DangerLevel					INT  
		,	DangerLevelType				INT  
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCateInfo;
    CREATE TEMPORARY TABLE 		Temp_CustCateInfo (
        	CustID				BIGINT UNSIGNED PRIMARY KEY
		,	CategoryID			INT        
		,	IsDangerProbation	BIT DEFAULT 0
		,	CustomerClass		INT
        ,	CustomerClassName  	VARCHAR(50)
		,	ParentID			INT
		,	TaggingType			SMALLINT
        ,	DangerLevel			INT
		,	DangerLevelType		SMALLINT 
		,	IsRobot				BIT(1)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustLatestCate;
    CREATE TEMPORARY TABLE 		Temp_CustLatestCate (
        	CustID				BIGINT UNSIGNED PRIMARY KEY
		,	LatesCCPriority   	SMALLINT DEFAULT -1  
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustClassificationInfo;
    CREATE TEMPORARY TABLE 		Temp_CustClassificationInfo (
			ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
        ,	CustID				BIGINT UNSIGNED 
		,	CategoryID			INT
		,	CustomerClass		INT
        ,	CustomerClassName  	VARCHAR(50)
		,	ParentID			INT
        ,	CategoryType		TINYINT
		,	TaggingType			SMALLINT
        ,	DangerLevel			INT
		,	DangerLevelType		SMALLINT     
		,	IsRobot				BIT(1)
        ,	INDEX 				IX_Temp_CustClassificationInfo_CustID(CustID)
    );  
     
	/* INIT */    
    SELECT CustomerClass, CustomerClassPriority, CustomerClassName
    INTO lv_LicBACC, lv_LicBAPriority, lv_LicBACC_Name
    FROM CustomerCategory WHERE CategoryID = CONST_CATEID_LICBA;
    
    SELECT CustomerClass, CustomerClassName
    INTO lv_LicVIPCC_Danger, lv_LicVIP_DangerousCCName
    FROM CustomerCategory WHERE CategoryID = CONST_CATEID_LICVIPDANGEROUS;
    
    SELECT CustomerClass, CustomerClassName
    INTO lv_LicVIPCC_Suspicious, lv_LicVIP_SuspiciousCCName
    FROM CustomerCategory WHERE CategoryID = CONST_CATEID_LICVIPSUSPICIOUS;    
    
    SELECT CustomerClass
    INTO lv_VVIPCC
    FROM CustomerCategory WHERE CategoryID = CONST_CATEID_VVIP;
    
    /* START */
    INSERT IGNORE INTO Temp_CustInfo (CustID,IsLicensee,IsLicenseeVIP,IsLicenseeBA,IsRobotException,SpecialCC)
    SELECT  tmp.CustID
		,	cus.IsLicensee
        ,	cus.IsLicenseeVIP
        ,	cus.IsLicenseeBA
        ,	CASE WHEN (cus.IsLicensee = 0 AND cus.SiteID = 16) OR (cus.IsLicensee = 0 AND cus.CurrencyID IN (6,13)) THEN 1
				 ELSE 0 
			END AS IsRobotException
        , 	sp.CustomerClass
    FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID  = 0
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = tmp.CustID;
    
	INSERT INTO Temp_CustLatestCate(CustID,LatesCCPriority)
    SELECT tmp.CustID, MIN(clss.CustomerClassPriority)
    FROM Temp_CustInfo AS tmp,
		LATERAL(SELECT 	cate.CustomerClassPriority
				FROM CTS_DataCenter.CTSCustomerClassification AS clss
					INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.IsActive = 1
                WHERE clss.CustID = tmp.CustID
					AND clss.ParentID <> CONST_PARENTID_WRAPPER
                ORDER BY  cate.CustomerClassPriority ASC  
						, clss.LastModifiedDate DESC
                LIMIT 1) AS clss
	GROUP BY tmp.CustID;
        
    INSERT INTO Temp_CustCateInfo(CustID,CategoryID,CustomerClass,CustomerClassName,ParentID,TaggingType,DangerLevel,DangerLevelType,IsRobot)
    SELECT 	tmp.CustID
		,	clss.CategoryID
		,	clss.CustomerClass
        ,	clss.CustomerClassName  
		,	clss.ParentID
		,	clss.TaggingType
        ,	dangerlvl.DangerLevel
        ,	CASE 
				WHEN dangerlvl.DangerLevel IS NULL THEN 0
				ELSE dangerlvl.Ext_DangerLevelType 
			END AS DangerLevelType
		,	clss.IsRobot
    FROM Temp_CustInfo AS tmp
		INNER JOIN Temp_CustLatestCate AS t ON tmp.CustID = t.CustID,
		LATERAL(SELECT 	CASE WHEN clss.ParentID = CONST_PARENTID_PA AND tmp.SpecialCC IS NULL THEN cate.Ext_CategoryGroupID 
							 ELSE NULL END AS CategoryID
					,	CASE  
							WHEN (tmp.SpecialCC IS NULL) OR (tmp.SpecialCCPriority <> -1)
									THEN CASE
											WHEN cate.CustomerClass = lv_VVIPCC THEN lv_VVIPCC
											WHEN tmp.IsLicenseeVIP = 1 AND t.LatesCCPriority > tmp.SpecialCCPriority AND tmp.SpecialCCDangerProbation = 1 THEN lv_LicVIPCC_Suspicious
                                            WHEN tmp.IsLicenseeVIP = 1 AND t.LatesCCPriority > tmp.SpecialCCPriority AND tmp.SpecialCCDangerProbation IS NOT NULL THEN lv_LicVIPCC_Danger
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 THEN lv_LicVIPCC_Suspicious
                                            WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 THEN lv_LicVIPCC_Danger
                                            WHEN tmp.IsLicenseeBA = 1 AND cate.CustomerClassPriority > lv_LicBAPriority THEN lv_LicBACC                                            
                                            WHEN tmp.SpecialCCPriority <> -1 AND cate.CustomerClassPriority > tmp.SpecialCCPriority THEN tmp.SpecialCC
                                            ELSE cate.CustomerClass
										END
							ELSE tmp.SpecialCC
						END AS CustomerClass
					,	CASE  
							WHEN (tmp.SpecialCC IS NULL) OR (tmp.SpecialCCPriority <> -1)
									THEN CASE
											WHEN cate.CustomerClass = lv_VVIPCC THEN cate.CustomerClassName
											WHEN tmp.IsLicenseeVIP = 1 AND t.LatesCCPriority > tmp.SpecialCCPriority AND tmp.SpecialCCDangerProbation = 1 THEN lv_LicVIP_SuspiciousCCName
                                            WHEN tmp.IsLicenseeVIP = 1 AND t.LatesCCPriority > tmp.SpecialCCPriority AND tmp.SpecialCCDangerProbation = 0 THEN lv_LicVIP_DangerousCCName
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 THEN lv_LicVIP_SuspiciousCCName
                                            WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 THEN lv_LicVIP_DangerousCCName
                                            WHEN tmp.IsLicenseeBA = 1 AND cate.CustomerClassPriority > lv_LicBAPriority THEN lv_LicBACC_Name                                            
                                            WHEN tmp.SpecialCCPriority <> -1 AND cate.CustomerClassPriority > tmp.SpecialCCPriority THEN tmp.SpecialCCName
                                            ELSE cate.CustomerClassName
										END
							ELSE tmp.SpecialCCName
						END AS CustomerClassName
					,	cate.ParentID
					,	cate.TaggingType
					,	CASE WHEN cate.CustomerClassName = 'Robot' THEN 1 ELSE 0 END AS IsRobot
				FROM CTS_DataCenter.CTSCustomerClassification AS clss
					INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.IsActive = 1
                WHERE clss.CustID = tmp.CustID
                ORDER BY  cate.CustomerClassPriority ASC  
						, clss.LastModifiedDate DESC
                LIMIT 1) AS clss,
		LATERAL(SELECT 	CASE WHEN tmp.IsLicensee = 1 THEN cc.Ext_ABIDangerLevel_Licensee
							 WHEN tmp.IsLicensee = 0 THEN cc.Ext_ABIDangerLevel_Credit
						 END AS DangerLevel
                    ,	cc.Ext_DangerLevelType 
				FROM CTS_DataCenter.CTSCustomerClassification AS c
					INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON c.CategoryID = cc.CategoryID AND cc.IsActive = 1
                WHERE c.CustID = tmp.CustID
					AND c.ParentID <> CONST_PARENTID_WRAPPER
                ORDER BY  cc.CustomerClassPriority ASC  
						, c.LastModifiedDate DESC
                LIMIT 1) AS dangerlvl;
                
	INSERT INTO Temp_CustClassificationInfo(CustID, CategoryID, CustomerClass, CustomerClassName, ParentID, CategoryType, TaggingType, DangerLevel, DangerLevelType, IsRobot)	
	SELECT 	tmp.CustID
		,	cate.CategoryID        
		,	IFNULL(cate.CustomerClass,-1) AS CustomerClass
        ,	cate.CustomerClassName  
		,	cate.ParentID
        ,	(CASE 	WHEN cate.ParentID = CONST_PARENTID_POTENTIALPA THEN 2
					WHEN cate.ParentID = CONST_PARENTID_PA THEN 1
                    ELSE 3 END ) AS CategoryType
		,	cate.TaggingType
        ,	cate.DangerLevel
        ,	cate.DangerLevelType
		,	cate.IsRobot
    FROM Temp_CustInfo AS tmp
		LEFT JOIN Temp_CustCateInfo AS cate ON tmp.CustID = cate.CustID;
END$$

DELIMITER ;