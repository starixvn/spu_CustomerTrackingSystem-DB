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
        ,	IsLicensee				BIT
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
        ,	Reason					SMALLINT
        ,	IsDirectPA				BIT
        ,	IsProbation				BIT DEFAULT 0	          
		,	TargetCC				SMALLINT
		,	TargetDangerLevel		SMALLINT UNSIGNED
		, 	ToEvidenceID			SMALLINT        
        ,	IsFromTVS				BIT DEFAULT 0
        ,	IsFromTW				BIT DEFAULT 0
        ,	IsFromPAM				BIT DEFAULT 0
        ,	IsDataChanged			TINYINT DEFAULT 0  /* 1:From REMOVE Special Classification */
        ,	OldCategoryID		    SMALLINT
        , 	PRIMARY KEY     		PK_Temp_PA(CustID,CategoryID)  
    );  
    
    IF ip_ByType = 'Category' THEN    
		INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, RoleID, SubscriberID, CreatedBy, CategoryID, CategoryGroup, IsProbation
				, TargetCC, TargetDangerLevel, ToEvidenceID, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromPAM, IsDataChanged)
		WITH CTE_CustInfo AS
        (
			SELECT 	DISTINCT tmpJs.CustID
			,	tmpJs.CTSCustID
            ,	tmpJs.RoleID
			, 	tmpJs.SubscriberID			
            ,	tmpJs.CategoryID
            ,	tmpJs.CategoryGroup
            ,	tmpJs.IsLicensee
			,	tmpJs.CreatedBy 
            ,	tmpJs.Remark
            ,	tmpJs.IsDirectPA
			, 	tmpJs.WinlossStatus 
			, 	tmpJs.TurnoverRM
			, 	tmpJs.WinlossRM 
			, 	tmpJs.BetCount 
			, 	tmpJs.ActiveDays 
			,	(CASE WHEN sp.CTSCustID IS NOT NULL THEN sp.CustomerClass ELSE NULL END) AS SpecialClass
            ,	(CASE WHEN WinlossStatus = 0 THEN 1 ELSE 0 END) AS IsProbation
            ,	tmpJs.IsFromPAM
            ,	tmpJs.IsDataChanged
		FROM JSON_TABLE(ip_CustInfo,
			"$[*]" COLUMNS(
					CustID 			BIGINT UNSIGNED		PATH "$.CustID"
				,	CTSCustID 		BIGINT UNSIGNED		PATH "$.CTSCustID"
                ,	RoleID 			INT					PATH "$.RoleID" 
				,	SubscriberID 	BIGINT UNSIGNED		PATH "$.SubscriberID"
                ,	CategoryID		BIGINT UNSIGNED		PATH "$.CategoryID"
                ,	CategoryGroup	BIGINT UNSIGNED		PATH "$.CategoryGroup"
                ,	IsLicensee		BIT					PATH "$.IsLicensee"
				, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
                , 	Remark			VARCHAR(500)		PATH "$.Remark"
                , 	IsDirectPA		VARCHAR(500)		PATH "$.IsDirectPA"
				,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus" 
				,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
				,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
				, 	BetCount		BIGINT 				PATH "$.BetCount"
				, 	ActiveDays		INT 				PATH "$.ActiveDays"
                , 	IsFromPAM		INT 				PATH "$.IsFromPAM"
                , 	IsDataChanged	INT 				PATH "$.IsDataChanged"             
                
		)) AS tmpJs
			LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on tmpJs.CTSCustID = pin.CTSCustID # Exclude IF Cust is Pin Category
			LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CTSCustID = sp.CTSCustID 
			WHERE pin.CTSCustID IS NULL
		)
        SELECT 	cte.CustID
			,	cte.CTSCustID
            ,	cte.RoleID
			, 	cte.SubscriberID
			,	cte.CreatedBy
			, 	tmpCat.CategoryID
			,	tmpCat.CategoryGroup
			,	cte.IsProbation
            ,	IFNULL(cte.SpecialClass,tmpCat.TargetCC) AS TargetCC                       
            ,	tmpCat.TargetDangerLevel 
            ,	tmpCat.ToEvidenceID
			, 	cte.WinlossStatus 
			, 	cte.TurnoverRM
			, 	cte.WinlossRM 
			, 	cte.BetCount 
			, 	cte.ActiveDays	
            ,	cte.IsFromPAM
            ,	cte.IsDataChanged
		FROM CTE_CustInfo AS cte,
		LATERAL (
				SELECT 	cat.CategoryID
					,	cat.CategoryGroup
					, 	IFNULL(cat.CustomerClass, -99) AS TargetCC
					, 	(CASE WHEN cte.IsLicensee = 1 THEN cat.ABIDangerLevel_Licensee
							WHEN cte.IsLicensee = 0 THEN cat.ABIDangerLevel_Credit				
						END) AS TargetDangerLevel
					,	(CASE WHEN cte.IsLicensee = 1 THEN cat.EvidenceID_Licensee
							 WHEN cte.IsLicensee = 0 THEN cat.EvidenceID_Credit
						ELSE NULL END) AS ToEvidenceID
				FROM CTS_DataCenter.CustomerCategory  AS cat
				WHERE cat.CategoryGroup = cte.CategoryGroup AND cat.IsProbation = cte.IsProbation
                LIMIT 1
			) AS tmpCat;
    END IF;   
   
    IF ip_ByType = 'Reason' THEN
		INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, RoleID, SubscriberID, CreatedBy, CategoryID, CategoryGroup, IsProbation
				, TargetCC, TargetDangerLevel, ToEvidenceID, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays)
		WITH CTE_CustInfo AS
        (
		SELECT 	DISTINCT tmpJs.CustID
            ,	tmpJs.ReasonID
			,	tmpJs.CreatedBy  
			, 	tmpJs.WinlossStatus 
			, 	tmpJs.TurnoverRM
			, 	tmpJs.WinlossRM 
			, 	tmpJs.BetCount 
			, 	tmpJs.ActiveDays 
		FROM JSON_TABLE(ip_CustInfo,
			"$[*]" COLUMNS(
					CustID 			BIGINT UNSIGNED		PATH "$.CustID"
                ,	RoleID 			INT					PATH "$.ReasonID" 
				,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus" 
				,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
				,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
				, 	BetCount		BIGINT 				PATH "$.BetCount"
				, 	ActiveDays		INT 				PATH "$.ActiveDays"
		)) AS tmpJs
			LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on tmpJs.CTSCustID = pin.CTSCustID # Exclude IF Cust is Pin Category
			LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CTSCustID = sp.CTSCustID 
			WHERE pin.CTSCustID IS NULL
		)
        SELECT 	cte.CustID
			,	cte.CTSCustID
            ,	cte.RoleID
			, 	cte.SubscriberID
			,	cte.CreatedBy
			, 	tmpCat.CategoryID
			,	tmpCat.CategoryGroup
			,	cte.IsProbation
            ,	IFNULL(cte.SpecialClass,tmpCat.TargetCC) AS TargetCC                       
            ,	tmpCat.TargetDangerLevel 
            ,	tmpCat.ToEvidenceID
			, 	cte.WinlossStatus 
			, 	cte.TurnoverRM
			, 	cte.WinlossRM 
			, 	cte.BetCount 
			, 	cte.ActiveDays			
		FROM CTE_CustInfo AS cte,
		LATERAL (
				SELECT 	cat.CategoryID
					,	cat.CategoryGroup
					, 	IFNULL(cat.CustomerClass, -99) AS TargetCC
					, 	(CASE WHEN cte.IsLicensee = 1 THEN cat.ABIDangerLevel_Licensee
							WHEN cte.IsLicensee = 0 THEN cat.ABIDangerLevel_Credit				
						END) AS TargetDangerLevel
					,	(CASE WHEN cte.IsLicensee = 1 THEN cat.EvidenceID_Licensee
							 WHEN cte.IsLicensee = 0 THEN cat.EvidenceID_Credit
						ELSE NULL END) AS ToEvidenceID
				FROM CTS_DataCenter.CustomerCategory  AS cat
				WHERE cat.CategoryGroup = tmpJs.CategoryGroup AND cte.IsProbation = cat.IsProbation
			) AS tmpCat;
            
		/*	2: EXCLUDE CUSTOMER */    
		CALL CTS_DC_ExcludeCustByCondition('Temp_PA');  
	END IF;
	
END$$
DELIMITER ;