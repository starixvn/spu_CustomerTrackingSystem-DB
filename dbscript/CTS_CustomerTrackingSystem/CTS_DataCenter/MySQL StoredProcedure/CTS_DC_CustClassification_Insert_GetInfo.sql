/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert_GetInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert_GetInfo`(
		IN	ip_InputFlowID			INT 
		IN	ip_FromAction			TINYINT
		IN	ip_CustInfo				JSON
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
	
	IF ip_InputFlowID IN (1,2,3,4) THEN /*ip_InputFlowID: VVIP/SpecialCC/LicVIP/LicBA*/
	
		DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
		CREATE TEMPORARY TABLE 	Temp_Customer (
				CustID						BIGINT UNSIGNED  
			, 	CTSCustID					BIGINT UNSIGNED
			,	SubscriberID 				INT UNSIGNED
			,	RoleID						INT		
			,	Remark						VARCHAR(500)
			,	CreatedBy					BIGINT UNSIGNED
			,	IsExistVVIP					BIT(1) DEFAULT 0
			,	IsLicenseeVIP				BIT(1) DEFAULT 0
			,	IsLicenseeBA				BIT(1) DEFAULT 0
			,	IsDirect					BIT(1) DEFAULT 0
			,	CustomerClass				SMALLINT UNSIGNED
			,	PRIMARY KEY (CustID)
		);
		
		DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;
		CREATE TEMPORARY TABLE 	Temp_NewClassification (
				CustID						BIGINT UNSIGNED  
			, 	CTSCustID					BIGINT UNSIGNED
			,	SubscriberID 				INT UNSIGNED
			,	RoleID						INT		
			,	Remark						VARCHAR(500)
			,	CreatedBy					BIGINT UNSIGNED
			,	IsExistVVIP					BIT(1) DEFAULT 0
			,	IsLicenseeVIP				BIT(1) DEFAULT 0
			,	IsLicenseeBA				BIT(1) DEFAULT 0
			,	IsDirect					BIT(1) DEFAULT 0
			,	CustomerClass				SMALLINT UNSIGNED
			,	CategoryPriority			SMALLINT UNSIGNED
			,	CustomerClassPriority		SMALLINT UNSIGNED
			,	IsDangerProbation			BIT(1) DEFAULT 0
			,	IsDataChanged				BIT(1) DEFAULT 1	/*0: No change category => No Action*/
			,	PRIMARY KEY (CustID)
		);
	
	ELSEIF ip_InputFlowID IN (5,6,7,8) THEN	/*ip_InputFlowID: PA/PotentialPA/Robot/Normal*/

		DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
		CREATE TEMPORARY TABLE Temp_NewClassification(	  	
				CustID						BIGINT UNSIGNED	PRIMARY KEY
			, 	CTSCustID					BIGINT 
			,	SubscriberID 				INT UNSIGNED
			,	RoleID						INT		
			,	IsLicensee					BIT(1) DEFAULT 0
			,	IsLicenseeVIP				BIT(1) DEFAULT 0
			,	IsLicenseeBA				BIT(1) DEFAULT 0
			,	IsExitsVIP					BIT(1) DEFAULT 0
			
			, 	TurnoverRM					DECIMAL(20,4)
			, 	WinlossRM					DECIMAL(20,4)
			, 	BetCount					BIGINT
			, 	ActiveDays					INT	
			,	PerformanceTime				DATETIME(3)

			, 	DWCategoryID		    	INT UNSIGNED -- InputCategoryID
			,	DWCategoryGroupID   		INT UNSIGNED -- InputCategoryGroupID
			
			, 	NewCategoryID		   		INT UNSIGNED
			,	NewCategoryGroupID     		INT UNSIGNED -- CategoryGroup
			,	NewIsDangerProbation		BIT(1) DEFAULT 0
			,	IsPAProbation	     		BIT(1) DEFAULT 0-- IsProbation
			
			,	OldCategoryID		    	INT UNSIGNED
			,	OldCategoryGroupID	    	INT UNSIGNED
			,	OldIsDangerProbation		BIT(1) DEFAULT 0

			,	ParentID					INT UNSIGNED
			,	OldTargetCC					SMALLINT
			,	TargetCC					SMALLINT
			,	TargetDangerLevel			SMALLINT UNSIGNED
			,	CategoryPriority			SMALLINT UNSIGNED 
			,	CustomerClassPriority		SMALLINT UNSIGNED 
			,	MatchID						INT
			
			, 	ToEvidenceID				SMALLINT
			
			, 	RelevantCategoryID			SMALLINT UNSIGNED
			,	RelevantCategoryGroupID   	SMALLINT UNSIGNED
			,	RelevantIsPAProbation	   	BIT(1) -- RelevantIsProbation
			
			,	IsDataChanged				BIT(1) DEFAULT 1 	/* 0: Not Change, 1: Changed (IF call from SpecialCC function THEN 1 ELSE 0) */
			,	DataChangeType				TINYINT DEFAULT 0	/* 0: New OR Change Category, 1: Change Probation Status, 2: NOT CHANGE */

			, 	WinlossStatus				SMALLINT /*LOSING  = 0 (PROBATION), KEEPSTATE = 1 (NOT CHANGE), WINNING = 2 (NOT PROBATION);*/
			,	IsFromOldPA					BIT(1) DEFAULT 0
			,	IsExisted					BIT(1) DEFAULT 0 -- Robot
			
			,	IsFromTVS					BIT(1)  DEFAULT 0
			,	TVSRequestID				BIGINT UNSIGNED
			, 	TVSReasonID		   			INT
			,	TVSSportType				SMALLINT DEFAULT NULL 
			,	TVSIssueTypeID 				TINYINT DEFAULT NULL 
			,	IsTVSParlay					BIT(1) DEFAULT NULL
			
			,	IsFromCTS					BIT(1)  DEFAULT 0
			,	IsFromAI					BIT(1)  DEFAULT 0
			,	IsFromImperva				BIT(1) 	DEFAULT 0

			,	IsFromTW					BIT(1)  DEFAULT 0
			,	TWRobotCounter				INT -- RobotCounter
			,	TWBetCount					BIGINT
			,	TWGroupBettingRate			DECIMAL(10,4)
			,	TWTicketRejectRate			DECIMAL(10,4)
			,	TWDesktopUsageRate			DECIMAL(10,4)
			
			,	TaggingID					SMALLINT
			,	TaggingType					SMALLINT	
			,	ScanTaggingType				TINYINT DEFAULT 0

			,   SpecialCC	       			SMALLINT  
			,	SpecialCCName				VARCHAR(50)
			,   SpecialCCPriority   		SMALLINT DEFAULT -1
			,   SpecialCCDangerProbation   	BIT(1) DEFAULT NULL
			
			,	LastModifiedDate			DATETIME(3)
			, 	ActionType					SMALLINT DEFAULT 0 /* 0: Insert; 1: Update, 3: Ignore Exist PA, 4: Ignore PIN; 5: Not satisfy Pass Probation*/

			, 	PRIMARY KEY (CustID, DWCategoryGroupID)  
		); 
	
	END IF;
	
	
END$$
DELIMITER ;