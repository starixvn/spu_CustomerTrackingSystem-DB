/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert_GetInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert_GetInfo`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_CustInfo				JSON
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
	DECLARE CONST_PARENTID_VVIP 			INT;
	DECLARE CONST_PARENTID_WRAPPER 			INT;
	DECLARE CONST_PARENTID_PA 				INT;
	DECLARE CONST_PARENTID_POTENTIALPA		INT;
	
	
    DECLARE lv_MaxCTSCustID					BIGINT UNSIGNED;
	
	SET CONST_CATEID_VVIP 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	SET CONST_CATEID_LICVIPSUSPICIOUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	-- SET CONST_CATEID_LICVIPDANGEROUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
	-- SET CONST_CATEID_LICBA 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
	SET CONST_PARENTID_VVIP 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_VVIP');
	SET CONST_PARENTID_WRAPPER 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_PARENTID_PA 					= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
	SET CONST_PARENTID_POTENTIALPA			= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_POTENTIALPA');
	
	IF ip_InputFlowID IN (1,2,3,4) THEN /*ip_InputFlowID: VVIP/SpecialCC/LicVIP/LicBA*/
	
		DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;
		CREATE TEMPORARY TABLE 	Temp_NewClassification (
				CustID						BIGINT UNSIGNED  
			, 	CTSCustID					BIGINT UNSIGNED
			,	SubscriberID 				INT UNSIGNED
			,	RoleID						INT		
			,	Remark						VARCHAR(500)
			,	CreatedBy					INT UNSIGNED
			,	IsExistVVIP					BIT(1) DEFAULT 0
			,	IsLicenseeVIP				BIT(1) DEFAULT 0
			,	IsLicenseeBA				BIT(1) DEFAULT 0
			,	TargetCC					SMALLINT UNSIGNED
			,	CategoryPriority			SMALLINT UNSIGNED
			,	CustomerClassPriority		SMALLINT UNSIGNED
			,	NewCategoryID				INT
			,	ParentID					INT UNSIGNED
			,	IsDangerProbation			BIT(1) DEFAULT 0
			,	IsDataChanged				BIT(1) DEFAULT 0	/*0: No change category => No Action*/
			,	IsReturnData				BIT(1) DEFAULT 0
			,	PRIMARY KEY (CustID)
		);
		
		DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
		CREATE TEMPORARY TABLE Temp_Customer (
				CustID						BIGINT UNSIGNED PRIMARY KEY
			, 	CTSCustID					BIGINT UNSIGNED
			, 	SubscriberID				INT 
			,	RoleID						INT	
			,	CreatedBy 					INT UNSIGNED
			,	IsLicenseeVIP				BIT(1) DEFAULT 0
			, 	IsLicenseeBA				INT 
		);

		IF ip_InputFlowID = 1 THEN /*VVIP*/
			INSERT INTO Temp_NewClassification (
					CustID, CTSCustID, SubscriberID, RoleID, Remark, CreatedBy, IsExistVVIP, ParentID, NewCategoryID, IsReturnData)
			SELECT DISTINCT 
					tmpJs.CustID, tmpJs.CTSCustID, tmpJs.SubscriberID, tmpJs.RoleID, tmpJs.Remark, tmpJs.CreatedBy
				,	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsExistVVIP
				,	CONST_PARENTID_VVIP
				,	CONST_CATEID_VVIP
				,	(CASE WHEN cls.CustID IS NOT NULL THEN 0 ELSE 1 END) AS IsReturnData
			FROM JSON_TABLE(ip_CustInfo,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED	PATH "$.CustID"
												,	CTSCustID 		BIGINT UNSIGNED	PATH "$.CTSCustID"
												,	RoleID			INT				PATH "$.RoleID"
												,	SubscriberID 	INT UNSIGNED	PATH "$.SubscriberID"
												,	CreatedBy 		INT UNSIGNED	PATH "$.CreatedBy"            
												,	Remark			VARCHAR(500)	PATH "$.Remark"
											 )) AS tmpJs
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON tmpJs.CustID = cls.CustID 
																				AND cls.ParentID = CONST_PARENTID_VVIP;
																				
		ELSEIF ip_InputFlowID = 2 THEN /*SpecialCC*/
			INSERT INTO Temp_NewClassification (
				CustID, CTSCustID, SubscriberID, RoleID, Remark, CreatedBy, IsLicenseeVIP, TargetCC, IsDataChanged, IsReturnData)
			SELECT 	tmpJs.CustID, tmpJs.CTSCustID, tmpJs.SubscriberID, cus.RoleID, tmpJs.Remark, tmpJs.CreatedBy, tmpJs.IsLicenseeVIP, tmpJs.TargetCC
				, 	CASE WHEN tmpJs.IsLicenseeVIP = 1 AND cls.CustID IS NOT NULL THEN 1 ELSE 0  END AS IsDataChanged
				, 	1 AS IsReturnData
			FROM JSON_TABLE(ip_CustInfo,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED		PATH "$.CustID"
												,	CTSCustID 		BIGINT UNSIGNED		PATH "$.CTSCustID"
												,	SubscriberID 	INT UNSIGNED		PATH "$.SubscriberID"
												,	IsLicenseeVIP	BIT(1)				PATH "$.IsLicenseeVIP"            
												,	TargetCC		SMALLINT			PATH "$.CustomerClass"            
												,	CreatedBy 		INT UNSIGNED		PATH "$.CreatedBy"          
												,	Remark			VARCHAR(500)		PATH "$.Remark"
											 )) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON cls.CustID = tmpJs.CustID
																				AND cls.CategoryID = CONST_CATEID_LICVIPSUSPICIOUS;
			
		ELSEIF ip_InputFlowID = 3 THEN	/*LicVIP*/
			INSERT INTO Temp_Customer (CustID, CTSCustID, SubscriberID, RoleID, CreatedBy, IsLicenseeVIP)
			SELECT tmpJs.CustID, cus.CTSCustID, cus.SubscriberID, cus.RoleID, tmpJs.CreatedBy, cus.IsLicenseeVIP
			FROM JSON_TABLE(ip_CustInfo,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED	PATH "$.CustID"
												,	CreatedBy 		INT UNSIGNED	PATH "$.CreatedBy"
											 )) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0;
			
			
		ELSEIF ip_InputFlowID = 4 THEN /*LicBA*/
			INSERT INTO Temp_Customer (CustID, CTSCustID, SubscriberID, RoleID, CreatedBy, IsLicenseeBA)
			SELECT tmpJs.CustID, cus.CTSCustID, cus.SubscriberID, cus.RoleID, tmpJs.CreatedBy, cus.IsLicenseeBA
			FROM JSON_TABLE(ip_CustInfo,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED	PATH "$.CustID"
												,	CreatedBy 		INT UNSIGNED	PATH "$.CreatedBy"
											 )) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON  tmpJs.CustID = cus.CustID AND cus.CustSubID = 0;
		
		END IF;

	ELSE /*IF ip_InputFlowID IN (50,51,6,7,8): PA/PotentialPA/Robot/Normal*/

		DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
		CREATE TEMPORARY TABLE Temp_NewClassification(	  	
				CustID						BIGINT UNSIGNED
			, 	CTSCustID					BIGINT 
			,	SubscriberID 				INT UNSIGNED
			,	RoleID						INT		
			,	IsLicensee					BIT(1) DEFAULT 0
			,	IsLicenseeVIP				BIT(1) DEFAULT 0
			,	IsLicenseeBA				BIT(1) DEFAULT 0
			,	IsExistVVIP					BIT(1) DEFAULT 0
			,	IsExistWrapper				BIT(1) DEFAULT 0
			,	IsExistPA					BIT(1) DEFAULT 0
			,	IsExistPotentialPA			BIT(1) DEFAULT 0
			-- ,	IsExistRobot				BIT(1) DEFAULT 0 
			-- ,	IsExistKeepOldCateID		BIT(1) DEFAULT 0 
			,	IsFromOldPA					BIT(1) DEFAULT 0
			
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
			-- ,	OldIsDangerProbation		BIT(1) DEFAULT 0

			,	ParentID					INT UNSIGNED
			,	OldTargetCC					SMALLINT
			,	TargetCC					SMALLINT
			,	TargetDangerLevel			SMALLINT UNSIGNED
			,	CategoryPriority			SMALLINT UNSIGNED 
			,	CustomerClassPriority		SMALLINT UNSIGNED 
			,	MatchID						INT
			
			, 	ToEvidenceID				SMALLINT
			
			, 	RelevantCategoryID			INT UNSIGNED
			,	RelevantCategoryGroupID   	INT UNSIGNED
			,	RelevantIsPAProbation	   	BIT(1) -- RelevantIsProbation
			
			,	IsDataChanged				BIT(1) 	/* 0: Not Change, 1: Changed (IF call from SpecialCC function THEN 1 ELSE 0) */
			,	DataChangeType				TINYINT DEFAULT 0	/* 0: New OR Change Category, 1: Change Probation Status, 2: NOT CHANGE */
			,	SourceTypeID      			SMALLINT

			, 	WinlossStatus				SMALLINT /*LOSING  = 0 (PROBATION), KEEPSTATE = 1 (NOT CHANGE), WINNING = 2 (NOT PROBATION);*/
			
			,	IsFromTVS					BIT(1)  DEFAULT 0
			,	TVSRequestID				BIGINT UNSIGNED
			, 	TVSReasonID		   			INT
			,	TVSIssueTypeID 				TINYINT DEFAULT NULL 
			,	IsTVSParlay					BIT(1) DEFAULT NULL
			,	SportType					SMALLINT DEFAULT NULL 
			
			,	SourceCreatedDate			DATETIME(3)
			,	GBTicketCount				INT

			,	IsFromTW					BIT(1)  DEFAULT 0
			,	TWRobotCounter				INT -- RobotCounter
			
			,	TWBetCount					BIGINT
			,	TWGroupBettingRate			DECIMAL(10,4)
			,	TWTicketRejectRate			DECIMAL(10,4)
			,	TWDesktopUsageRate			DECIMAL(10,4)
			
			,	IsFromCTS					BIT(1)  DEFAULT 0
			,	IsFromAI					BIT(1)  DEFAULT 0
			,	IsFromImperva				BIT(1) 	DEFAULT 0
			
			,	TaggingID					SMALLINT
			,	TaggingType					SMALLINT	
			,	ScanTaggingType				TINYINT DEFAULT 0

			,   SpecialCC	       			SMALLINT  
			,	SpecialCCName				VARCHAR(50)
			,   SpecialCCCatePriority  		SMALLINT DEFAULT -1
			,   SpecialCCDangerProbation   	BIT(1) DEFAULT NULL
			
			,	LastModifiedDate			DATETIME(3)
			, 	ActionType					SMALLINT DEFAULT 0 /* 0: Insert; 1: Update, 3: Ignore Exist PA, 4: Ignore PIN; 5: Not satisfy Pass Probation*/
			,	CreatedBy					INT UNSIGNED
			,	IsMarkedDirectly			BIT(1) DEFAULT 0
			,	IsReturnData				BIT(1) DEFAULT 1
			,	Remark						VARCHAR(500)
			,	GroupName					VARCHAR(100)
			, 	PRIMARY KEY (CustID, DWCategoryID)
		); 
		
		IF ip_InputFlowID IN (50,150) THEN /*PA - ip_InputType = 'Category'*/
			INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, RoleID, SubscriberID, DWCategoryID, DWCategoryGroupID,IsLicensee, IsLicenseeVIP, IsLicenseeBA, CreatedBy, Remark, IsMarkedDirectly
			, 	WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI
			, 	SpecialCC, IsPAProbation, RelevantCategoryID, LastModifiedDate, MatchID, TVSRequestID, IsTVSParlay, SportType
			, 	TVSIssueTypeID, CategoryPriority, CustomerClassPriority, ParentID, IsReturnData, IsDataChanged, PerformanceTime)
			SELECT 	tmpJs.CustID
				,	tmpJs.CTSCustID
				,	tmpJs.RoleID
				, 	tmpJs.SubscriberID
				,	tmpJs.DWCategoryID
				,	cat.CategoryGroupID
				,	tmpJs.IsLicensee
				,	cus.IsLicenseeVIP
				,	cus.IsLicenseeBA
				,	tmpJs.CreatedBy 
				,	(CASE WHEN tmpJs.MatchID IS NOT NULL THEN CONCAT('Auto MatchID: ', MatchID) ELSE tmpJs.Remark END) AS Remark
				,	tmpJs.IsMarkedDirectly
				, 	IFNULL(tmpJs.WinlossStatus,2) AS  WinlossStatus
				, 	tmpJs.TurnoverRM
				, 	tmpJs.WinlossRM 
				, 	tmpJs.BetCount 
				, 	tmpJs.ActiveDays
				,	tmpJs.IsFromTVS
				,	tmpJs.IsFromTW
				,	tmpJs.IsFromCTS
				,	tmpJs.IsFromAI
				,	sp.CustomerClass AS SpecialCC
				,	(CASE WHEN tmpJs.WinlossStatus = 0 THEN 1 ELSE 0 END) AS IsPAProbation	/*1: PROBATION, 0: NOT PROBATION*/
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
				,	1 AS IsReturnData
				,	0 AS IsDataChanged
				,	tmpJs.PerformanceTime
				,	tmpJs.GroupName
			FROM JSON_TABLE(ip_CustInfo,
							"$[*]" COLUMNS(
												CustID 						BIGINT UNSIGNED		PATH "$.CustID"
											,	CTSCustID 					BIGINT UNSIGNED		PATH "$.CTSCustID"
											,	RoleID 						INT					PATH "$.RoleID" 
											,	SubscriberID 				INT UNSIGNED		PATH "$.SubscriberID"
											,	DWCategoryID				INT UNSIGNED		PATH "$.CategoryID"
											,	IsLicensee					BIT(1)				PATH "$.IsLicensee"
											, 	CreatedBy					INT UNSIGNED		PATH "$.CreatedBy"
											, 	Remark						VARCHAR(500)		PATH "$.Remark"
											, 	IsMarkedDirectly			BIT(1)				PATH "$.IsDirectPA"
											,	WinlossStatus				SMALLINT 			PATH "$.WinlossStatus" 
											,	TurnoverRM					DECIMAL(20,4)		PATH "$.TurnoverRM"
											,	WinlossRM					DECIMAL(20,4) 		PATH "$.WinlossRM"
											, 	BetCount					BIGINT 				PATH "$.BetCount"
											, 	ActiveDays					INT 				PATH "$.ActiveDays"
											, 	IsFromTVS					BIT(1) 				PATH "$.IsFromTVS"
											, 	IsFromTW					BIT(1) 				PATH "$.IsFromTW"
											, 	IsFromCTS					BIT(1) 				PATH "$.IsFromCTS"
											, 	IsFromAI					BIT(1) 				PATH "$.IsFromAI"
											, 	LastModifiedDate			DATETIME(3)			PATH "$.LastModifiedDate"
											, 	MatchID						INT 				PATH "$.MatchID"	
											, 	TVSRequestID				BIGINT UNSIGNED		PATH "$.TVSRequestID"
											,	IsTVSParlay					BIT(1)  			PATH "$.IsParlay"
											,	TVSIssueTypeID				TINYINT 			PATH "$.IssueTypeID"
											,	SportType					SMALLINT 			PATH "$.SportType"
											, 	PerformanceTime				DATETIME(3)			PATH "$.PerformanceTime"
											,	GroupName					VARCHAR(100)		PATH "$.GroupName"
											)) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID
				LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = tmpJs.DWCategoryID
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID
			ON DUPLICATE KEY UPDATE TurnoverRM = IFNULL(Temp_NewClassification.TurnoverRM, tmpJs.TurnoverRM)  
								,	WinlossRM = IFNULL(Temp_NewClassification.WinlossRM, tmpJs.WinlossRM)  
								,	BetCount = IFNULL(Temp_NewClassification.BetCount, tmpJs.BetCount)  
								,	ActiveDays = IFNULL(Temp_NewClassification.ActiveDays, tmpJs.ActiveDays)
								,	IsFromTW = CASE WHEN tmpJs.IsFromTW = 1 THEN 1 ELSE Temp_NewClassification.IsFromTW END
								,	IsFromCTS = CASE WHEN tmpJs.IsFromCTS = 1 THEN 1 ELSE Temp_NewClassification.IsFromCTS END
								,	IsFromAI = CASE WHEN tmpJs.IsFromAI = 1 THEN 1 ELSE Temp_NewClassification.IsFromAI END
								,	IsFromTVS = CASE WHEN tmpJs.IsFromTVS = 1 THEN 1 ELSE Temp_NewClassification.IsFromTVS END
								,	IsMarkedDirectly = CASE WHEN tmpJs.IsMarkedDirectly = 1 THEN 1 ELSE Temp_NewClassification.IsMarkedDirectly END
								,	IsTVSParlay = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.IsTVSParlay 
														ELSE Temp_NewClassification.IsTVSParlay END
								,	SportType = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.SportType 
														ELSE Temp_NewClassification.SportType END
								,	CreatedBy = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.CreatedBy 
														ELSE Temp_NewClassification.CreatedBy END
								,	TVSIssueTypeID = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.TVSIssueTypeID 
														ELSE Temp_NewClassification.TVSIssueTypeID END
								,	TVSRequestID = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.TVSRequestID 
														ELSE Temp_NewClassification.TVSRequestID END
								;

		ELSEIF ip_InputFlowID IN (51,151) THEN /*PA - ip_InputType = 'Reason'*/
			
			IF ip_InputFlowID = 51 THEN
				INSERT INTO CTS_DataCenter.TVSVoidRequest_Log(
					TVSRequestID,CustIDs,ReasonID,CreatedBy,CreatedDate,CreatedTime,IsParlay,SportType,IssueTypeID)
				WITH CTECustInfo AS (
					SELECT	tmpJs.TVSRequestID AS TVSRequestID
						,	tmpJs.CustID AS CustID
						,	tmpJs.TVSReasonID AS ReasonID
						,	tmpJs.CreatedBy AS CreatedBy
						,	tmpJs.IsTVSParlay AS IsParlay
						,	tmpJs.SportType AS SportType
						,	tmpJs.TVSIssueTypeID AS IssueTypeID
					FROM JSON_TABLE(ip_CustInfo,
						"$[*]" COLUMNS(
								CustID 			BIGINT UNSIGNED		PATH "$.CustID"
							,	TVSReasonID		INT 				PATH "$.ReasonID"
							, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
							, 	IsFromTVS		BOOLEAN 			PATH "$.IsFromTVS"
							, 	TVSRequestID	BIGINT UNSIGNED		PATH "$.TVSRequestID"
							,	IsTVSParlay		BOOLEAN 			PATH "$.IsParlay"
							,	SportType		SMALLINT 			PATH "$.SportType"
							,	TVSIssueTypeID	TINYINT 			PATH "$.IssueTypeID"
						)) AS tmpJs
						LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.TVSReasonID = tmpJs.TVSReasonID
					WHERE tmpJs.IsFromTVS = 1
				)
				SELECT	TVSRequestID
					,	GROUP_CONCAT(DISTINCT CustID) AS CustIDs
					,	ReasonID
					,	CreatedBy
					,	NOW() AS CreatedDate
					,	CURRENT_TIMESTAMP(3) AS CreatedTime
					,	IsParlay
					,	SportType
					,	IssueTypeID
				FROM CTECustInfo AS cte
				GROUP BY TVSRequestID, ReasonID, CreatedBy, IsParlay, SportType, IssueTypeID;

			END IF;
		
			INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, RoleID, SubscriberID, DWCategoryID, DWCategoryGroupID,  IsLicensee, IsLicenseeVIP, IsLicenseeBA, CreatedBy, IsMarkedDirectly
			, 	WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, SpecialCC, IsPAProbation
			, 	RelevantCategoryID, TVSRequestID, IsTVSParlay, SportType, TVSIssueTypeID, CategoryPriority, CustomerClassPriority
			, 	ParentID, IsReturnData, IsDataChanged, PerformanceTime)
			SELECT 	tmpJs.CustID
				,	cus.CTSCustID
				,	cus.RoleID
				, 	cus.SubscriberID
				,	cat.CategoryID
				,	cat.CategoryGroupID
				,	cus.IsLicensee
				,	cus.IsLicenseeVIP
				,	cus.IsLicenseeBA
				,	tmpJs.CreatedBy 
				,	tmpJs.IsMarkedDirectly
				, 	IFNULL(tmpJs.WinlossStatus,2) AS  WinlossStatus
				, 	tmpJs.TurnoverRM
				, 	tmpJs.WinlossRM 
				, 	tmpJs.BetCount 
				, 	tmpJs.ActiveDays
				,	tmpJs.IsFromTVS
				,	sp.CustomerClass AS SpecialCC
				,	(CASE WHEN tmpJs.WinlossStatus = 0 THEN 1 ELSE 0 END) AS IsPAProbation	/*1: PROBATION, 0: NOT PROBATION*/		
				,	cat.RelevantCategoryID
				,	CASE WHEN IFNULL(tmpJs.TVSRequestID,0) = 0 AND tmpJs.IsFromTVS = 0 THEN NULL
						 ELSE tmpJs.TVSRequestID END AS TVSRequestID
				,	tmpJs.IsTVSParlay
				,	tmpJs.SportType
				,	tmpJs.TVSIssueTypeID
				,	cat.CategoryPriority
				,	cat.CustomerClassPriority
				,	cat.ParentID
				,	1 AS IsReturnData
				,	0 AS IsDataChanged
				,	tmpJs.PerformanceTime
			FROM JSON_TABLE(ip_CustInfo,
							"$[*]" COLUMNS(
												CustID 						BIGINT UNSIGNED		PATH "$.CustID"
											,	TVSReasonID					INT 				PATH "$.ReasonID"
											, 	CreatedBy					INT UNSIGNED		PATH "$.CreatedBy"
											, 	IsMarkedDirectly			BIT(1)				PATH "$.IsDirectPA"
											,	WinlossStatus				SMALLINT 			PATH "$.WinlossStatus" 
											,	TurnoverRM					DECIMAL(20,4)		PATH "$.TurnoverRM"
											,	WinlossRM					DECIMAL(20,4) 		PATH "$.WinlossRM"
											, 	BetCount					BIGINT 				PATH "$.BetCount"
											, 	ActiveDays					INT 				PATH "$.ActiveDays"
											, 	IsFromTVS					BIT(1) 				PATH "$.IsFromTVS"
											, 	IsFromTW					BIT(1) 				PATH "$.IsFromTW"
											, 	IsFromCTS					BIT(1) 				PATH "$.IsFromCTS"
											, 	IsFromAI					BIT(1) 				PATH "$.IsFromAI"
											, 	TVSRequestID				BIGINT UNSIGNED		PATH "$.TVSRequestID"
											, 	Remark						VARCHAR(500) 		PATH "$.Remark"
											,	IsTVSParlay					BIT(1)	 			PATH "$.IsParlay"
											,	SportType					SMALLINT 			PATH "$.SportType"
											,	TVSIssueTypeID				TINYINT 			PATH "$.IssueTypeID"
											, 	PerformanceTime				DATETIME(3)			PATH "$.PerformanceTime"
										)) AS tmpJs
				LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID 
				LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.TVSReasonID = tmpJs.TVSReasonID
			ON DUPLICATE KEY UPDATE TurnoverRM = IFNULL(Temp_NewClassification.TurnoverRM, tmpJs.TurnoverRM)  
								,	WinlossRM = IFNULL(Temp_NewClassification.WinlossRM, tmpJs.WinlossRM)  
								,	BetCount = IFNULL(Temp_NewClassification.BetCount, tmpJs.BetCount)  
								,	ActiveDays = IFNULL(Temp_NewClassification.ActiveDays, tmpJs.ActiveDays)
								,	IsFromTW = CASE WHEN tmpJs.IsFromTW = 1 THEN 1 ELSE Temp_NewClassification.IsFromTW END
								,	IsFromCTS = CASE WHEN tmpJs.IsFromCTS = 1 THEN 1 ELSE Temp_NewClassification.IsFromCTS END
								,	IsFromAI = CASE WHEN tmpJs.IsFromAI = 1 THEN 1 ELSE Temp_NewClassification.IsFromAI END
								,	IsFromTVS = CASE WHEN tmpJs.IsFromTVS = 1 THEN 1 ELSE Temp_NewClassification.IsFromTVS END
								,	IsMarkedDirectly = CASE WHEN tmpJs.IsMarkedDirectly = 1 THEN 1 ELSE Temp_NewClassification.IsMarkedDirectly END
								,	IsTVSParlay = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.IsTVSParlay 
														ELSE Temp_NewClassification.IsTVSParlay END
								,	SportType = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.SportType 
														ELSE Temp_NewClassification.SportType END
								,	CreatedBy = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.CreatedBy 
														ELSE Temp_NewClassification.CreatedBy END
								,	TVSIssueTypeID = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.TVSIssueTypeID 
														ELSE Temp_NewClassification.TVSIssueTypeID END
								,	TVSRequestID = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.TVSRequestID 
														ELSE Temp_NewClassification.TVSRequestID END
								;
								
			/*INSERT INTO TABLE TVS_LOG*/
				
		ELSEIF ip_InputFlowID IN (6,16) THEN /*ip_InputType = PotentialPA*/
			INSERT IGNORE INTO Temp_NewClassification(
				CustID, CTSCustID, RoleID, SubscriberID, DWCategoryID, DWCategoryGroupID,IsLicensee, IsLicenseeVIP, IsLicenseeBA, CreatedBy, Remark, IsMarkedDirectly
			, 	WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTW, IsFromCTS, IsFromAI
			, 	SpecialCC, IsPAProbation, RelevantCategoryID, CategoryPriority, CustomerClassPriority
			, 	ParentID, IsReturnData, IsDataChanged, PerformanceTime, SportType, SourceCreatedDate, GBTicketCount)
			SELECT 	tmpJs.CustID
				,	tmpJs.CTSCustID
				,	tmpJs.RoleID
				, 	tmpJs.SubscriberID
				,	tmpJs.DWCategoryID
				,	cat.CategoryGroupID
				,	tmpJs.IsLicensee
				,	cus.IsLicenseeVIP
				,	cus.IsLicenseeBA
				,	tmpJs.CreatedBy 
				,	tmpJs.Remark
				,	tmpJs.IsMarkedDirectly
				, 	IFNULL(tmpJs.WinlossStatus,2) AS  WinlossStatus
				, 	tmpJs.TurnoverRM
				, 	tmpJs.WinlossRM 
				, 	tmpJs.BetCount 
				, 	tmpJs.ActiveDays
				,	tmpJs.IsFromTW
				,	tmpJs.IsFromCTS
				,	tmpJs.IsFromAI
				,	sp.CustomerClass AS SpecialCC
				,	(CASE WHEN tmpJs.WinlossStatus = 0 THEN 1 ELSE 0 END) AS IsPAProbation	/*1: PROBATION, 0: NOT PROBATION*/
				,	cat.RelevantCategoryID
				,	cat.CategoryPriority
				,	cat.CustomerClassPriority
				,	cat.ParentID
				,	1 AS IsReturnData
				,	0 AS IsDataChanged
				,	tmpJs.PerformanceTime
				,	tmpJs.SportType
				,	tmpJs.SourceCreatedDate
				,	tmpJs.GBTicketCount
			FROM JSON_TABLE(ip_CustInfo,
							"$[*]" COLUMNS(
												CustID 						BIGINT UNSIGNED		PATH "$.CustID"
											,	CTSCustID 					BIGINT UNSIGNED		PATH "$.CTSCustID"
											,	RoleID 						INT					PATH "$.RoleID" 
											,	SubscriberID 				INT UNSIGNED		PATH "$.SubscriberID"
											,	DWCategoryID				INT UNSIGNED		PATH "$.CategoryID"
											,	IsLicensee					BIT(1)				PATH "$.IsLicensee"
											, 	CreatedBy					INT UNSIGNED		PATH "$.CreatedBy"
											, 	Remark						VARCHAR(500)		PATH "$.Remark"
											, 	IsMarkedDirectly			BIT(1)				PATH "$.IsDirectPA"
											,	WinlossStatus				SMALLINT 			PATH "$.WinlossStatus" 
											,	TurnoverRM					DECIMAL(20,4)		PATH "$.TurnoverRM"
											,	WinlossRM					DECIMAL(20,4) 		PATH "$.WinlossRM"
											, 	BetCount					BIGINT 				PATH "$.BetCount"
											, 	ActiveDays					INT 				PATH "$.ActiveDays"
											, 	IsFromTW					BIT(1) 				PATH "$.IsFromTW"
											, 	IsFromCTS					BIT(1) 				PATH "$.IsFromCTS"
											, 	IsFromAI					BIT(1) 				PATH "$.IsFromAI"
											, 	PerformanceTime				DATETIME(3)			PATH "$.PerformanceTime"
											,	SportType					SMALLINT 			PATH "$.SportType"
											, 	SourceCreatedDate			DATETIME(3)			PATH "$.DetectionDate"
											, 	GBTicketCount				INT					PATH "$.GBTicketCount"
											)) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID
				LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = tmpJs.DWCategoryID
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID;
                
		ELSEIF ip_InputFlowID IN (7,17) THEN /*Robot*/
			INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, SubscriberID, RoleID, DWCategoryID, DWCategoryGroupID, IsLicensee, IsLicenseeVIP, IsLicenseeBA, CreatedBy, Remark, IsMarkedDirectly
			, 	WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI
			, 	SpecialCC, IsPAProbation, RelevantCategoryID, TVSRequestID, IsTVSParlay, SportType, TVSIssueTypeID, CategoryPriority
			, 	CustomerClassPriority, ParentID, TWRobotCounter, IsFromImperva, IsReturnData, IsDataChanged, PerformanceTime)
			SELECT 	tmpJs.CustID
				,	cus.CTSCustID
				, 	cus.SubscriberID
				, 	cus.RoleID
				,	tmpJs.DWCategoryID				
				,	cat.CategoryGroupID
				,	cus.IsLicensee
				,	cus.IsLicenseeVIP
				,	cus.IsLicenseeBA
				,	tmpJs.CreatedBy 
				,	tmpJs.Remark
				,	tmpJs.IsMarkedDirectly
				, 	IFNULL(tmpJs.WinlossStatus,2) AS  WinlossStatus
				, 	tmpJs.TurnoverRM
				, 	tmpJs.WinlossRM 
				, 	tmpJs.BetCount 
				, 	tmpJs.ActiveDays
				,	tmpJs.IsFromTVS
				,	tmpJs.IsFromTW
				,	tmpJs.IsFromCTS
				,	tmpJs.IsFromAI
				,	sp.CustomerClass AS SpecialCC
				,	(CASE WHEN tmpJs.WinlossStatus = 0 THEN 1 ELSE 0 END) AS IsPAProbation	/*1: PROBATION, 0: NOT PROBATION*/
				,	cat.RelevantCategoryID
				,	CASE WHEN IFNULL(tmpJs.TVSRequestID,0) = 0 AND tmpJs.IsFromTVS = 0 THEN NULL
						 ELSE tmpJs.TVSRequestID END AS TVSRequestID
				,	tmpJs.IsTVSParlay
				,	tmpJs.SportType
				,	tmpJs.TVSIssueTypeID
				,	cat.CategoryPriority
				,	cat.CustomerClassPriority
				,	cat.ParentID
				,	tmpJs.TWRobotCounter
				,	tmpJs.IsFromImperva
				,	1 AS IsReturnData
				,	0 AS IsDataChanged
				,	tmpJs.PerformanceTime
			FROM JSON_TABLE(ip_CustInfo,
							"$[*]" COLUMNS(
												CustID 					BIGINT UNSIGNED		PATH "$.CustID"                
											,	TWRobotCounter			INT 				PATH "$.RobotCounter"
											,	DWCategoryID    		INT UNSIGNED		PATH "$.CategoryID"
											
											,	WinlossStatus			SMALLINT 			PATH "$.WinlossStatus"	
											,	TurnoverRM				DECIMAL(20,4)		PATH "$.TurnoverRM"
											,	WinlossRM				DECIMAL(20,4) 		PATH "$.WinlossRM"
											, 	BetCount				BIGINT 				PATH "$.BetCount"
											, 	ActiveDays				INT 				PATH "$.ActiveDays"

											, 	IsFromTW				BIT(1)  			PATH "$.IsFromTW"
											, 	IsFromCTS				BIT(1)  			PATH "$.IsFromCTS"
											, 	IsFromAI				BIT(1)  			PATH "$.IsFromAI"
											, 	IsFromTVS				BIT(1)  			PATH "$.IsFromTVS"
											,	IsFromImperva			BIT(1) 				PATH "$.IsFromImperva"
											, 	TVSRequestID			BIGINT UNSIGNED 	PATH "$.TVSRequestID"
											, 	IsMarkedDirectly		BIT(1)  			PATH "$.IsDirect"

											, 	Remark					VARCHAR(500)		PATH "$.Remark"
											, 	CreatedBy				INT UNSIGNED		PATH "$.CreatedBy"
											,	IsTVSParlay				BIT(1) 				PATH "$.IsParlay"
											,	SportType				SMALLINT			PATH "$.SportType"
											,	TVSIssueTypeID			TINYINT				PATH "$.IssueTypeID"
											, 	PerformanceTime			DATETIME(3)			PATH "$.PerformanceTime"
										)) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID 
				LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = tmpJs.DWCategoryID
			ON DUPLICATE KEY UPDATE TWRobotCounter = IFNULL(Temp_NewClassification.TWRobotCounter, tmpJs.TWRobotCounter)
								,	TurnoverRM = IFNULL(Temp_NewClassification.TurnoverRM, tmpJs.TurnoverRM)  
								,	WinlossRM = IFNULL(Temp_NewClassification.WinlossRM, tmpJs.WinlossRM)  
								,	BetCount = IFNULL(Temp_NewClassification.BetCount, tmpJs.BetCount)  
								,	ActiveDays = IFNULL(Temp_NewClassification.ActiveDays, tmpJs.ActiveDays)
								,	IsFromTW = CASE WHEN tmpJs.IsFromTW = 1 THEN 1 ELSE Temp_NewClassification.IsFromTW END
								,	IsFromCTS = CASE WHEN tmpJs.IsFromCTS = 1 THEN 1 ELSE Temp_NewClassification.IsFromCTS END
								,	IsFromAI = CASE WHEN tmpJs.IsFromAI = 1 THEN 1 ELSE Temp_NewClassification.IsFromAI END
								,	IsFromTVS = CASE WHEN tmpJs.IsFromTVS = 1 THEN 1 ELSE Temp_NewClassification.IsFromTVS END
								,	IsFromImperva = CASE WHEN tmpJs.IsFromImperva = 1 THEN 1 ELSE Temp_NewClassification.IsFromImperva END
								,	IsMarkedDirectly = CASE WHEN tmpJs.IsMarkedDirectly = 1 THEN 1 ELSE Temp_NewClassification.IsMarkedDirectly END
								,	IsTVSParlay = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.IsTVSParlay 
														ELSE Temp_NewClassification.IsTVSParlay END
								,	SportType = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.SportType 
														ELSE Temp_NewClassification.SportType END
								,	CreatedBy = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.CreatedBy 
														ELSE Temp_NewClassification.CreatedBy END
								,	TVSIssueTypeID = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.TVSIssueTypeID 
														ELSE Temp_NewClassification.TVSIssueTypeID END
								,	TVSRequestID = CASE WHEN Temp_NewClassification.TVSRequestID IS NULL 
																AND (tmpJs.TVSRequestID > 0 OR (tmpJs.TVSRequestID IS NULL AND tmpJs.TVSIssueTypeID = 11))
															THEN tmpJs.TVSRequestID 
														ELSE Temp_NewClassification.TVSRequestID END
								;
			/*INSERT INTO TABLE TVS_LOG*/
		ELSEIF ip_InputFlowID = 8 THEN /*Normal*/
			INSERT INTO Temp_NewClassification(
				CustID,CTSCustID,DWCategoryID,DWCategoryGroupID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TWBetCount,TWGroupBettingRate
				,TWTicketRejectRate,TWDesktopUsageRate,TaggingID,TaggingType,PerformanceTime,ScanTaggingType
				,SubscriberID,RoleID,IsLicensee,IsLicenseeVIP,IsLicenseeBA,SpecialCC,IsReturnData,IsDataChanged)
			SELECT DISTINCT
					tmpJs.CustID
				,	cus.CTSCustID
				, 	tmpJs.DWCategoryID
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
				,	cus.SubscriberID
				,	cus.RoleID
				,	cus.IsLicensee
				,	cus.IsLicenseeVIP
				,	cus.IsLicenseeBA
				,	sp.CustomerClass AS SpecialCC
				,	1 AS IsReturnData
				,	1 AS IsDataChanged
			FROM JSON_TABLE(ip_CustInfo,
							"$[*]" COLUMNS(
												CustID 					BIGINT UNSIGNED		PATH "$.CustID"
											, 	DWCategoryID			INT UNSIGNED		PATH "$.CategoryID"
											, 	DWCategoryGroupID		INT UNSIGNED		PATH "$.CategoryGroupID"
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
											, 	PerformanceTime			DATETIME(3)			PATH "$.PerformanceTime"
											, 	ScanTaggingType			BIT(1)				PATH "$.ScanTaggingType"
										)) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpJs.CustID = cus.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID;
			-- WHERE tmpJs.DWCategoryGroupID <> 0;
		END IF;
		
		UPDATE Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = temp.DWCategoryID
		SET temp.DWCategoryGroupID = cat.CategoryGroupID
		WHERE temp.DWCategoryID IS NOT NULL
			AND temp.DWCategoryGroupID IS NULL;
		
		UPDATE Temp_NewClassification AS temp
		SET 	temp.IsExistVVIP = 1
			,	IsFromOldPA = 1
			,	IsDataChanged = 1
		WHERE EXISTS (	SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
						WHERE temp.CustID = cls.CustID
							AND cls.ParentID = CONST_PARENTID_VVIP
					 );
		
		
		UPDATE Temp_NewClassification AS temp
		SET 	temp.IsExistWrapper = 1
			,	IsFromOldPA = 1
			,	IsDataChanged = 1
		WHERE EXISTS (	SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
						WHERE temp.CustID = cls.CustID
							AND cls.ParentID = CONST_PARENTID_WRAPPER
					 );
					 
					 
		UPDATE Temp_NewClassification AS temp
		SET temp.IsExistPA = 1
		WHERE EXISTS (	SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
						WHERE temp.CustID = cls.CustID
							AND cls.ParentID = CONST_PARENTID_PA
					 );
					 
		UPDATE Temp_NewClassification AS temp
		SET temp.IsExistPotentialPA = 1
		WHERE EXISTS (	SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
						WHERE temp.CustID = cls.CustID
							AND cls.ParentID = CONST_PARENTID_POTENTIALPA
					 );
	
		/*UPDATE Temp_NewClassification AS temp
		SET temp.IsExistRobot = 1
		WHERE EXISTS (	SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
							INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = cls.CategoryID 
						WHERE temp.CustID = cls.CustID
							AND cat.IsActive = 1 AND cat.CustomerClassName = 'Robot'
					 );
					 
		UPDATE Temp_NewClassification AS temp
		SET temp.IsExistKeepOldCateID = 1
		WHERE (temp.IsExistVVIP = 1 OR temp.IsExistWrapper = 1 OR temp.IsExistPA = 1)
			AND EXISTS (SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
							INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = cls.CategoryID
						WHERE temp.CustID = cls.CustID
							AND cs.IsKeepOldCateID = 1
						);*/
    
    END IF;
    
END$$
DELIMITER ;