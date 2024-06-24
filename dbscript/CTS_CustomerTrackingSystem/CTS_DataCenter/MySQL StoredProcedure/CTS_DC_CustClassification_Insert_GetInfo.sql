/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert_GetInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert_GetInfo`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_FromAction			TINYINT
	,	IN	ip_CustInfo				JSON
	,	OUT op_MaxCTSCustID			BIGINT
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

	DECLARE CONST_CATEID_VVIP 				INT;
	DECLARE CONST_CATEID_LICVIPSUSPICIOUS 	INT;
	DECLARE CONST_CATEID_LICVIPDANGEROUS 	INT;
	DECLARE CONST_CATEID_LICBA 				INT;
	
    DECLARE lv_MaxCTSCustID					BIGINT UNSIGNED;
    DECLARE lv_LicVIPPriority				SMALLINT UNSIGNED;
    DECLARE lv_LicBAPriority				SMALLINT UNSIGNED;
	
	SET CONST_CATEID_VVIP 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	SET CONST_CATEID_LICVIPSUSPICIOUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_CATEID_LICVIPDANGEROUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
	SET CONST_CATEID_LICBA 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
	
	IF ip_InputFlowID IN (1,2,3,4) THEN /*ip_InputFlowID: VVIP/SpecialCC/LicVIP/LicBA*/
	
		DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;
		CREATE TEMPORARY TABLE 	Temp_NewClassification (
				CustID						BIGINT UNSIGNED  
			, 	CTSCustID					BIGINT UNSIGNED
			,	SubscriberID 				INT UNSIGNED
			,	RoleID						INT		
			,	Remark						VARCHAR(500)
			,	CreatedBy					INT UNSIGNED
			,	IsVVIP						BIT(1) DEFAULT 0
			,	IsLicenseeVIP				BIT(1) DEFAULT 0
			,	IsLicenseeBA				BIT(1) DEFAULT 0
			,	IsDirect					BIT(1) DEFAULT 0
			,	SportID						SMALLINT UNSIGNED  DEFAULT 0	
			,	CustomerClass				SMALLINT UNSIGNED
			,	CategoryPriority			SMALLINT UNSIGNED
			,	CustomerClassPriority		SMALLINT UNSIGNED
			,	CategoryID					INT
			,	Ext_CategoryGroupID			INT
			,	IsDangerProbation			BIT(1) DEFAULT 0
			,	IsDataChanged				BIT(1) DEFAULT 0	/*0: No change category => No Action*/
			,	PRIMARY KEY (CustID,SportID)
		);

		IF ip_InputFlowID = 1 THEN /*VVIP*/
			INSERT INTO Temp_NewClassification (CustID, CTSCustID, SubscriberID, RoleID, Remark, CreatedBy, IsVVIP, IsDirect)
			SELECT DISTINCT 
					temp.CustID, temp.CTSCustID, temp.SubscriberID, temp.RoleID, temp.CreatedBy, temp.Remark
				,	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsVVIP
				,	(CASE WHEN ip_FromAction = 1 THEN 1 ELSE 0 END) AS IsDirect
			FROM JSON_TABLE(ip_CustJson,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED	PATH "$.CustID"
												,	CTSCustID 		BIGINT UNSIGNED	PATH "$.CTSCustID"
												,	RoleID			INT				PATH "$.RoleID"
												,	SubscriberID 	INT UNSIGNED	PATH "$.SubscriberID"
												,	CreatedBy 		INT UNSIGNED	PATH "$.CreatedBy"            
												,	Remark			VARCHAR(500)	PATH "$.Remark"
											 )) AS temp
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID 
																				AND cls.CategoryID = CONST_CATEID_VVIP;
			
			SELECT MAX(tmpCus.CTSCustID)
			INTO op_MaxCTSCustID
			FROM Temp_NewClassification AS tmpCus;
			
			
		ELSEIF ip_InputFlowID = 2 THEN /*SpecialCC*/
			INSERT INTO Temp_NewClassification (CustID, CTSCustID, SportID, SubscriberID, Remark, CreatedBy, IsLicenseeVIP, CustomerClass)
			SELECT CustID, CTSCustID, SubscriberID, SportID, Remark, CreatedBy, IsLicenseeVIP, CustomerClass
			FROM JSON_TABLE(ip_CustJson,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED		PATH "$.CustID"
												,	CTSCustID 		BIGINT UNSIGNED		PATH "$.CTSCustID"
												,	SportID			SMALLINT UNSIGNED   PATH '$.SportID'
												,	SubscriberID 	INT UNSIGNED		PATH "$.SubscriberID"
												,	IsLicenseeVIP	BIT(1)				PATH "$.IsLicenseeVIP"            
												,	CustomerClass	SMALLINT			PATH "$.CustomerClass"            
												,	CreatedBy 		INT UNSIGNED		PATH "$.CreatedBy"          
												,	Remark			VARCHAR(500)		PATH "$.Remark"
											 )) AS temp;
			
		ELSEIF ip_InputFlowID = 3 THEN	/*LicVIP*/
			INSERT INTO Temp_NewClassification (CustID, CTSCustID, SubscriberID, CreatedBy, IsLicenseeVIP)
			SELECT temp.CustID, temp.CTSCustID, temp.SubscriberID, temp.CreatedBy
				,	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsLicenseeVIP
			FROM JSON_TABLE(ip_CustJson,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED	PATH "$.CustID"
												,	CreatedBy 		INT UNSIGNED	PATH "$.CreatedBy"
											 )) AS temp
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON  temp.CustID = cus.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID 
																				AND cls.CategoryID IN (CONST_CATEID_LICVIPSUSPICIOUS,CONST_CATEID_LICVIPDANGEROUS);
			
			
		ELSEIF ip_InputFlowID = 4 THEN /*LicBA*/
			INSERT INTO Temp_NewClassification (CustID, CTSCustID, SubscriberID, CreatedBy, IsLicenseeBA)
			SELECT temp.CustID, temp.CTSCustID, temp.SubscriberID, temp.CreatedBy
				,	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsLicenseeBA
			FROM JSON_TABLE(ip_CustJson,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED	PATH "$.CustID"
												,	CreatedBy 		INT UNSIGNED	PATH "$.CreatedBy"
											 )) AS temp
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON  temp.CustID = cus.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID 
																				AND cls.CategoryID = CONST_CATEID_LICBA;
		
		END IF;

	ELSE /*IF ip_InputFlowID IN (50,51,6,7,8): PA/PotentialPA/Robot/Normal*/

		DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
		CREATE TEMPORARY TABLE Temp_NewClassification(	  	
				CustID						BIGINT UNSIGNED	PRIMARY KEY
			, 	CTSCustID					BIGINT 
			,	SubscriberID 				INT UNSIGNED
			,	RoleID						INT		
			,	IsLicensee					BIT(1) DEFAULT 0
			,	IsLicenseeVIP				BIT(1) DEFAULT 0
			,	IsLicenseeBA				BIT(1) DEFAULT 0
			,	IsVVIP						BIT(1) DEFAULT 0
			
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
			,	Ext_CategoryGroupID			INT
			,	MatchID						INT
			
			, 	ToEvidenceID				SMALLINT
			
			, 	RelevantCategoryID			SMALLINT UNSIGNED
			,	RelevantCategoryGroupID   	SMALLINT UNSIGNED
			,	RelevantIsPAProbation	   	BIT(1) -- RelevantIsProbation
			
			,	IsDataChanged				BIT(1) DEFAULT 0 	/* 0: Not Change, 1: Changed (IF call from SpecialCC function THEN 1 ELSE 0) */
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
			,	CreatedBy					INT UNSIGNED
			,	IsDirect					BIT(1) DEFAULT 0

			, 	PRIMARY KEY (CustID, DWCategoryGroupID)  
		); 
		
		IF ip_InputFlowID IN (50,6) THEN /*PA - ip_InputType = 'Category' | PotentialPA*/
			INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, RoleID, SubscriberID, DWCategoryID, DWCategoryGroupID,  IsLicensee, CreatedBy, Remark, IsDirect
			, 	WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsDataChanged
			, 	SpecialCC, IsPAProbation, RelevantCategoryID, LastModifiedDate, MatchID, TVSRequestID, IsTVSParlay, SportType
			, 	TVSIssueTypeID, CategoryPriority, CustomerClassPriority, ParentID, IsVVIP)
			SELECT 	tmpJs.CustID
				,	tmpJs.CTSCustID
				,	tmpJs.RoleID
				, 	tmpJs.SubscriberID
				,	tmpJs.CategoryID
				,	tmpJs.CategoryGroupID
				,	tmpJs.IsLicensee
				,	tmpJs.CreatedBy 
				,	(CASE WHEN tmpJs.MatchID IS NOT NULL THEN CONCAT('Auto MatchID: ', MatchID) ELSE tmpJs.Remark END) AS Remark
				,	tmpJs.IsDirect
				, 	IFNULL(tmpJs.WinlossStatus,2) AS  WinlossStatus
				, 	tmpJs.TurnoverRM
				, 	tmpJs.WinlossRM 
				, 	tmpJs.BetCount 
				, 	tmpJs.ActiveDays
				,	tmpJs.IsFromTVS
				,	tmpJs.IsFromTW
				,	tmpJs.IsFromCTS
				,	tmpJs.IsFromAI
				,	tmpJs.IsDataChanged
				,	sp.CustomerClass AS SpecialCC
				,	cat.IsPAProbation		
				,	cat.RelevantCategoryID
				,	tmpJs.LastModifiedDate
				,	tmpJs.MatchID
				,	CASE WHEN IFNULL(tmpJs.TVSRequestID,0) = 0 AND tmpJs.IsFromTVS = 0 THEN NULL
						 ELSE tmpJs.TVSRequestID END AS TVSRequestID
				,	tmpJs.IsTVSParlay
				,	tmpJs.SportType
				,	tmpJs.TVSIssueTypeID
				,	cat.CategoryPriority
				,	cat.CustomerClassPriority
				,	cat.ParentID
				,	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsVVIP
			FROM JSON_TABLE(ip_CustInfo,
							"$[*]" COLUMNS(
												CustID 				BIGINT UNSIGNED		PATH "$.CustID"
											,	CTSCustID 			BIGINT UNSIGNED		PATH "$.CTSCustID"
											,	RoleID 				INT					PATH "$.RoleID" 
											,	SubscriberID 		INT UNSIGNED		PATH "$.SubscriberID"
											,	DWCategoryID		INT UNSIGNED		PATH "$.CategoryID"
											,	DWCategoryGroupID	INT UNSIGNED		PATH "$.CategoryGroup"
											,	IsLicensee			BIT(1)				PATH "$.IsLicensee"
											, 	CreatedBy			INT UNSIGNED		PATH "$.CreatedBy"
											, 	Remark				VARCHAR(500)		PATH "$.Remark"
											, 	IsDirect			BOOLEAN				PATH "$.IsDirectPA"
											,	WinlossStatus		SMALLINT 			PATH "$.WinlossStatus" 
											,	TurnoverRM			DECIMAL(20,4)		PATH "$.TurnoverRM"
											,	WinlossRM			DECIMAL(20,4) 		PATH "$.WinlossRM"
											, 	BetCount			BIGINT 				PATH "$.BetCount"
											, 	ActiveDays			INT 				PATH "$.ActiveDays"
											, 	IsFromTVS			BIT(1) 				PATH "$.IsFromTVS"
											, 	IsFromTW			BIT(1) 				PATH "$.IsFromTW"
											, 	IsFromCTS			BIT(1) 				PATH "$.IsFromCTS"
											, 	IsFromAI			BIT(1) 				PATH "$.IsFromAI"
											, 	IsDataChanged		BIT(1) 				PATH "$.IsDataChanged"
											, 	LastModifiedDate	DATETIME(3)			PATH "$.LastModifiedDate"
											, 	MatchID				INT 				PATH "$.MatchID"	
											, 	TVSRequestID		BIGINT UNSIGNED		PATH "$.TVSRequestID"
											,	IsTVSParlay			BIT(1)  			PATH "$.IsParlay"
											,	TVSIssueTypeID		TINYINT 			PATH "$.IssueTypeID"
											,	SportType			SMALLINT 			PATH "$.SportType"
											)) AS tmpJs
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls on tmpJs.CustID = cls.CustID AND cls.CategoryID = CONST_CATEID_VVIP
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID 
				LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = tmpJs.CategoryID;	
			
			
		ELSEIF ip_InputFlowID = 51 THEN /*PA - ip_InputType = 'Reason'*/
			INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, RoleID, SubscriberID, DWCategoryID, DWCategoryGroupID,  IsLicensee, CreatedBy, IsDirect
			, 	WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsDataChanged, SpecialCC, IsPAProbation
			, 	RelevantCategoryID, TVSRequestID, IsTVSParlay, SportType, TVSIssueTypeID, CategoryPriority, CustomerClassPriority
			, 	ParentID, IsVVIP)
			SELECT 	tmpJs.CustID
				,	cus.CTSCustID
				,	cus.RoleID
				, 	cus.SubscriberID
				,	cat.CategoryID
				,	cat.CategoryGroupID
				,	cus.IsLicensee
				,	tmpJs.CreatedBy 
				,	tmpJs.IsDirect
				, 	IFNULL(tmpJs.WinlossStatus,2) AS  WinlossStatus
				, 	tmpJs.TurnoverRM
				, 	tmpJs.WinlossRM 
				, 	tmpJs.BetCount 
				, 	tmpJs.ActiveDays
				,	tmpJs.IsFromTVS
				,	tmpJs.IsDataChanged
				,	sp.CustomerClass AS SpecialCC
				,	cat.IsPAProbation		
				,	cat.RelevantCategoryID
				,	CASE WHEN IFNULL(tmpJs.TVSRequestID,0) = 0 AND tmpJs.IsFromTVS = 0 THEN NULL
						 ELSE tmpJs.TVSRequestID END AS TVSRequestID
				,	tmpJs.IsTVSParlay
				,	tmpJs.SportType
				,	tmpJs.TVSIssueTypeID
				,	cat.CategoryPriority
				,	cat.CustomerClassPriority
				,	cat.ParentID
				,	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsVVIP
			FROM JSON_TABLE(ip_CustInfo,
							"$[*]" COLUMNS(
												CustID 			BIGINT UNSIGNED		PATH "$.CustID"
											,	TVSReasonID		INT 				PATH "$.ReasonID"
											, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
											, 	IsDirect		BIT(1)				PATH "$.IsDirectPA"
											,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus" 
											,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
											,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
											, 	BetCount		BIGINT 				PATH "$.BetCount"
											, 	ActiveDays		INT 				PATH "$.ActiveDays"
											, 	IsFromTVS		BIT(1) 				PATH "$.IsFromTVS"
											, 	IsFromTW		BIT(1) 				PATH "$.IsFromTW"
											, 	IsFromCTS		BIT(1) 				PATH "$.IsFromCTS"
											, 	IsFromAI		BIT(1) 				PATH "$.IsFromAI"
											, 	TVSRequestID	BIGINT UNSIGNED		PATH "$.TVSRequestID"
											, 	Remark			VARCHAR(500) 		PATH "$.Remark"
											,	IsTVSParlay		BIT(1)	 			PATH "$.IsParlay"
											,	SportType		SMALLINT 			PATH "$.SportType"
											,	TVSIssueTypeID	TINYINT 			PATH "$.IssueTypeID"
										)) AS tmpJs
				LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls on tmpJs.CustID = cls.CustID AND cls.CategoryID = CONST_CATEID_VVIP
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID 
				LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.TVSReasonID = tmpJs.TVSReasonID;	
		
		ELSEIF ip_InputFlowID = 7 THEN /*Robot*/
			INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, SubscriberID, DWCategoryID, DWCategoryGroupID,  IsLicensee, CreatedBy, Remark, IsDirect
			, 	WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsDataChanged
			, 	SpecialCC, IsPAProbation, RelevantCategoryID, TVSRequestID, IsTVSParlay, SportType, TVSIssueTypeID, CategoryPriority
			, 	CustomerClassPriority, ParentID, IsVVIP, TWRobotCounter, IsFromImperva)
			SELECT 	tmpJs.CustID
				,	tmpJs.CTSCustID
				, 	tmpJs.SubscriberID
				,	tmpJs.CategoryID
				,	tmpJs.CategoryGroupID
				,	tmpJs.IsLicensee
				,	tmpJs.CreatedBy 
				,	(CASE WHEN tmpJs.MatchID IS NOT NULL THEN CONCAT('Auto MatchID: ', MatchID) ELSE tmpJs.Remark END) AS Remark
				,	tmpJs.IsDirect
				, 	IFNULL(tmpJs.WinlossStatus,2) AS  WinlossStatus
				, 	tmpJs.TurnoverRM
				, 	tmpJs.WinlossRM 
				, 	tmpJs.BetCount 
				, 	tmpJs.ActiveDays
				,	tmpJs.IsFromTVS
				,	tmpJs.IsFromTW
				,	tmpJs.IsFromCTS
				,	tmpJs.IsFromAI
				,	tmpJs.IsDataChanged
				,	sp.CustomerClass AS SpecialCC
				,	cat.IsPAProbation		
				,	cat.RelevantCategoryID
				,	CASE WHEN IFNULL(tmpJs.TVSRequestID,0) = 0 AND tmpJs.IsFromTVS = 0 THEN NULL
						 ELSE tmpJs.TVSRequestID END AS TVSRequestID
				,	tmpJs.IsTVSParlay
				,	tmpJs.SportType
				,	tmpJs.TVSIssueTypeID
				,	cat.CategoryPriority
				,	cat.CustomerClassPriority
				,	cat.ParentID
				,	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsVVIP
				,	tmpJs.TWRobotCounter
				,	tmpJs.IsFromImperva
			FROM JSON_TABLE(ip_CustInfo,
							"$[*]" COLUMNS(
												CustID 			BIGINT UNSIGNED		PATH "$.CustID"                
											,	TWRobotCounter	INT 				PATH "$.RobotCounter"
											,	CategoryID	    INT UNSIGNED		PATH "$.CategoryID"
											
											,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus"	
											,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
											,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
											, 	BetCount		BIGINT 				PATH "$.BetCount"
											, 	ActiveDays		INT 				PATH "$.ActiveDays"

											, 	IsFromTW		BIT(1)  			PATH "$.IsFromTW"
											, 	IsFromCTS		BIT(1)  			PATH "$.IsFromCTS"
											, 	IsFromAI		BIT(1)  			PATH "$.IsFromAI"
											, 	IsFromTVS		BIT(1)  			PATH "$.IsFromTVS"
											,	IsFromImperva	BIT(1) 				PATH "$.IsFromImperva"
											, 	TVSRequestID	BIGINT UNSIGNED 	PATH "$.TVSRequestID"
											, 	IsDirect		BIT(1)  			PATH "$.IsDirect"

											, 	Remark			VARCHAR(500)		PATH "$.Remark"
											, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
											,	IsTVSParlay		BIT(1) 				PATH "$.IsParlay"
											,	SportType		SMALLINT			PATH "$.SportType"
											,	TVSIssueTypeID	TINYINT				PATH "$.IssueTypeID"
										)) AS tmpJs
				LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls on tmpJs.CustID = cls.CustID AND cls.CategoryID = CONST_CATEID_VVIP
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID 
				LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = tmpJs.CategoryID;	
				
		ELSEIF ip_InputFlowID = 8 THEN /*Normal*/
			INSERT INTO Temp_NewClassification(
				CustID,CTSCustID,DWCategoryGroupID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TWBetCount,TWGroupBettingRate
				,TWTicketRejectRate,TWDesktopUsageRate,TaggingID,TaggingType,PerformanceTime,ScanTaggingType
				,SubscriberID,IsLicensee,IsLicenseeVIP,IsLicenseeBA,IsVVIP)
			SELECT DISTINCT
					tmpJs.CustID
				,	cust.CTSCustID
				, 	tmpJs.DWCategoryGroupID
                , 	tmpJs.TurnoverRM
                , 	tmpJs.WinlossRM
                , 	tmpJs.BetCount
                , 	tmpJs.ActiveDays
                ,	tmpJs.TWBetCount
                , 	tmpJs.TWGroupBettingRate
                , 	tmpJs.TWTicketRejectRate
                , 	tmpJs.TWDesktopUsageRate
                ,	IFNULL(tmpJs.TaggingID, -99)
                , 	tmpJs.TaggingType
                ,	tmpJs.PerformanceTime
                ,	tmpJs.ScanTaggingType
				,	cust.SubscriberID
				,	cust.IsLicensee
				,	cust.IsLicenseeVIP
				,	cust.IsLicenseeBA
				,	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsVVIP
			FROM JSON_TABLE(ip_CustInfo,
							"$[*]" COLUMNS(
												CustID 					BIGINT UNSIGNED		PATH "$.CustId"
											, 	DWCategoryGroupID		SMALLINT UNSIGNED	PATH "$.CategoryId"
											, 	TurnoverRM				DECIMAL(20,4)		PATH "$.TurnoverRM"
											, 	WinlossRM				DECIMAL(20,4)		PATH "$.WinlossRM"
											, 	BetCount				BIGINT				PATH "$.BetCount"
											, 	ActiveDays				INT					PATH "$.ActiveDays"		
											,	TWBetCount				BIGINT				PATH "$.TWBetCount"
											,	TWGroupBettingRate		DECIMAL(10,4)		PATH "$.TWGroupBettingRate"
											,	TWTicketRejectRate		DECIMAL(10,4)		PATH "$.TWTicketRejectRate"
											,	TWDesktopUsageRate		DECIMAL(10,4)		PATH "$.TWDesktopUsageRate"
											, 	TaggingID				SMALLINT			PATH "$.TaggingID"
											, 	TaggingType				SMALLINT			PATH "$.TaggingType"	
											, 	PerformanceTime			DATETIME			PATH "$.PerformanceTime"
											, 	ScanTaggingType			BIT(1)				PATH "$.ScanTaggingType"
										)) AS tmpJs
				LEFT JOIN CTS_DataCenter.CTSCustomer AS cust ON tmpJs.CustID = cust.CustID AND cust.CustSubID = 0
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls on tmpJs.CustID = cls.CustID AND cls.CategoryID = CONST_CATEID_VVIP
			WHERE tmpJs.DWCategoryGroupID <> 0;
				
		END IF;
		
	END IF;
	
	
END$$
DELIMITER ;