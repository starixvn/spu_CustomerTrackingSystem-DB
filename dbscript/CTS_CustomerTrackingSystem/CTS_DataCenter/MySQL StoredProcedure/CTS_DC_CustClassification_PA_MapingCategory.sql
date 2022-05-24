/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin,ctsService,ctsAPIAdmin,ctsAPI,ctsWebAdmin,ctsWeb" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_PA_MapingCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_MapingCategory`(
		IN 		ip_ByType		VARCHAR(20)	#"Category, Reason, Evidence"
    ,	IN 		ip_CustInfo 	JSON
	
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created: 20220328@Aries.Nguyen
		Task: Add new category/class for PA Probation [Redmine ID: #170468]
		DB: CTS_DataCenter
        
		Original:
		Revisions:
			- 20220328@Aries.Nguyen: Created [Redmine ID: #170468]
            - 20220505@Aries.Nguyen: Classification History - Wrong store Source Type for mark/remove PA [Redmine ID: #172401]
			- 20220426@Casey.Huynh: Return CreatedBy [Redmine ID: #171512]
            - 20220519@Casey.Huynh: Renovate PA Process [Redmine ID: #172061]
		Param's Explanation (filtered by):      
			- CALL CTS_DC_CustClassification_PA_MapingCategory ('[{"CustID": 123,"ReasonID": -1,"WinlossStatus": 1,"TurnoverRM":100,"WinlossRM":10,"BetCount":15,"ActiveDays":10}]','NAP');
*/     
    DROP TEMPORARY TABLE IF EXISTS Temp_PA;    
	CREATE TEMPORARY TABLE Temp_PA(	  
		/*Cust info*/
			CustID					BIGINT UNSIGNED 
		, 	CTSCustID				BIGINT UNSIGNED DEFAULT 0
        ,	RoleID					INT
        , 	SubscriberID			INT DEFAULT 0
        ,	IsLicensee				BOOLEAN
        ,	Remark 					VARCHAR(500)        
        ,	CreatedBy 				INT UNSIGNED
        
        /*Data warehouse, mainDB  info*/
        , 	WinlossStatus			SMALLINT /*LOSING  = 0, KEEPSTATE = 1, WINNING = 2;*/
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT 
        
        /*Get Mapping Value*/
		, 	CategoryID		    	SMALLINT
        ,	CategoryGroup     		SMALLINT
        ,	Reason					INT
        ,	IsDirectPA				BOOLEAN
        ,	IsProbation				BOOLEAN DEFAULT 0	          
		,	TargetCC				SMALLINT
		,	TargetDangerLevel		SMALLINT UNSIGNED
		, 	ToEvidenceID			SMALLINT        
        ,	IsFromTVS				BOOLEAN DEFAULT 0
        ,	IsFromTW				BOOLEAN DEFAULT 0
        ,	IsFromPAM				BOOLEAN DEFAULT 0
        ,	IsDataChanged			BOOLEAN DEFAULT 0 # 0: Not Change, 1: Changed (IF call from SpecialCC function THEN 1 ELSE 0)
        ,	DataChangeType			TINYINT DEFAULT 0 # 0: New OR Change Category, 1: Change Probation Status, 2: NOT CHANGE
        ,	OldCategoryID		    SMALLINT
        ,	RelevantCategoryID		SMALLINT	
        ,	RelevantCategoryGroup	SMALLINT	
        , 	PRIMARY KEY     		PK_Temp_PA(CustID,CategoryID)  
    );  
   
    IF ip_ByType = 'Category' THEN      
	INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, RoleID, SubscriberID, CategoryID, CategoryGroup, RelevantCategoryID, IsLicensee, CreatedBy, Remark, IsDirectPA
		, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsFromTW, IsFromPAM, IsDataChanged, TargetCC, TargetDangerLevel, ToEvidenceID, IsProbation )	
	SELECT 	DISTINCT tmpJs.CustID
		,	tmpJs.CTSCustID
		,	tmpJs.RoleID
		, 	tmpJs.SubscriberID
		,	tmpJs.CategoryID
		,	tmpJs.CategoryGroup
		,	cat.RelevantCategoryID
		,	tmpJs.IsLicensee
		,	tmpJs.CreatedBy 
		,	tmpJs.Remark
		,	tmpJs.IsDirectPA
		, 	tmpJs.WinlossStatus 
		, 	tmpJs.TurnoverRM
		, 	tmpJs.WinlossRM 
		, 	tmpJs.BetCount 
		, 	tmpJs.ActiveDays
		,	tmpJs.IsFromTVS
        ,	tmpJs.IsFromTW
        ,	tmpJs.IsFromPAM
		,	tmpJs.IsDataChanged
		,	(CASE 	WHEN sp.CTSCustID IS NOT NULL THEN sp.CustomerClass ELSE IFNULL(cat.CustomerClass,-99) END) AS TargetCC
		,	(CASE 	WHEN tmpJs.IsLicensee = 1 THEN cat.ABIDangerLevel_Licensee
					WHEN tmpJs.IsLicensee = 0 THEN cat.ABIDangerLevel_Credit END) AS TargetDangerLevel
		,	(CASE 	WHEN tmpJs.IsLicensee = 1 THEN cat.EvidenceID_Licensee
					WHEN tmpJs.IsLicensee = 0 THEN cat.EvidenceID_Credit
					ELSE NULL END) AS ToEvidenceID
		,	(CASE WHEN WinlossStatus = 0 THEN 1 ELSE 0 END) AS IsProbation            
	FROM JSON_TABLE(ip_CustInfo,
		"$[*]" COLUMNS(
				CustID 			BIGINT UNSIGNED		PATH "$.CustID"
			,	CTSCustID 		BIGINT UNSIGNED		PATH "$.CTSCustID"
			,	RoleID 			INT					PATH "$.RoleID" 
			,	SubscriberID 	BIGINT UNSIGNED		PATH "$.SubscriberID"
			,	CategoryID		BIGINT UNSIGNED		PATH "$.CategoryID"
			,	CategoryGroup	BIGINT UNSIGNED		PATH "$.CategoryGroup"
			,	IsLicensee		BOOLEAN				PATH "$.IsLicensee"
			, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
			, 	Remark			VARCHAR(500)		PATH "$.Remark"
			, 	IsDirectPA		BOOLEAN				PATH "$.IsDirectPA"
			,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus" 
			,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
			,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
			, 	BetCount		BIGINT 				PATH "$.BetCount"
			, 	ActiveDays		INT 				PATH "$.ActiveDays"
			, 	IsFromTVS		BOOLEAN 			PATH "$.IsFromTVS"
            , 	IsFromTW		BOOLEAN 			PATH "$.IsFromTW"
            , 	IsFromPAM		BOOLEAN 			PATH "$.IsFromPAM"
			, 	IsDataChanged	BOOLEAN 			PATH "$.IsDataChanged"   
			
	)) AS tmpJs
		LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on tmpJs.CTSCustID = pin.CTSCustID # Exclude IF Cust is Pin Category
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CTSCustID = sp.CTSCustID 
		INNER JOIN CTS_DataCenter.CustomerCategory  AS cat ON cat.CategoryID = tmpJs.CategoryID
		WHERE pin.CTSCustID IS NULL;
	
		UPDATE Temp_PA AS tmpPA
		INNER JOIN CTS_DataCenter.CustomerCategory  AS cat ON cat.CategoryID = tmpPA.RelevantCategoryID
        SET tmpPA.RelevantCategoryGroup = cat.CategoryGroup;
    END IF;   

    IF ip_ByType = 'Reason' THEN 
	INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, RoleID, SubscriberID, CategoryID, CategoryGroup, RelevantCategoryID, IsLicensee, CreatedBy, Remark, IsDirectPA
		, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS,  TargetCC, TargetDangerLevel, ToEvidenceID, IsProbation )	
	SELECT 	DISTINCT tmpJs.CustID
		,	cus.CTSCustID
		,	cus.RoleID
		, 	cus.SubscriberID
		,	cat.CategoryID    
		,	cat.CategoryGroup
		,	cat.RelevantCategoryID
		,	cus.IsLicensee
		,	tmpJs.CreatedBy 
		,	NULL AS Remark
		,	tmpJs.IsDirectPA
		, 	tmpJs.WinlossStatus 
		, 	tmpJs.TurnoverRM
		, 	tmpJs.WinlossRM 
		, 	tmpJs.BetCount 
		, 	tmpJs.ActiveDays
		,	tmpJs.IsFromTVS
		,	(CASE 	WHEN sp.CTSCustID IS NOT NULL THEN sp.CustomerClass ELSE IFNULL(cat.CustomerClass,-99) END) AS TargetCC
		,	(CASE 	WHEN cus.IsLicensee = 1 THEN cat.ABIDangerLevel_Licensee
					WHEN cus.IsLicensee = 0 THEN cat.ABIDangerLevel_Credit END) AS TargetDangerLevel
		,	(CASE 	WHEN cus.IsLicensee = 1 THEN cat.EvidenceID_Licensee
					WHEN cus.IsLicensee = 0 THEN cat.EvidenceID_Credit
					ELSE NULL END) AS ToEvidenceID
		,	(CASE WHEN WinlossStatus = 0 THEN 1 ELSE 0 END) AS IsProbation            
	FROM JSON_TABLE(ip_CustInfo,
		"$[*]" COLUMNS(
				CustID 			BIGINT UNSIGNED		PATH "$.CustID"
			,	ReasonID		INT 				PATH "$.ReasonID"
			, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
            , 	IsDirectPA		BOOLEAN				PATH "$.IsDirectPA"
			,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus" 
			,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
			,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
			, 	BetCount		BIGINT 				PATH "$.BetCount"
			, 	ActiveDays		INT 				PATH "$.ActiveDays"
			, 	IsFromTVS		BOOLEAN 			PATH "$.IsFromTVS"
            , 	IsFromTW		BOOLEAN 			PATH "$.IsFromTW"
            , 	IsFromPAM		BOOLEAN 			PATH "$.IsFromPAM"
	)) AS tmpJs
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
		LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on cus.CTSCustID = pin.CTSCustID # Exclude IF Cust is Pin Category
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON cus.CTSCustID = sp.CTSCustID 
		INNER JOIN CTS_DataCenter.CustomerCategory  AS cat ON cat.ReasonID = tmpJs.ReasonID
		WHERE pin.CTSCustID IS NULL AND cus.IsInternal = 0;
		
        /*
		UPDATE Temp_PA AS tmpPA
		INNER JOIN CTS_DataCenter.CustomerCategory  AS cat ON cat.CategoryID = tmpPA.RelevantCategoryID
        SET tmpPA.RelevantCategoryGroup = cat.CategoryGroup;*/
            
		/*	2: EXCLUDE CUSTOMER */    
		CALL CTS_DC_ExcludeCustByCondition('Temp_PA');  
	END IF;


END$$
DELIMITER ;