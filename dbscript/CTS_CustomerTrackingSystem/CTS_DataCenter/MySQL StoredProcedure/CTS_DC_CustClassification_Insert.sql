/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert`(
		IN	ip_InputFlowID			INT 
		IN	ip_FromAction			TINYINT
		IN	ip_UplineRoleID			TINYINT
		IN	ip_QueueID				BIGINT
		IN	ip_AffectDownline		BIT(1)
		IN	ip_IsToQueue			BIT(1)
		IN	ip_CustInfo				JSON
		IN	ip_CustomerClass		SMALLINT
		IN	ip_Remark				VARCHAR(500)	
		IN	ip_CreatedBy			INT
		OUT op_ErrorMessage 		VARCHAR(200)
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		
		Revisions: 
			-	20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
		Param's Expanation:
			- 
*/


	DECLARE CONST_CATETYPEID_VVIP 			INT;
	DECLARE CONST_CATETYPEID_WRAPPER 		INT;
	DECLARE CONST_CATETYPEID_PA 			INT;
	DECLARE CONST_CATETYPEID_POTENTIALPA 	INT;
	DECLARE CONST_CATETYPEID_NORMAL 		INT;
	
	SET CONST_CATETYPEID_VVIP 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_VVIP');
	SET CONST_CATETYPEID_WRAPPER 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_WRAPPER');
	SET CONST_CATETYPEID_PA 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_PA');
	SET CONST_CATETYPEID_POTENTIALPA 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_POTENTIALPA');
	SET CONST_CATETYPEID_NORMAL 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATETYPEID_NORMAL');
	
	DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification(	  	
			CustID						BIGINT UNSIGNED	PRIMARY KEY
		, 	CTSCustID					BIGINT DEFAULT 0
		, 	SubscriberID				INT DEFAULT 0     
		,	RoleID						INT		
		,	IsLicensee					BIT(1) 
        ,	IsLicenseeVIP				BIT(1)
        ,	IsLicenseeBA				BIT(1)
        
		,	IsExitsVIP					BIT(1) -- VVIP
		,	IsDirect					BIT(1)
		
		,	SportID						SMALLINT UNSIGNED DEFAULT 0 -- SpecialCC
		,	CustomerClass				SMALLINT UNSIGNED

		,	IsDataChanged				BIT(1) DEFAULT 1 /*0: No change category => No Action*/

		,	IsDangerProbation			BIT(1) -- LicVIP
		,	CategoryID					INT UNSIGNED
		,	CategoryPriority			SMALLINT UNSIGNED  -- Priority
		,	CreatedBy 					INT UNSIGNED
		
		,	ExistCategoryID 			INT UNSIGNED -- PA
		,	CategoryGroupID				INT UNSIGNED
        ,	TargetCC					SMALLINT		
		,	TargetDangerLevel			SMALLINT
		, 	ToEvidenceID				SMALLINT
		,	IsPAProbation				BIT(1) -- IsProbation
        ,	RelevantCategoryID 			SMALLINT UNSIGNED
        ,	RelevantCategoryGroupID		SMALLINT UNSIGNED
		,	RelevantIsPAProbation		BIT(1) -- RelevantIsProbation
        ,	LastModifiedDate			DATETIME(3)
		,	Remark						VARCHAR(500)
		,	IsFromTVS					BIT(1)  DEFAULT 0
        ,	IsFromTW					BIT(1)  DEFAULT 0
        ,	IsFromCTS					BIT(1)  DEFAULT 0
        ,	IsFromAI					BIT(1)  DEFAULT 0
		,	TVSRequestID				BIGINT UNSIGNED
		,	IsTVSParlay					BIT(1) DEFAULT NULL
		,	TVSSportType				SMALLINT DEFAULT NULL 
		,	TVSIssueTypeID 				TINYINT DEFAULT NULL 
        , 	TVSReasonID		   			INT
        ,	IsFromOldPA					BIT(1)	
		,   SpecialCC	       			SMALLINT  
        ,	SpecialCCName				VARCHAR(50)
		,   SpecialCCPriority   		SMALLINT DEFAULT -1
		,   SpecialCCDangerProbation   	BIT(1) DEFAULT NULL
		, 	TurnoverRM					DECIMAL(20,4)
		, 	WinlossStatus				SMALLINT
		, 	WinlossRM					DECIMAL(20,4)
		, 	BetCount					BIGINT
		, 	ActiveDays					INT	
		
        ,	TWBetCount					BIGINT
        ,	TWGroupBettingRate			DECIMAL(10,4)
        ,	TWTicketRejectRate			DECIMAL(10,4)
        ,	TWDesktopUsageRate			DECIMAL(10,4)
		,	TaggingID					SMALLINT
		,	TaggingType					SMALLINT	
		, 	DWCateGroup					SMALLINT
		,	DWCateID					SMALLINT
        ,	OldCateGroup 				SMALLINT
        ,	OldCateID 					SMALLINT
        ,	OldIsDangerProbation		BIT(1) DEFAULT 0
      	, 	NewCateGroup				SMALLINT
		,	NewCateID					SMALLINT
        ,	NewIsDangerProbation		BIT(1) DEFAULT 0
		,	SourceTypeID      			SMALLINT

        ,	OldTargetCC					SMALLINT


		, 	ActionType					SMALLINT DEFAULT 0 /* 0: Insert; 1: Update, 3: Ignore Exist PA, 4: Ignore PIN; 5: Not satisfy Pass Probation*/
        ,	PerformanceTime				DATETIME
        ,	ScanTaggingType				TINYINT DEFAULT 0
        ,	SportType					SMALLINT DEFAULT NULL
		, 	INDEX    			    	IX_Temp_NewClassification(CustID, DWCateGroup)  
	); 
	
END$$
DELIMITER ;