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
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
	CREATE TEMPORARY TABLE Temp_CustInfo (
		 	CustID						BIGINT UNSIGNED	PRIMARY KEY	
		,   CTSCustID 					BIGINT UNSIGNED
		,	SubscriberID 				INT UNSIGNED
		,	RoleID						INT		
		,	IsLicensee					BIT(1) 
        ,	IsLicenseeVIP				BIT(1)
        ,	IsLicenseeBA				BIT(1)
		,	IsExitsVIP					BIT(1) 
		,	IsDirect					BIT(1)
		,	CreatedBy					BIGINT UNSIGNED
		,	Remark						VARCHAR(300)
		,	SportID						SMALLINT UNSIGNED
		
        ,	INDEX IX_Temp_CustInfo_CTSCustID(CTSCustID)
		,	KEY IX_Temp_CustInfo_SportID (SportID)
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_NewCustomerClass;
	CREATE TEMPORARY TABLE 		Temp_NewCustomerClass (
			CustID						BIGINT UNSIGNED  
		, 	CTSCustID					BIGINT UNSIGNED
		,	CategoryID					INT
		,	IsDangerProbation			BIT(1) 
		,	CategoryPriority			SMALLINT 
		,	CustomerClass				SMALLINT UNSIGNED
		,	IsDataChanged				BIT(1)  DEFAULT 0
		
		,	PRIMARY KEY (CustID, SportID)
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification(	  	
			CustID						BIGINT UNSIGNED	PRIMARY KEY
		, 	CTSCustID					BIGINT DEFAULT 0
		
		, 	WinlossStatus				SMALLINT /*LOSING  = 0 (PROBATION), KEEPSTATE = 1 (NOT CHANGE), WINNING = 2 (NOT PROBATION);*/
		, 	TurnoverRM					DECIMAL(20,4)
		, 	WinlossRM					DECIMAL(20,4)
		, 	BetCount					BIGINT
		, 	ActiveDays					INT	

		, 	DWCategoryID		    	INT UNSIGNED -- InputCategoryID
        ,	DWCategoryGroupID   		INT UNSIGNED -- InputCategoryGroupID
        , 	CategoryID		   			INT UNSIGNED
        ,	CategoryGroupID     		INT UNSIGNED
        ,	ParentID					INT UNSIGNED
        ,	TargetCC					SMALLINT
		,	TargetDangerLevel			SMALLINT UNSIGNED
        ,	CategoryPriority			SMALLINT UNSIGNED -- review
        ,	CCPriority					SMALLINT UNSIGNED -- review
        ,	MatchID						INT
		
        , 	ToEvidenceID				SMALLINT
		
        , 	RelevantCategoryID			SMALLINT UNSIGNED
        ,	RelevantCategoryGroupID   	SMALLINT UNSIGNED
        ,	RelevantIsPAProbation	   	BIT(1) -- RelevantIsProbation
		
		,	OldCategoryID		    	INT UNSIGNED
        ,	IsFromOldPA					BIT(1)	
		
		,	IsDangerProbation			BIT(1) 
        ,	IsPAProbation	     		BIT(1)  -- IsProbation
        ,	IsDataChanged				BIT(1) DEFAULT 0 	# 0: Not Change, 1: Changed (IF call from SpecialCC function THEN 1 ELSE 0)
        ,	DataChangeType				TINYINT DEFAULT 0	# 0: New OR Change Category, 1: Change Probation Status, 2: NOT CHANGE
		
		,	TVSRequestID				BIGINT UNSIGNED
		, 	TVSReasonID		   			INT
		,	TVSSportType				SMALLINT DEFAULT NULL 
		,	TVSIssueTypeID 				TINYINT DEFAULT NULL 
		,	IsFromTVS					BIT(1)  DEFAULT 0
		,	IsTVSParlay					BIT(1) DEFAULT NULL
		
        ,	IsFromCTS					BIT(1)  DEFAULT 0
        ,	IsFromAI					BIT(1)  DEFAULT 0

		,   SpecialCC	       			SMALLINT  
        ,	SpecialCCName				VARCHAR(50)
		,   SpecialCCPriority   		SMALLINT DEFAULT -1
		,   SpecialCCDangerProbation   	BIT(1) DEFAULT NULL

        ,	IsFromTW					BIT(1)  DEFAULT 0
        ,	TWBetCount					BIGINT
        ,	TWGroupBettingRate			DECIMAL(10,4)
        ,	TWTicketRejectRate			DECIMAL(10,4)
        ,	TWDesktopUsageRate			DECIMAL(10,4)
		
        ,	LastModifiedDate			DATETIME(3)
		, 	ActionType					SMALLINT DEFAULT 0 /* 0: Insert; 1: Update, 3: Ignore Exist PA, 4: Ignore PIN; 5: Not satisfy Pass Probation*/

		
		, 	INDEX    			    	IX_Temp_NewClassification(CustID, DWCateGroup)  
	); 
	
END$$
DELIMITER ;