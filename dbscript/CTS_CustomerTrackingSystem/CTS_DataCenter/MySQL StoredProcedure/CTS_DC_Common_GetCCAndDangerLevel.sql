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
			- 20240923@Jonas.Huynh:		Change CC Priority of Robot- Potential Risk  [RedmineID: #209792]	
			- 20240930@Casey.Huynh: 	Return Agency CC and Danger [Redmine ID: #185799]
            
        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_Common_GetCCAndDangerLevel('1275, 5, 4178, 1264');
                       
	*/ 
    #=========================Member Define==========================================
    DECLARE CONST_ROLEID_MEMBER					SMALLINT DEFAULT 1;   
    
	DECLARE	CONST_PARENTID_PA 					INT;
	DECLARE	CONST_PARENTID_WRAPPER				INT;
	
	DECLARE	CONST_CATEID_VVIP					INT;
	DECLARE	CONST_CATEID_LICBA					INT;
	DECLARE	CONST_CATEID_LICVIPSUSPICIOUS		INT;
	DECLARE	CONST_CATEID_LICVIPDANGEROUS		INT;
	DECLARE	CONST_BIZCATEGROUPID_NORMAL			INT;

    DECLARE	lv_LicVIP_DangerousCCName 			VARCHAR(50);
    DECLARE	lv_LicVIP_SuspiciousCCName			VARCHAR(50);
    DECLARE	lv_LicBACC_Name						VARCHAR(50);
    DECLARE lv_LicBACC							INT UNSIGNED;
    DECLARE lv_LicBAPriority					SMALLINT UNSIGNED;
    DECLARE lv_LicVIPCC_Danger					INT UNSIGNED;
    DECLARE lv_LicVIPCC_Suspicious				INT UNSIGNED;
    DECLARE lv_VVIPCC							INT UNSIGNED; 
	    
	DECLARE	CONST_SITEID_EVOIO					INT;
	DECLARE CONST_SITEID_INDO 					INT;
	DECLARE	CONST_CATEID_NEW					INT;
	DECLARE	CONST_CURRENCYID_USDT				INT;
	DECLARE CONST_CURRENCYID_EURO 				INT;	   
       
    #=========================Agency Define==========================================        
    DECLARE CONST_ROLEID_AGENT					SMALLINT DEFAULT 2;
    DECLARE CONST_ROLEID_MASTER					SMALLINT DEFAULT 3;
    DECLARE CONST_ROLEID_SUPER					SMALLINT DEFAULT 4;
      
    DECLARE	CONST_AGENCY_PARENTID_PA 			INT;
    
	DECLARE	CONST_AGENCY_CATEID_VVIP			INT;
	DECLARE	CONST_AGENCY_CATEID_LICBA			INT;

    DECLARE lv_Agency_VVIPCC					INT UNSIGNED; 
    
    #===================================GET Staticlist Define constant for Member====================================================================        
	SET CONST_PARENTID_PA 				    	= CTS_DC_CategoryTypeParent_Get('CONST_PARENTID_PA');
	SET CONST_PARENTID_WRAPPER 					= CTS_DC_CategoryTypeParent_Get('CONST_PARENTID_WRAPPER');
	SET CONST_CATEID_VVIP 						= CTS_DC_CategoryTypeParent_Get('CONST_CATEID_VVIP');
	SET CONST_CATEID_LICBA 						= CTS_DC_CategoryTypeParent_Get('CONST_CATEID_LICBA');
	SET CONST_CATEID_LICVIPSUSPICIOUS 			= CTS_DC_CategoryTypeParent_Get('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_CATEID_LICVIPDANGEROUS 			= CTS_DC_CategoryTypeParent_Get('CONST_CATEID_LICVIPDANGEROUS');
	SET CONST_BIZCATEGROUPID_NORMAL 			= CTS_DC_CategoryTypeParent_Get ('CONST_BIZCATEGROUPID_NORMAL');
    
	SET CONST_SITEID_EVOIO			    		= 1763; --  EVOIO site
	SET CONST_SITEID_INDO			    		= 11; --  INDO site
	SET CONST_CATEID_NEW 				    	= 200;
	SET CONST_CURRENCYID_USDT 					= 96;
	SET CONST_CURRENCYID_EURO 					= 6;

	#===================================GET Staticlist Define constant for Agency==================================================================== 
    SET CONST_AGENCY_PARENTID_PA 				    	= CTS_DC_CategoryTypeParent_Get('CONST_AGENCY_PARENTID_PA');
	SET CONST_AGENCY_CATEID_VVIP 						= CTS_DC_CategoryTypeParent_Get('CONST_AGENCY_CATEID_VVIP');
	SET CONST_AGENCY_CATEID_LICBA 						= CTS_DC_CategoryTypeParent_Get('CONST_AGENCY_CATEID_LICBA');
	
    #=====================SCHEMA=======================
    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
    CREATE TEMPORARY TABLE 		Temp_CustInfo(
        	CustID						BIGINT UNSIGNED PRIMARY KEY 
		,	RoleID						SMALLINT
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
        
        , INDEX IX_Temp_CustInfo_RoleID(RoleID)
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCateInfo;
    CREATE TEMPORARY TABLE 		Temp_CustCateInfo(
        	CustID				BIGINT UNSIGNED PRIMARY KEY
		,	CategoryID			INT        
		,	IsDangerProbation	BIT DEFAULT 0
		,	CustomerClass		INT
        ,	CustomerClassName  	VARCHAR(50)
		,	ParentID			INT
		,	TaggingType			SMALLINT
        ,	DangerLevel			INT
		,	DangerLevelType		SMALLINT
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustLatestCate;
    CREATE TEMPORARY TABLE 		Temp_CustLatestCate(
        	CustID				BIGINT UNSIGNED PRIMARY KEY
		,	LatesCCPriority   	SMALLINT DEFAULT -1  
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustClassificationInfo;
    CREATE TEMPORARY TABLE 		Temp_CustClassificationInfo(
			ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
        ,	CustID				BIGINT UNSIGNED
        ,	RoleID				SMALLINT
		,	CategoryID			INT
		,	CustomerClass		INT
        ,	CustomerClassName  	VARCHAR(50)
		,	ParentID			INT
		,	TaggingType			SMALLINT
        ,	DangerLevel			INT
		,	DangerLevelType		SMALLINT
        ,	INDEX 				IX_Temp_CustClassificationInfo_CustID(CustID)
    );  
    
    /* START */
    INSERT IGNORE INTO Temp_CustInfo(CustID, RoleID, IsLicensee,IsLicenseeVIP,IsLicenseeBA,IsRobotException,SpecialCC)
    SELECT  tmp.CustID
		,	cus.RoleID
		,	cus.IsLicensee
        ,	cus.IsLicenseeVIP
        ,	cus.IsLicenseeBA
        ,	CASE WHEN(cus.IsLicensee = 0 AND cus.SiteID = 16) OR(cus.IsLicensee = 0 AND cus.CurrencyID IN(6,13)) THEN 1
				 ELSE 0 
			END AS IsRobotException
        , 	sp.CustomerClass
    FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS(CustID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID  = 0
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = tmp.CustID;
     
	/* ==========================GET MEMBER CC INFO================================================= */    
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
	WHERE tmp.RoleID = CONST_ROLEID_MEMBER
	GROUP BY tmp.CustID;
        
    INSERT INTO Temp_CustCateInfo(CustID,CategoryID,CustomerClass,CustomerClassName,ParentID,TaggingType,DangerLevel,DangerLevelType)
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
    FROM Temp_CustInfo AS tmp
		INNER JOIN Temp_CustLatestCate AS t ON tmp.CustID = t.CustID,
		LATERAL(SELECT 	CASE WHEN clss.ParentID = CONST_PARENTID_PA 
								AND cate.BusinessCategoryGroupID <> CONST_BIZCATEGROUPID_NORMAL 
								AND tmp.SpecialCC IS NULL THEN cate.Ext_CategoryGroupID 
							 ELSE NULL END AS CategoryID
					,	CASE  
							WHEN(tmp.SpecialCC IS NULL) OR(tmp.SpecialCCPriority <> -1)
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
							WHEN(tmp.SpecialCC IS NULL) OR(tmp.SpecialCCPriority <> -1)
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
                
                
    # =================GET AGENCY CC INFO====================================================================
        
     /* INIT MEMBER AGENCY */    

    SELECT CustomerClass
    INTO lv_Agency_VVIPCC
    FROM CustomerCategoryAgency WHERE CategoryID = CONST_AGENCY_CATEID_VVIP;
      
	INSERT INTO Temp_CustLatestCate(CustID,LatesCCPriority)
    SELECT tmp.CustID, MIN(clss.CustomerClassPriority)
    FROM Temp_CustInfo AS tmp
	,	LATERAL(SELECT 	cate.CustomerClassPriority
				FROM CTS_DataCenter.CTSCustomerClassificationAgency AS clss
					INNER JOIN CTS_DataCenter.CustomerCategoryAgency AS cate ON clss.CategoryID = cate.CategoryID AND cate.IsActive = 1
                WHERE clss.CustID = tmp.CustID
                ORDER BY  cate.CustomerClassPriority ASC  
						, clss.LastModifiedDate DESC
                LIMIT 1) AS clss
	WHERE tmp.RoleID IN (CONST_ROLEID_AGENT, CONST_ROLEID_MASTER,CONST_ROLEID_SUPER)
	GROUP BY tmp.CustID;
        
    INSERT INTO Temp_CustCateInfo(CustID,CategoryID,CustomerClass,CustomerClassName,ParentID,TaggingType,DangerLevel,DangerLevelType)
    SELECT 	tmp.CustID
		,	clss.CategoryID
		,	clss.CustomerClass
        ,	clss.CustomerClassName  
		,	clss.ParentID
		,	NULL TaggingType
        ,	dangerlvl.DangerLevel
        ,	CASE 
				WHEN dangerlvl.DangerLevel IS NULL THEN 0
				ELSE dangerlvl.Ext_DangerLevelType 
			END AS DangerLevelType
    FROM Temp_CustInfo AS tmp
		INNER JOIN Temp_CustLatestCate AS t ON tmp.CustID = t.CustID,
		LATERAL(SELECT 	CASE WHEN clss.ParentID = CONST_AGENCY_PARENTID_PA THEN cate.Ext_CategoryGroupID 
							 ELSE NULL END AS CategoryID
					,	CASE WHEN cate.CustomerClass = lv_Agency_VVIPCC THEN lv_Agency_VVIPCC 
							ELSE cate.CustomerClass						
						END AS CustomerClass
					,	CASE WHEN cate.CustomerClass = lv_Agency_VVIPCC THEN cate.CustomerClassName
							ELSE cate.CustomerClassName
						END AS CustomerClassName
					,	cate.ParentID
				FROM CTS_DataCenter.CTSCustomerClassificationAgency AS clss
					INNER JOIN CTS_DataCenter.CustomerCategoryAgency AS cate ON clss.CategoryID = cate.CategoryID AND cate.IsActive = 1
                WHERE clss.CustID = tmp.CustID
                ORDER BY  cate.CustomerClassPriority ASC  
						, clss.LastModifiedDate DESC
                LIMIT 1) AS clss,
		LATERAL(SELECT 	CASE WHEN tmp.IsLicensee = 0 THEN cc.Ext_ABIDangerLevel_Credit
						 END AS DangerLevel
                    ,	cc.Ext_DangerLevelType 
				FROM CTS_DataCenter.CTSCustomerClassificationAgency AS c
					INNER JOIN CTS_DataCenter.CustomerCategoryAgency AS cc ON c.CategoryID = cc.CategoryID AND cc.IsActive = 1
                WHERE c.CustID = tmp.CustID			
                ORDER BY  cc.CustomerClassPriority ASC  
						, c.LastModifiedDate DESC
                LIMIT 1) AS dangerlvl;         
    #=========================================================================================================            
	INSERT INTO Temp_CustClassificationInfo(CustID, RoleID, CategoryID, CustomerClass, CustomerClassName, ParentID, TaggingType, DangerLevel, DangerLevelType)	
	SELECT 	tmp.CustID
		,	tmp.RoleID
		,	cate.CategoryID        
		,	IFNULL(cate.CustomerClass,-1) AS CustomerClass
        ,	cate.CustomerClassName  
		,	cate.ParentID
		,	cate.TaggingType
		CASE
    		WHEN cate.DangerLevelType = 1 THEN
				CASE
					-- AC01: Members from EVOIO site, All CC (except New member CC200) will be set to Ori 18
					WHEN c.SiteID = CONST_SITEID_EVOIO AND IFNULL(cate.CustomerClass, -1) <> CONST_CATEID_NEW 
					THEN 18
					-- AC02: Licensee members using USDT and EURO currency (exclusive of members from EVOIO) with Suspicious, Dangerous, Problems, Robot Class will be set to Ori 19
					WHEN c.IsLicensee = 1
					    AND c.SiteID <> CONST_SITEID_EVOIO -- exclusive of members from EVOIO
					    AND c.CurrencyID IN (CONST_CURRENCYID_USDT, CONST_CURRENCYID_EURO)
					    AND (
                    		cate.CustomerClassName LIKE '%Suspicious%'
                 			OR cate.CustomerClassName LIKE '%Danger%'
                 			OR cate.CustomerClassName LIKE '%Problem%'
                 			OR cate.CustomerClassName LIKE '%Robot%'
                 			)
					THEN 19
					WHEN c.SiteID = CONST_SITEID_INDO
						AND IFNULL(cate.CustomerClass, -1) IN (
							203, 2303, 2005, 2105, 2205, 2305,
							2600, 2700, 2800, 204, 205, 2304,
							301, 3101, 302, 303, 304, 300, 2100, 2300
						)
					THEN 17
					WHEN (cate.CategoryName LIKE '%Good%' OR cate.CategoryName LIKE '%Normal%')
     						AND (cate.DangerLevel = 17 OR cate.DangerLevel = 19)
					THEN 0

                	ELSE cate.DangerLevel
            	END
    		ELSE cate.DangerLevel
		END AS DangerLevel
        ,	cate.DangerLevelType
    FROM Temp_CustInfo AS tmp
		LEFT JOIN Temp_CustCateInfo AS cate ON tmp.CustID = cate.CustID;
		LEFT JOIN CTSCustomer c ON tmp.CustID = c.CustID;
END$$

DELIMITER ;