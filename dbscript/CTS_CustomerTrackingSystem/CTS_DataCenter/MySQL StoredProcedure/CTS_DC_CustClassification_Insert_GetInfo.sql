/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert_GetInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert_GetInfo`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_FromAction			TINYINT
    ,	IN	ip_UplineRoleID			INT
	,	IN	ip_CustInfo				JSON
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		
		Param's Expanation:
			- ip_InputFlowID
            - ip_FromAction
            - ip_UplineRoleID
			- ip_CustInfo
			
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_GetInfo (9,3,'[{"CustID":1275,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":1280,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5002646,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5022391,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0}]');
			
		Revisions: 
			- 20240618@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/

	DECLARE CONST_CATEID_VVIP 								INT;
	DECLARE CONST_CATEID_SPECIALCC 							INT;
	DECLARE CONST_CATEID_LICVIPSUSPICIOUS 					INT;
	DECLARE CONST_PARENTID_VVIP 							INT;
	DECLARE CONST_PARENTID_WRAPPER 							INT;
	DECLARE CONST_PARENTID_PA 								INT;
	DECLARE CONST_PARENTID_POTENTIALPA						INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_INSERT_VVIP			INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_INSERT_SPECIALCC		INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_INSERT_LICVIP			INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_INSERT_LICBA			INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_INSERT_PACATEGORY		INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_INSERT_PAREASON		INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_INSERT_PAROBOT		INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_INSERT_POTENTIAL		INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_INSERT_NORMAL			INT;
	
	DECLARE CONST_INPUTFLOWID_GENERAL_RESCAN_PACATEGORY		INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_RESCAN_PAREASON		INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_RESCAN_PAROBOT		INT;
	DECLARE CONST_INPUTFLOWID_GENERAL_RESCAN_POTENTIAL		INT;
	
	DECLARE CONST_SOURCETYPE_VVIP_MANUAL 					INT DEFAULT 13;
	DECLARE CONST_SOURCETYPE_VVIP_AFFECTED_SUPER			INT DEFAULT 24;
	DECLARE CONST_SOURCETYPE_VVIP_AFFECTED_MASTER			INT DEFAULT 25;
	DECLARE CONST_SOURCETYPE_VVIP_AFFECTED_AGENT			INT DEFAULT 26;
	DECLARE CONST_SOURCETYPE_VVIP_AFFECTED_DIRECTUPLINE		INT DEFAULT 30;
	
	DECLARE lv_SourceTypeID									INT; 
	DECLARE lv_IsMarkedDirectly								TINYINT(1);   
	
	SET CONST_CATEID_VVIP 									= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	SET CONST_CATEID_SPECIALCC								= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SPECIALCC');
	SET CONST_CATEID_LICVIPSUSPICIOUS 						= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_PARENTID_VVIP 								= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_VVIP');
	SET CONST_PARENTID_WRAPPER 								= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_PARENTID_PA 									= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
	SET CONST_PARENTID_POTENTIALPA							= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_POTENTIALPA');
	SET CONST_INPUTFLOWID_GENERAL_INSERT_VVIP				= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_INSERT_VVIP');
	SET CONST_INPUTFLOWID_GENERAL_INSERT_SPECIALCC			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_INSERT_SPECIALCC');
	SET CONST_INPUTFLOWID_GENERAL_INSERT_LICVIP				= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_INSERT_LICVIP');
	SET CONST_INPUTFLOWID_GENERAL_INSERT_LICBA				= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_INSERT_LICBA');
	SET CONST_INPUTFLOWID_GENERAL_INSERT_PACATEGORY			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_INSERT_PACATEGORY');
	SET CONST_INPUTFLOWID_GENERAL_INSERT_PAREASON			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_INSERT_PAREASON');
	SET CONST_INPUTFLOWID_GENERAL_INSERT_PAROBOT			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_INSERT_PAROBOT');
	SET CONST_INPUTFLOWID_GENERAL_INSERT_POTENTIAL			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_INSERT_POTENTIAL');
	SET CONST_INPUTFLOWID_GENERAL_INSERT_NORMAL				= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_INSERT_NORMAL');
	
	SET CONST_INPUTFLOWID_GENERAL_RESCAN_PACATEGORY			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_RESCAN_PACATEGORY');
	SET CONST_INPUTFLOWID_GENERAL_RESCAN_PAREASON			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_RESCAN_PAREASON');
	SET CONST_INPUTFLOWID_GENERAL_RESCAN_PAROBOT			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_RESCAN_PAROBOT');
	SET CONST_INPUTFLOWID_GENERAL_RESCAN_POTENTIAL			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_GENERAL_RESCAN_POTENTIAL');
	
	DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification(	  	
			CustID						BIGINT UNSIGNED
		, 	CTSCustID					BIGINT UNSIGNED
		,	SubscriberID 				INT UNSIGNED
		,	RoleID						INT		
		,	IsLicensee					TINYINT(1) DEFAULT 0
		,	IsLicenseeVIP				TINYINT(1) DEFAULT 0
		,	IsLicenseeBA				TINYINT(1) DEFAULT 0
		,	IsExistVVIP					TINYINT(1) DEFAULT 0
		,	IsExistWrapper				TINYINT(1) DEFAULT 0
		,	IsExistPA					TINYINT(1) DEFAULT 0
		,	IsExistPotentialPA			TINYINT(1) DEFAULT 0
		,	IsFromOldPA					TINYINT(1) DEFAULT 0
		
		, 	TurnoverRM					DECIMAL(20,4)
		, 	WinlossRM					DECIMAL(20,4)
		, 	BetCount					BIGINT
		, 	ActiveDays					INT	
		,	PerformanceTime				DATETIME(3)

		, 	DWCategoryID		    	INT UNSIGNED
		,	DWCategoryGroupID   		INT UNSIGNED
		
		, 	NewCategoryID		   		INT UNSIGNED
		,	NewCategoryGroupID     		INT UNSIGNED
		,	NewIsDangerProbation		TINYINT(1) DEFAULT 0
		,	IsPAProbation	     		TINYINT(1) DEFAULT 0
		
		,	OldCategoryID		    	INT UNSIGNED
		,	OldCategoryGroupID	    	INT UNSIGNED

		,	ParentID					INT UNSIGNED
		,	OldTargetCC					INT 
		,	TargetCC					INT 
		,	TargetDangerLevel			SMALLINT UNSIGNED
		,	CategoryPriority			SMALLINT UNSIGNED 
		,	CustomerClassPriority		SMALLINT UNSIGNED 
		,	MatchID						INT
		
		, 	ToEvidenceID				SMALLINT
		
		, 	RelevantCategoryID			INT UNSIGNED
		,	RelevantCategoryGroupID   	INT UNSIGNED
		,	RelevantIsPAProbation	   	TINYINT(1)
		
		,	IsDataChanged				TINYINT(1) 	/* 0: Not Change, 1: Changed (IF call from SpecialCC function THEN 1 ELSE 0) */
		,	DataChangeType				TINYINT DEFAULT 0	/* 0: New OR Change Category, 1: Change Probation Status, 2: NOT CHANGE */
		,	SourceTypeID      			SMALLINT

		, 	WinlossStatus				SMALLINT /*LOSING  = 0 (PROBATION), KEEPSTATE = 1 (NOT CHANGE), WINNING = 2 (NOT PROBATION);*/
		
		,	IsFromTVS					TINYINT(1)  DEFAULT 0
		,	TVSRequestID				BIGINT UNSIGNED
		, 	TVSReasonID		   			INT
		,	TVSIssueTypeID 				TINYINT DEFAULT NULL 
		,	IsTVSParlay					TINYINT(1) DEFAULT NULL
		,	SportType					SMALLINT DEFAULT NULL 
		
		,	SourceCreatedDate			DATETIME(3)
		,	GBTicketCount				INT

		,	IsFromTW					TINYINT(1)  DEFAULT 0
		,	TWRobotCounter				INT 
		
		,	TWBetCount					BIGINT
		,	TWGroupBettingRate			DECIMAL(10,4)
		,	TWTicketRejectRate			DECIMAL(10,4)
		,	TWDesktopUsageRate			DECIMAL(10,4)
		
		,	IsFromCTS					TINYINT(1)  DEFAULT 0
		,	IsFromAI					TINYINT(1)  DEFAULT 0
		,	IsFromImperva				TINYINT(1) 	DEFAULT 0
		
		,	TaggingID					SMALLINT
		,	TaggingType					SMALLINT	
		,	ScanTaggingType				TINYINT DEFAULT 0

		,   SpecialCC	       			SMALLINT  
		,	SpecialCCName				VARCHAR(50)
		,   SpecialCCCatePriority  		SMALLINT DEFAULT -1
		,   SpecialCCDangerProbation   	TINYINT(1) DEFAULT NULL
		
		,	LastModifiedDate			DATETIME(3)
		, 	ActionType					SMALLINT DEFAULT 0 
		,	CreatedBy					INT UNSIGNED
		,	IsMarkedDirectly			TINYINT(1) DEFAULT 0
		,	IsReturnData				TINYINT(1) DEFAULT 1
		,	Remark						VARCHAR(500)
		,	GroupName					VARCHAR(100)
		, 	PRIMARY KEY (CustID, DWCategoryID)
	); 
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE Temp_Customer (
			CustID						BIGINT UNSIGNED PRIMARY KEY
		, 	CTSCustID					BIGINT UNSIGNED
		, 	SubscriberID				INT UNSIGNED
		,	RoleID						INT	
		,	CreatedBy 					INT UNSIGNED
		,	IsLicenseeVIP				TINYINT(1) DEFAULT 0
		, 	IsLicenseeBA				TINYINT(1) DEFAULT 0
	);
	
	/*VVIP/SpecialCC/LicVIP/LicBA*/
	IF ip_InputFlowID IN (CONST_INPUTFLOWID_GENERAL_INSERT_VVIP,CONST_INPUTFLOWID_GENERAL_INSERT_SPECIALCC,
							CONST_INPUTFLOWID_GENERAL_INSERT_LICVIP,CONST_INPUTFLOWID_GENERAL_INSERT_LICBA) THEN 
		/*1 - VVIP*/
		IF ip_InputFlowID = CONST_INPUTFLOWID_GENERAL_INSERT_VVIP THEN 
			SET lv_SourceTypeID = CASE 	WHEN ip_FromAction = 1 THEN CONST_SOURCETYPE_VVIP_MANUAL
										WHEN ip_FromAction = 3 AND ip_UplineRoleID = 4 THEN CONST_SOURCETYPE_VVIP_AFFECTED_SUPER
										WHEN ip_FromAction = 3 AND ip_UplineRoleID = 3 THEN CONST_SOURCETYPE_VVIP_AFFECTED_MASTER
										WHEN ip_FromAction = 3 AND ip_UplineRoleID = 2 THEN CONST_SOURCETYPE_VVIP_AFFECTED_AGENT
										WHEN ip_FromAction = 3 AND ip_UplineRoleID IS NULL THEN CONST_SOURCETYPE_VVIP_AFFECTED_DIRECTUPLINE
								  END;
								  
			IF ip_FromAction = 1 THEN
				SET lv_IsMarkedDirectly = 1;
			ELSE
				SET lv_IsMarkedDirectly = 0;
			END IF;
		
			INSERT INTO Temp_NewClassification (
					CustID, CTSCustID, SubscriberID, RoleID, Remark, CreatedBy, IsExistVVIP, ParentID
				, 	DWCategoryID, NewCategoryID, IsMarkedDirectly, SourceTypeID, IsDataChanged, IsReturnData)
			SELECT DISTINCT 
					tmpJs.CustID, tmpJs.CTSCustID, tmpJs.SubscriberID, tmpJs.RoleID, tmpJs.Remark, tmpJs.CreatedBy
				,	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsExistVVIP
				,	CONST_PARENTID_VVIP
				,	CONST_CATEID_VVIP
				,	CONST_CATEID_VVIP
				,	(CASE WHEN cls.CustID IS NULL THEN lv_IsMarkedDirectly END) AS IsMarkedDirectly
				,	(CASE WHEN cls.CustID IS NULL THEN lv_SourceTypeID END) AS SourceTypeID
				,	(CASE WHEN cls.CustID IS NULL THEN 1 ELSE 0 END) AS IsDataChanged
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
																				AND cls.CategoryID = CONST_CATEID_VVIP;
																				
		/*2 - SpecialCC*/
		ELSEIF ip_InputFlowID = CONST_INPUTFLOWID_GENERAL_INSERT_SPECIALCC THEN 
			INSERT INTO Temp_NewClassification (
				CustID, CTSCustID, SubscriberID, RoleID, ParentID, DWCategoryID, NewCategoryID, Remark, CreatedBy, IsLicenseeVIP, TargetCC, IsDataChanged, IsReturnData)
			SELECT 	tmpJs.CustID, tmpJs.CTSCustID, tmpJs.SubscriberID, cus.RoleID
				,	CONST_PARENTID_WRAPPER
				,	CONST_CATEID_SPECIALCC
				,	CONST_CATEID_SPECIALCC
				, 	tmpJs.Remark, tmpJs.CreatedBy, tmpJs.IsLicenseeVIP, tmpJs.TargetCC
				, 	CASE WHEN tmpJs.IsLicenseeVIP = 1 AND cls.CustID IS NOT NULL THEN 1 ELSE 0  END AS IsDataChanged
				, 	1 AS IsReturnData
			FROM JSON_TABLE(ip_CustInfo,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED		PATH "$.CustID"
												,	CTSCustID 		BIGINT UNSIGNED		PATH "$.CTSCustID"
												,	SubscriberID 	INT UNSIGNED		PATH "$.SubscriberID"
												,	IsLicenseeVIP	TINYINT(1)			PATH "$.IsLicenseeVIP"            
												,	TargetCC		INT 				PATH "$.CustomerClass"            
												,	CreatedBy 		INT UNSIGNED		PATH "$.CreatedBy"          
												,	Remark			VARCHAR(500)		PATH "$.Remark"
											 )) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON cls.CustID = tmpJs.CustID
																				AND cls.CategoryID = CONST_CATEID_LICVIPSUSPICIOUS;
			
		/*3 - LicVIP*/
		ELSEIF ip_InputFlowID = CONST_INPUTFLOWID_GENERAL_INSERT_LICVIP THEN	
			INSERT INTO Temp_Customer (CustID, CTSCustID, SubscriberID, RoleID, CreatedBy, IsLicenseeVIP)
			SELECT tmpJs.CustID, cus.CTSCustID, cus.SubscriberID, cus.RoleID, tmpJs.CreatedBy, cus.IsLicenseeVIP
			FROM JSON_TABLE(ip_CustInfo,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED	PATH "$.CustID"
												,	CreatedBy 		INT UNSIGNED	PATH "$.CreatedBy"
											 )) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0;
			
		/*4 - LicBA*/
		ELSEIF ip_InputFlowID = CONST_INPUTFLOWID_GENERAL_INSERT_LICBA THEN 
			INSERT INTO Temp_Customer (CustID, CTSCustID, SubscriberID, RoleID, CreatedBy, IsLicenseeBA)
			SELECT tmpJs.CustID, cus.CTSCustID, cus.SubscriberID, cus.RoleID, tmpJs.CreatedBy, cus.IsLicenseeBA
			FROM JSON_TABLE(ip_CustInfo,
							 "$[*]" COLUMNS(
													CustID 			BIGINT UNSIGNED	PATH "$.CustID"
												,	CreatedBy 		INT UNSIGNED	PATH "$.CreatedBy"
											 )) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON  tmpJs.CustID = cus.CustID AND cus.CustSubID = 0;
		
		END IF;

	ELSE
		
		/*5 - PA-Category*/
		IF ip_InputFlowID IN (CONST_INPUTFLOWID_GENERAL_INSERT_PACATEGORY,CONST_INPUTFLOWID_GENERAL_RESCAN_PACATEGORY) THEN 
			
			INSERT INTO Temp_NewClassification(
					CustID, CTSCustID, RoleID, SubscriberID, DWCategoryID, DWCategoryGroupID,IsLicensee, IsLicenseeVIP, IsLicenseeBA, CreatedBy, Remark, IsMarkedDirectly
				, 	WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI
				, 	SpecialCC, IsPAProbation, RelevantCategoryID, LastModifiedDate, MatchID, TVSRequestID, IsTVSParlay, SportType
				, 	TVSIssueTypeID, CategoryPriority, CustomerClassPriority, ParentID, IsReturnData, IsDataChanged, PerformanceTime, GroupName)
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
											,	IsLicensee					TINYINT(1)			PATH "$.IsLicensee"
											, 	CreatedBy					INT UNSIGNED		PATH "$.CreatedBy"
											, 	Remark						VARCHAR(500)		PATH "$.Remark"
											, 	IsMarkedDirectly			TINYINT(1)			PATH "$.IsMarkedDirectly"
											,	WinlossStatus				SMALLINT 			PATH "$.WinlossStatus" 
											,	TurnoverRM					DECIMAL(20,4)		PATH "$.TurnoverRM"
											,	WinlossRM					DECIMAL(20,4) 		PATH "$.WinlossRM"
											, 	BetCount					BIGINT 				PATH "$.BetCount"
											, 	ActiveDays					INT 				PATH "$.ActiveDays"
											, 	IsFromTVS					TINYINT(1) 			PATH "$.IsFromTVS"
											, 	IsFromTW					TINYINT(1)			PATH "$.IsFromTW"
											, 	IsFromCTS					TINYINT(1) 			PATH "$.IsFromCTS"
											, 	IsFromAI					TINYINT(1) 			PATH "$.IsFromAI"
											, 	LastModifiedDate			DATETIME(3)			PATH "$.LastModifiedDate"
											, 	MatchID						INT 				PATH "$.MatchID"	
											, 	TVSRequestID				BIGINT UNSIGNED		PATH "$.TVSRequestID"
											,	IsTVSParlay					TINYINT(1)  		PATH "$.IsParlay"
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
			
		/*6 - PA-Reason*/
		ELSEIF ip_InputFlowID IN (CONST_INPUTFLOWID_GENERAL_INSERT_PAREASON,CONST_INPUTFLOWID_GENERAL_RESCAN_PAREASON) THEN 
			
			IF ip_InputFlowID = CONST_INPUTFLOWID_GENERAL_INSERT_PAREASON THEN
				INSERT INTO CTS_DataCenter.TVSVoidRequest_Log(TVSRequestID,CustIDs,ReasonID,CreatedBy,CreatedDate,CreatedTime,IsParlay,SportType,IssueTypeID)
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
							,	TVSReasonID		INT 				PATH "$.TVSReasonID"
							, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
							, 	IsFromTVS		TINYINT(1) 			PATH "$.IsFromTVS"
							, 	TVSRequestID	BIGINT UNSIGNED		PATH "$.TVSRequestID"
							,	IsTVSParlay		TINYINT(1) 			PATH "$.IsParlay"
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
				,	cat.CategoryGroupID
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
											,	TVSReasonID					INT 				PATH "$.TVSReasonID"
											, 	CreatedBy					INT UNSIGNED		PATH "$.CreatedBy"
											, 	IsMarkedDirectly			TINYINT(1)			PATH "$.IsMarkedDirectly"
											,	WinlossStatus				SMALLINT 			PATH "$.WinlossStatus" 
											,	TurnoverRM					DECIMAL(20,4)		PATH "$.TurnoverRM"
											,	WinlossRM					DECIMAL(20,4) 		PATH "$.WinlossRM"
											, 	BetCount					BIGINT 				PATH "$.BetCount"
											, 	ActiveDays					INT 				PATH "$.ActiveDays"
											, 	IsFromTVS					TINYINT(1) 			PATH "$.IsFromTVS"
											, 	IsFromTW					TINYINT(1) 			PATH "$.IsFromTW"
											, 	IsFromCTS					TINYINT(1) 			PATH "$.IsFromCTS"
											, 	IsFromAI					TINYINT(1) 			PATH "$.IsFromAI"
											, 	TVSRequestID				BIGINT UNSIGNED		PATH "$.TVSRequestID"
											, 	Remark						VARCHAR(500) 		PATH "$.Remark"
											,	IsTVSParlay					TINYINT(1) 			PATH "$.IsParlay"
											,	SportType					SMALLINT 			PATH "$.SportType"
											,	TVSIssueTypeID				TINYINT 			PATH "$.IssueTypeID"
											, 	PerformanceTime				DATETIME(3)			PATH "$.PerformanceTime"
										)) AS tmpJs
				LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID 
				,	LATERAL (
						SELECT cate.CategoryGroupID, cate.RelevantCategoryID, cate.CategoryPriority, cate.CustomerClassPriority,cate.ParentID
						FROM CTS_DataCenter.CustomerCategory AS cate 
						WHERE cate.TVSReasonID = tmpJs.TVSReasonID
						LIMIT 1
				) AS cat
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
			
			UPDATE Temp_NewClassification AS temp
			SET 	temp.IsExistWrapper = 1
				,	IsDataChanged = 1
			WHERE EXISTS (	SELECT 1
							FROM CTS_DataCenter.CTSCustomerClassification AS cls
							WHERE temp.CustID = cls.CustID
								AND cls.ParentID = CONST_PARENTID_WRAPPER
						 );
		/*7 - Robot*/
		ELSEIF ip_InputFlowID IN (CONST_INPUTFLOWID_GENERAL_INSERT_PAROBOT,CONST_INPUTFLOWID_GENERAL_RESCAN_PAROBOT) THEN 
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

											, 	IsFromTW				TINYINT(1) 			PATH "$.IsFromTW"
											, 	IsFromCTS				TINYINT(1) 			PATH "$.IsFromCTS"
											, 	IsFromAI				TINYINT(1) 			PATH "$.IsFromAI"
											, 	IsFromTVS				TINYINT(1)  		PATH "$.IsFromTVS"
											,	IsFromImperva			TINYINT(1) 			PATH "$.IsFromImperva"
											, 	TVSRequestID			BIGINT UNSIGNED 	PATH "$.TVSRequestID"
											, 	IsMarkedDirectly		TINYINT(1) 			PATH "$.IsMarkedDirectly"

											, 	Remark					VARCHAR(500)		PATH "$.Remark"
											, 	CreatedBy				INT UNSIGNED		PATH "$.CreatedBy"
											,	IsTVSParlay				TINYINT(1) 			PATH "$.IsParlay"
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
			
			UPDATE Temp_NewClassification AS temp
			SET 	temp.IsExistWrapper = 1
				,	IsDataChanged = 1
			WHERE EXISTS (	SELECT 1
							FROM CTS_DataCenter.CTSCustomerClassification AS cls
							WHERE temp.CustID = cls.CustID
								AND cls.ParentID = CONST_PARENTID_WRAPPER
						 );
		/*8 - PotentialPA*/
		ELSEIF ip_InputFlowID IN (CONST_INPUTFLOWID_GENERAL_INSERT_POTENTIAL,CONST_INPUTFLOWID_GENERAL_RESCAN_POTENTIAL) THEN 
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
											,	IsLicensee					TINYINT(1)			PATH "$.IsLicensee"
											, 	CreatedBy					INT UNSIGNED		PATH "$.CreatedBy"
											, 	Remark						VARCHAR(500)		PATH "$.Remark"
											, 	IsMarkedDirectly			TINYINT(1)			PATH "$.IsMarkedDirectly"
											,	WinlossStatus				SMALLINT 			PATH "$.WinlossStatus" 
											,	TurnoverRM					DECIMAL(20,4)		PATH "$.TurnoverRM"
											,	WinlossRM					DECIMAL(20,4) 		PATH "$.WinlossRM"
											, 	BetCount					BIGINT 				PATH "$.BetCount"
											, 	ActiveDays					INT 				PATH "$.ActiveDays"
											, 	IsFromTW					TINYINT(1)			PATH "$.IsFromTW"
											, 	IsFromCTS					TINYINT(1) 			PATH "$.IsFromCTS"
											, 	IsFromAI					TINYINT(1) 			PATH "$.IsFromAI"
											, 	PerformanceTime				DATETIME(3)			PATH "$.PerformanceTime"
											,	SportType					SMALLINT 			PATH "$.SportType"
											, 	SourceCreatedDate			DATETIME(3)			PATH "$.DetectedDate"
											, 	GBTicketCount				INT					PATH "$.GBTicketCount"
											)) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID
				LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = tmpJs.DWCategoryID
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID;
                
		/*9 - Normal*/
		ELSEIF ip_InputFlowID = CONST_INPUTFLOWID_GENERAL_INSERT_NORMAL THEN 
			INSERT INTO Temp_NewClassification(
					CustID,CTSCustID,DWCategoryID,DWCategoryGroupID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TWBetCount,TWGroupBettingRate
				,	TWTicketRejectRate,TWDesktopUsageRate,TaggingID,TaggingType,PerformanceTime,ScanTaggingType
				,	SubscriberID,RoleID,IsLicensee,IsLicenseeVIP,IsLicenseeBA,SpecialCC,IsReturnData,IsDataChanged)
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
											, 	ScanTaggingType			TINYINT				PATH "$.ScanTaggingType"
										)) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpJs.CustID = cus.CustID AND cus.CustSubID = 0
				LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON tmpJs.CustID = sp.CustID;
				
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
		END IF;
		
		UPDATE Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = temp.DWCategoryID
		SET temp.DWCategoryGroupID = cat.CategoryGroupID
		WHERE temp.DWCategoryID IS NOT NULL
			AND temp.DWCategoryGroupID IS NULL;
		
		UPDATE Temp_NewClassification AS temp
		SET 	temp.IsExistVVIP = 1
			,	IsDataChanged = 1
		WHERE EXISTS (	SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
						WHERE temp.CustID = cls.CustID
							AND cls.CategoryID = CONST_CATEID_VVIP
					 );

    END IF;
    
END$$
DELIMITER ;