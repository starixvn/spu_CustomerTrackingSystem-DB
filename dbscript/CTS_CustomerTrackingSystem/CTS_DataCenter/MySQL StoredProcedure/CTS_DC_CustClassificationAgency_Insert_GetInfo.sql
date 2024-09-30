/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassificationAgency_Insert_GetInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassificationAgency_Insert_GetInfo`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_FromAction			TINYINT
    ,	IN	ip_UplineRoleID			INT
	,	IN	ip_CustInfo				JSON
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240927@Thomas.Nguyen
		Task:		Insert main Agency categories for Agency Classification
		DB:			CTS_DataCenter
		
		Param's Expanation:
			- ip_InputFlowID
            - ip_FromAction
            - ip_UplineRoleID
			- ip_CustInfo
			
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassificationAgency_Insert_GetInfo (9,3,'[{"CustID":1275,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":1280,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5002646,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5022391,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0}]');
			
		Revisions: 
			- 20240927@Thomas.Nguyen:			Created [Redmine ID: #185799]
*/

	DECLARE CONST_AGENCY_CATEID_VVIP 								INT;
	DECLARE CONST_AGENCY_PARENTID_VVIP 								INT;
	DECLARE CONST_AGENCY_PARENTID_PA 								INT;
	DECLARE CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_VVIP			INT;
	DECLARE CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_PACATEGORY		INT;
	DECLARE CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_NORMAL			INT;
	
	DECLARE CONST_AGENCY_INPUTFLOWID_GENERAL_RESCAN_PACATEGORY		INT;
	DECLARE CONST_AGENCY_INPUTFLOWID_GENERAL_RESCAN_POTENTIAL		INT;
	
	DECLARE CONST_SOURCETYPE_VVIP_MANUAL 					INT DEFAULT 13;
	DECLARE CONST_SOURCETYPE_VVIP_AFFECTED_SUPER			INT DEFAULT 24;
	DECLARE CONST_SOURCETYPE_VVIP_AFFECTED_MASTER			INT DEFAULT 25;
	DECLARE CONST_SOURCETYPE_VVIP_AFFECTED_AGENT			INT DEFAULT 26;
	DECLARE CONST_SOURCETYPE_VVIP_AFFECTED_DIRECTUPLINE		INT DEFAULT 30;
	
	DECLARE lv_SourceTypeID									INT; 
	DECLARE lv_IsMarkedDirectly								TINYINT(1);
	DECLARE	lv_CurrentDateTime								DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3); 
	
	SET CONST_AGENCY_CATEID_VVIP 									= CTS_DC_CategoryTypeParent_Get ('CONST_AGENCY_CATEID_VVIP');
	SET CONST_AGENCY_PARENTID_VVIP 									= CTS_DC_CategoryTypeParent_Get ('CONST_AGENCY_PARENTID_VVIP');
	SET CONST_AGENCY_PARENTID_PA 									= CTS_DC_CategoryTypeParent_Get ('CONST_AGENCY_PARENTID_PA');
	SET CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_VVIP				= CTS_DC_CategoryTypeParent_Get ('CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_VVIP');
	SET CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_PACATEGORY			= CTS_DC_CategoryTypeParent_Get ('CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_PACATEGORY');
	SET CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_NORMAL				= CTS_DC_CategoryTypeParent_Get ('CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_NORMAL');
	SET CONST_AGENCY_INPUTFLOWID_GENERAL_RESCAN_PACATEGORY			= CTS_DC_CategoryTypeParent_Get ('CONST_AGENCY_INPUTFLOWID_GENERAL_RESCAN_PACATEGORY');
	
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
		,	IsExistPA					TINYINT(1) DEFAULT 0
		,	IsFromOld					TINYINT(1) DEFAULT 0
		
		, 	TurnoverRM					DECIMAL(20,4)
		, 	WinlossRM					DECIMAL(20,4)
		, 	BetCount					BIGINT
		, 	ActiveDays					INT	
		,	PerformanceTime				DATETIME

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
		,	CategoryPriority			SMALLINT  
		,	CustomerClassPriority		SMALLINT  

		, 	ToEvidenceID				SMALLINT
		
		, 	RelevantCategoryID			INT UNSIGNED
		,	RelevantCategoryGroupID   	INT UNSIGNED
		,	RelevantIsPAProbation	   	TINYINT(1)
		
		,	IsDataChanged				TINYINT(1) 	/* 0: Not Change, 1: Changed (IF call from SpecialCC function THEN 1 ELSE 0) */
		,	DataChangeType				TINYINT DEFAULT 0	/* 0: New OR Change Category, 1: Change Probation Status, 2: NOT CHANGE */
		, 	ActionType					SMALLINT DEFAULT 0 
		, 	WinlossStatus				SMALLINT /*LOSING  = 0 (PROBATION), KEEPSTATE = 1 (NOT CHANGE), WINNING = 2 (NOT PROBATION);*/
		,	SourceTypeID      			SMALLINT

		,	IsFromTW					TINYINT(1)  DEFAULT 0
		
		,	IsFromCTS					TINYINT(1)  DEFAULT 0
		,	IsFromAI					TINYINT(1)  DEFAULT 0
		,	IsFromImperva				TINYINT(1) 	DEFAULT 0
			
		,	CreatedDate					DATETIME
		,	LastModifiedDate			DATETIME
		,	CreatedBy					INT UNSIGNED
		,	IsMarkedDirectly			TINYINT(1) DEFAULT 0
		,	IsReturnData				TINYINT(1) DEFAULT 1
		,	Remark						VARCHAR(500)
		,	IsRobot						TINYINT(1) DEFAULT 0
		, 	PRIMARY KEY (CustID, DWCategoryID)
		,	KEY IX_Temp_NewCC_CustID_NewCateID (CustID, NewCategoryGroupID)
		,	KEY IX_Temp_NewCC_CustID_Priority (CustID,CustomerClassPriority)
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
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassification_Old;
	CREATE TEMPORARY TABLE Temp_CTSCustomerClassification_Old (
			CustID						BIGINT UNSIGNED
		,	CTSCustID					BIGINT UNSIGNED
		,	SubscriberID				INT UNSIGNED
		,	RoleID						INT
		,	ParentID					INT UNSIGNED
		,	CategoryID					INT UNSIGNED
		,	CategoryGroupID				INT UNSIGNED
		,	ExistCategoryID				INT UNSIGNED
		,	RelevantCategoryID			INT UNSIGNED
		,	Remark						VARCHAR(500)
		,	CreatedDate					DATETIME
		,	CreatedBy					INT UNSIGNED
		,	LastModifiedDate			DATETIME
		,	LastModifiedBy				INT UNSIGNED
		,	LastScannedDate				DATETIME
		,	IsFromTVS					TINYINT(1) 
		,	IsFromTW					TINYINT(1) 
		,	IsFromCTS					TINYINT(1) 
		,	IsFromAI					TINYINT(1)
		,	IsFromImperva				TINYINT(1)
		,	InsertTime					DATETIME
		,	IsMarkedDirectly			TINYINT(1)
		,	SpecialCC	       			SMALLINT 
		,	CustomerClass				INT 
		,	CategoryPriority			SMALLINT
		,	CustomerClassPriority		SMALLINT
		,	IsPAProbation				TINYINT(1)
		,	IsMultiCateIDSameParentID	TINYINT(1)
		,	IsKeepOldCateID				TINYINT(1)
		,	IsNew						TINYINT(1) DEFAULT 1
		,	IsRemove					TINYINT(1) DEFAULT NULL
		,	INDEX IX_Temp_CCOld_CustID_ParentID_CategoryGroupID (ParentID,CategoryGroupID,CustID,IsNew,IsRemove)
	);
	
		/*1 - VVIP*/
	IF ip_InputFlowID = CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_VVIP THEN 
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
			,	CONST_AGENCY_PARENTID_VVIP
			,	CONST_AGENCY_CATEID_VVIP
			,	CONST_AGENCY_CATEID_VVIP
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
			LEFT JOIN CTS_DataCenter.CTSCustomerClassificationAgency AS cls ON tmpJs.CustID = cls.CustID 
																			AND cls.ParentID = CONST_AGENCY_PARENTID_VVIP
																			AND cls.CategoryID = CONST_AGENCY_CATEID_VVIP;

	ELSE
		
		/*5 - PA-Category*/
		IF ip_InputFlowID IN (CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_PACATEGORY,CONST_AGENCY_INPUTFLOWID_GENERAL_RESCAN_PACATEGORY) THEN 
			
			INSERT INTO Temp_NewClassification(
					CustID, CTSCustID, RoleID, SubscriberID, DWCategoryID, DWCategoryGroupID,IsLicensee, IsLicenseeVIP, IsLicenseeBA, CreatedBy, Remark, IsMarkedDirectly
				, 	WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsFromCTS
				,	IsPAProbation, RelevantCategoryID, CreatedDate, IsFromTW, IsFromAI, IsFromImperva
				,	CategoryPriority, CustomerClassPriority, ParentID, IsDataChanged, PerformanceTime, IsRobot)
			SELECT 	tmpJs.CustID
				,	CASE WHEN tmpJs.CTSCustID = 0 THEN cus.CTSCustID ELSE tmpJs.CTSCustID END
				,	CASE WHEN tmpJs.RoleID = 0 THEN cus.RoleID ELSE tmpJs.RoleID END
				,	CASE WHEN tmpJs.SubscriberID = 0 THEN cus.SubscriberID ELSE tmpJs.SubscriberID END
				,	tmpJs.DWCategoryID
				,	cat.CategoryGroupID
				,	CASE WHEN tmpJs.IsLicensee = 0 THEN cus.IsLicensee ELSE tmpJs.IsLicensee END
				,	cus.IsLicenseeVIP
				,	cus.IsLicenseeBA
				,	tmpJs.CreatedBy 
				,	tmpJs.Remark END AS Remark
				,	tmpJs.IsMarkedDirectly
				, 	IFNULL(tmpJs.WinlossStatus,2) AS  WinlossStatus
				, 	tmpJs.TurnoverRM
				, 	tmpJs.WinlossRM 
				, 	tmpJs.BetCount 
				, 	tmpJs.ActiveDays
				,	tmpJs.IsFromCTS
				,	(CASE WHEN tmpJs.WinlossStatus = 0 THEN 1 ELSE 0 END) AS IsPAProbation	/*1: PROBATION, 0: NOT PROBATION*/
				,	cat.RelevantCategoryID
				,	tmpJs.CreatedDate
				,	tmpJs.IsFromTW
				,	tmpJs.IsFromAI
				,	tmpJs.IsFromImperva
				,	cat.CategoryPriority
				,	cat.CustomerClassPriority
				,	cat.ParentID
				,	0 AS IsDataChanged
				,	tmpJs.PerformanceTime
				,	CASE WHEN cat.CustomerClassName = 'Robot' THEN 1 ELSE 0 END AS IsRobot
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
											, 	IsFromCTS					TINYINT(1) 			PATH "$.IsFromCTS"
											, 	CreatedDate					DATETIME			PATH "$.CreatedDate"
											, 	PerformanceTime				DATETIME			PATH "$.PerformanceTime"
											,	IsFromTW					TINYINT(1)			PATH "$.IsFromTW"
											,	IsFromAI					TINYINT(1)			PATH "$.IsFromAI"
											,	IsFromImperva				TINYINT(1)			PATH "$.IsFromImperva"
											)) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmpJs.CustID
				LEFT JOIN CTS_DataCenter.CustomerCategoryAgency AS cat ON cat.CategoryID = tmpJs.DWCategoryID
			ON DUPLICATE KEY UPDATE TurnoverRM = IFNULL(Temp_NewClassification.TurnoverRM, tmpJs.TurnoverRM)  
								,	WinlossRM = IFNULL(Temp_NewClassification.WinlossRM, tmpJs.WinlossRM)  
								,	BetCount = IFNULL(Temp_NewClassification.BetCount, tmpJs.BetCount)  
								,	ActiveDays = IFNULL(Temp_NewClassification.ActiveDays, tmpJs.ActiveDays)
								,	IsFromCTS = CASE WHEN tmpJs.IsFromCTS = 1 THEN 1 ELSE Temp_NewClassification.IsFromCTS END
								,	IsMarkedDirectly = CASE WHEN tmpJs.IsMarkedDirectly = 1 THEN 1 ELSE Temp_NewClassification.IsMarkedDirectly END
								,	IsFromImperva = CASE WHEN tmpJs.IsFromImperva = 1 THEN 1 ELSE Temp_NewClassification.IsFromImperva END
								,	IsFromTW = CASE WHEN tmpJs.IsFromTW = 1 THEN 1 ELSE Temp_NewClassification.IsFromTW END
								,	IsFromAI = CASE WHEN tmpJs.IsFromAI = 1 THEN 1 ELSE Temp_NewClassification.IsFromAI END
								;

		/*9 - Normal*/
		ELSEIF ip_InputFlowID = CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_NORMAL THEN 
			INSERT INTO Temp_NewClassification(
					CustID,CTSCustID,DWCategoryID,DWCategoryGroupID,TurnoverRM,WinlossRM,BetCount,ActiveDays,PerformanceTime
				,	SubscriberID,RoleID,IsLicensee,IsLicenseeVIP,IsLicenseeBA,IsDataChanged)
			SELECT DISTINCT
					tmpJs.CustID
				,	cus.CTSCustID
				, 	tmpJs.DWCategoryID
				, 	tmpJs.DWCategoryGroupID
                , 	tmpJs.TurnoverRM
                , 	tmpJs.WinlossRM
                , 	tmpJs.BetCount
                , 	tmpJs.ActiveDays
                ,	tmpJs.PerformanceTime
				,	cus.SubscriberID
				,	cus.RoleID
				,	cus.IsLicensee
				,	cus.IsLicenseeVIP
				,	cus.IsLicenseeBA
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
											, 	PerformanceTime			DATETIME			PATH "$.PerformanceTime"
										)) AS tmpJs
				INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpJs.CustID = cus.CustID AND cus.CustSubID = 0;
				
			UPDATE Temp_NewClassification AS temp
			SET temp.IsExistPA = 1
			WHERE EXISTS (	SELECT 1
							FROM CTS_DataCenter.CTSCustomerClassificationAgency AS cls
							WHERE temp.CustID = cls.CustID
								AND cls.ParentID = CONST_AGENCY_PARENTID_PA
						 );
			
		END IF;
		
		UPDATE Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CustomerCategoryAgency AS cat ON cat.CategoryID = temp.DWCategoryID
		SET temp.DWCategoryGroupID = cat.CategoryGroupID
		WHERE temp.DWCategoryID IS NOT NULL
			AND temp.DWCategoryGroupID IS NULL;
		
		UPDATE Temp_NewClassification AS temp
		SET 	temp.IsExistVVIP 	= 1
			,	temp.IsDataChanged 	= 1
		WHERE EXISTS (	SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassificationAgency AS cls
						WHERE temp.CustID = cls.CustID
							AND cls.ParentID = CONST_AGENCY_PARENTID_VVIP
							AND cls.CategoryID = CONST_AGENCY_CATEID_VVIP
					 );

    END IF;
    
END$$
DELIMITER ;