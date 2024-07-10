/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert_Complete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert_Complete`(
		IN	ip_InputFlowID			INT
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

	-- CALL CTS_DataCenter.CTS_DC_CustClassification_Remark_Get(ip_InputFlowID); 

	DECLARE CONST_CATEID_LICVIPSUSPICIOUS 	INT;
	DECLARE CONST_CATEID_LICVIPDANGEROUS 	INT;
	DECLARE CONST_CATEID_LICBA 				INT;
	
	DECLARE CONST_PARENTID_WRAPPER 			INT;
	DECLARE CONST_PARENTID_NORMAL			INT;
	
	DECLARE CONST_ACTIONTYPE_INSERT 		INT DEFAULT 0;
	
	
    DECLARE lv_CreatedBy 					INT DEFAULT 10278938;
	DECLARE	lv_CurrentDateTime				DATETIME DEFAULT CURRENT_TIME();
	DECLARE	lv_InsertedCount				INT DEFAULT 0;
	DECLARE CONST_TVSRequestTypeID_PA		TINYINT DEFAULT 1;
	DECLARE CONST_TVSRequestTypeID_ROBOT	TINYINT DEFAULT 2;
	
	SET CONST_CATEID_LICVIPSUSPICIOUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_CATEID_LICVIPDANGEROUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
	SET CONST_CATEID_LICBA 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
	
	SET CONST_PARENTID_WRAPPER 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_PARENTID_NORMAL 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');
	
	IF ip_InputFlowID = 8 THEN /*Normal*/
		UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN Temp_NewClassification AS temp ON temp.CustID = cate.CustID 
															AND cate.ParentID = CONST_PARENTID_WRAPPER
		SET   	cate.CategoryID = 	CASE 
										WHEN temp.NewIsDangerProbation = 1 
											THEN CONST_CATEID_LICVIPSUSPICIOUS
										ELSE CONST_CATEID_LICVIPDANGEROUS 
									END
		WHERE cate.CategoryID IN (CONST_CATEID_LICVIPSUSPICIOUS,CONST_CATEID_LICVIPDANGEROUS)
			AND temp.IsDataChanged = 1;
		
		DELETE del
		FROM CTS_DataCenter.CTSCustomerClassification AS del
			INNER JOIN Temp_NewClassification AS temp ON del.CustID = temp.CustID 
															AND del.ParentID = CONST_PARENTID_NORMAL
			INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.ParentID = del.ParentID AND ccs.IsKeepOldCateID = 0 
		WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
				CustID,CTSCustID,SubscriberID,RoleID,ParentID,CategoryID,CreatedDate,CreatedBy,LastModifiedDate
			,	LastModifiedBy,LastScannedDate)
		SELECT DISTINCT 
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.SubscriberID
			, 	temp.RoleID
			, 	CONST_PARENTID_NORMAL AS ParentID
			, 	temp.NewCategoryID AS CategoryID
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	DATE(lv_CurrentDateTime) AS LastScannedDate
		FROM Temp_NewClassification AS temp
		WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History (
				CustID, CTSCustID, CategoryID, ParentID, LastModifiedDate, LastModifiedBy, TurnoverRM
			, 	WinlossRM, BetCount, ActiveDays, TWBetCount, TWGroupBettingRate, TWTicketRejectRate, TWDesktopUsageRate
			, 	IsAuto, InsertDate, TargetCC, SourceTypeID, OldCategoryID, DWCategoryID, IsDataChanged
			, 	TaggingType, TargetDangerLevel1, PerformanceTime, ActionType)
		SELECT DISTINCT	
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.NewCategoryID AS CategoryID
			, 	CONST_PARENTID_NORMAL AS ParentID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	lv_CreatedBy AS LastModifiedBy
			, 	temp.TurnoverRM
			, 	temp.WinlossRM
			, 	temp.BetCount
			, 	temp.ActiveDays
			,	temp.TWBetCount
			, 	temp.TWGroupBettingRate
			, 	temp.TWTicketRejectRate
			, 	temp.TWDesktopUsageRate
			, 	1 AS IsAuto
			, 	DATE(lv_CurrentDateTime) AS InsertDate
			,	temp.TargetCC 
			,   temp.SourceTypeID
			, 	temp.OldCategoryID 
			, 	temp.DWCategoryID
			,   temp.IsDataChanged
			,	temp.TaggingType
			,	temp.TargetDangerLevel AS TargetDangerLevel1
			,	temp.PerformanceTime
			,	temp.ActionType
		FROM 	Temp_NewClassification AS temp
		WHERE temp.IsDataChanged  = 1;	
        
        INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log (
				CustID, CTSCustID, CategoryID, ParentID, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM
			, 	BetCount, ActiveDays, TWBetCount, TWGroupBettingRate, TWTicketRejectRate, TWDesktopUsageRate
			, 	IsAuto, InsertDate, TargetCC, SourceTypeID, OldCategoryID, DWCategoryID, IsDataChanged
			, 	TaggingType, TargetDangerLevel1, PerformanceTime, ActionType)
		SELECT DISTINCT	
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.NewCategoryID AS CategoryID
			, 	CONST_PARENTID_NORMAL AS ParentID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	lv_CreatedBy
			, 	temp.TurnoverRM
			, 	temp.WinlossRM
			, 	temp.BetCount
			, 	temp.ActiveDays
			,	temp.TWBetCount
			, 	temp.TWGroupBettingRate
			, 	temp.TWTicketRejectRate
			, 	temp.TWDesktopUsageRate
			, 	1 AS IsAuto
			, 	DATE(lv_CurrentDateTime) AS InsertDate
			,	temp.TargetCC 
			,   temp.SourceTypeID
			, 	temp.OldCategoryID 
			, 	temp.DWCategoryID
			,   temp.IsDataChanged
			,	temp.TaggingType
			,	temp.TargetDangerLevel AS TargetDangerLevel1
			,	temp.PerformanceTime
			,	temp.ActionType
		FROM 	Temp_NewClassification AS temp;

	ELSEIF (ip_InputFlowID IN (50,51,6,7) OR ip_InputFlowID IN (150,151,16,17)) THEN
	/*(ip_InputFlowID IN (50,51,6,7) - insert
	ip_InputFlowID IN (150,151,16,17) - rescan*/
		SET lv_InsertedCount = 0;
		
		/*Insert into main table*/
		-- ADD MAIN TABLE CC - FROM OLD - isnew = 1
		-- Vic: check logic: if existing VVIP >> current will store in old table >> reonovate: store in CTCC main >> DWCateID? OldCateID?
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
				CustID, CTSCustID, SubscriberID,RoleID, ParentID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
			, 	LastScannedDate, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, IsMarkedDirectly, TVSRequestID, IsParlay
			, 	SportType, IssueTypeID) 
		SELECT 	temp_old.CustID
			, 	temp_old.CTSCustID
			, 	temp_old.SubscriberID
			, 	temp_old.RoleID
			, 	temp_old.ParentID
			, 	temp_old.CategoryID
			, 	temp_old.Remark
			, 	temp_old.CreatedDate
			, 	temp_old.CreatedBy
			, 	temp_old.LastModifiedDate
			, 	temp_old.LastModifiedBy
			, 	temp_old.LastScannedDate
			, 	temp_old.IsFromTVS
			, 	temp_old.IsFromTW
			, 	temp_old.IsFromCTS
			, 	temp_old.IsFromAI
			, 	temp_old.IsFromImperva
			, 	temp_old.IsMarkedDirectly
			, 	temp_old.TVSRequestID
			, 	temp_old.IsTVSParlay
			, 	temp_old.SportType
			, 	temp_old.TVSIssueTypeID
		FROM Temp_CTSCustomerClassification_Old AS temp_old
		WHERE temp_old.IsNew = 1;
		
		SET lv_InsertedCount = FOUND_ROWS();
		
		-- DELETE MAIN TABLE - FROM OLD - isnew = 0 + IsRemove = 1
		DELETE cls
		FROM CTS_DataCenter.CTSCustomerClassification AS cls
			INNER JOIN Temp_CTSCustomerClassification_Old AS temp_old ON temp_old.CustID = cls.CustID
																			AND temp_old.ExistCategoryID = cls.CategoryID
		WHERE temp_old.IsNew = 0 AND temp_old.IsRemove = 1;
		
		UPDATE IGNORE CTS_DataCenter.CTSCustomerClassification AS cls
			INNER JOIN Temp_NewClassification AS temp ON cls.CustID = temp.CustID AND cls.CategoryID = temp.OldCategoryID 
																						AND temp.DataChangeType = 1
		SET 	cls.CTSCustID 			=  temp.CTSCustID
			,	cls.CategoryID 			=  temp.NewCategoryID
			, 	cls.LastScannedDate 	=  DATE(lv_CurrentDateTime); 
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
				CustID, CTSCustID, SubscriberID, RoleID, CategoryID, ParentID, CreatedDate, CreatedBy, LastModifiedDate
			, 	LastModifiedBy, LastScannedDate, IsMarkedDirectly, Remark, IsFromCTS, IsFromAI, IsFromImperva, IsFromTVS, IsFromTW
			, 	TVSRequestID, IsParlay, SportType, IssueTypeID)
		SELECT 	temp.CustID
			,	temp.CTSCustID
			, 	temp.SubscriberID
			, 	temp.RoleID
			, 	temp.NewCategoryGroupID AS CategoryID
			, 	temp.ParentID
			, 	lv_CurrentDateTime AS CreatedDate
			, 	temp.CreatedBy
			, 	IFNULL(temp.LastModifiedDate, lv_CurrentDateTime) AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			, 	DATE(lv_CurrentDateTime) AS LastScannedDate
			,	temp.IsMarkedDirectly
			,	temp.Remark
			,	temp.IsFromCTS
			,	temp.IsFromAI
			,	temp.IsFromImperva
			,	temp.IsFromTVS
			,	temp.IsFromTW
			,	temp.TVSRequestID
			,	temp.IsTVSParlay
			,	temp.SportType
			,	temp.TVSIssueTypeID
		FROM Temp_NewClassification AS temp 
		WHERE temp.DataChangeType = 0 OR temp.IsFromOldPA = 1;   
		
		SET lv_InsertedCount = FOUND_ROWS();
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(
				CustID, CTSCustID, CategoryID, ParentID, LastModifiedDate, LastModifiedBy, ActionType
			, 	InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays
			, 	IsMarkedDirectly, Remark, TVSRequestID, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, IsParlay, SportType
			, 	IssueTypeID, RobotCounter, OldCategoryID, DWCategoryID, PerformanceTime)
		SELECT 	temp.CustID
			, 	temp.CTSCustID
			, 	temp.NewCategoryID AS CategoryID
			,	temp.ParentID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			, 	temp.ActionType
			, 	DATE(lv_CurrentDateTime) AS InsertDate
			, 	temp.TargetCC
			, 	(CASE	WHEN ccs.CategoryID IS NOT NULL THEN ccs.RemarkTemplateID
						WHEN temp.MatchID IS NOT NULL OR ccs.CategoryID IS NOT NULL THEN ccs.RemarkTemplateID
						WHEN temp.IsMarkedDirectly = 1 THEN 31 
						WHEN temp.IsMarkedDirectly = 0 THEN 32 END) AS SourceTypeID
			,  	1 AS IsDataChanged
			,	temp.TargetDangerLevel AS TargetDangerLevel1
			,	temp.TurnoverRM
			,	temp.WinlossRM
			, 	temp.BetCount
			, 	temp.ActiveDays
			,	temp.IsMarkedDirectly
			,	temp.Remark
			,	temp.TVSRequestID
			,	temp.IsFromTVS
			,	temp.IsFromTW
			,	temp.IsFromCTS
			,	temp.IsFromAI
			,	temp.IsFromImperva
			,	temp.IsTVSParlay
			,	temp.SportType
			,	temp.TVSIssueTypeID
			,	temp.TWRobotCounter
			,	temp.OldCategoryID
			,	temp.DWCategoryID
			,	temp.PerformanceTime
		FROM Temp_NewClassification AS temp
			LEFT JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.CategoryID = temp.NewCategoryID 
		WHERE temp.IsDataChanged = 1 
		ORDER BY temp.LastModifiedDate ASC, temp.NewCategoryID ASC;
		
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(
				CustID, CTSCustID, CategoryID, ParentID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate
			, 	TargetCC, SourceTypeID, IsDataChanged,TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsMarkedDirectly, Remark, TVSRequestID
			, 	IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, IsParlay, SportType, IssueTypeID, RobotCounter
			, 	OldCategoryID, DWCategoryID, PerformanceTime)
		SELECT 	temp.CustID
			,	temp.CTSCustID
			,	temp.NewCategoryID
			,	temp.ParentID
			,	IFNULL(temp.LastModifiedDate,lv_CurrentDateTime)
			,	temp.CreatedBy AS LastModifiedBy
			,	temp.ActionType
			,	1 AS IsAuto 
			,	DATE(lv_CurrentDateTime) AS InsertDate
			,	temp.TargetCC
			, 	(CASE	WHEN ccs.CategoryID IS NOT NULL THEN ccs.RemarkTemplateID
						WHEN temp.MatchID IS NOT NULL OR ccs.CategoryID IS NOT NULL THEN ccs.RemarkTemplateID
						WHEN temp.IsMarkedDirectly = 1 THEN 31 
						WHEN temp.IsMarkedDirectly = 0 THEN 32 END) AS SourceTypeID
			,	temp.IsDataChanged
			,	temp.TargetDangerLevel AS TargetDangerLevel1
			,	temp.TurnoverRM
			,	temp.WinlossRM
			,	temp.BetCount
			,	temp.ActiveDays
			,	temp.IsMarkedDirectly
			,	temp.Remark
			,	temp.TVSRequestID
			,	temp.IsFromTVS
			,	temp.IsFromTW
			,	temp.IsFromCTS
			,	temp.IsFromAI
			,	temp.IsFromImperva
			,	temp.IsTVSParlay
			,	temp.SportType
			,	temp.TVSIssueTypeID
			,	temp.TWRobotCounter
			,	temp.OldCategoryID
			,	temp.DWCategoryID
			,	temp.PerformanceTime
		FROM Temp_NewClassification AS temp
			LEFT JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.CategoryID = temp.NewCategoryID ;
			
		/*Insert into source table*/
		IF (IFNULL(lv_InsertedCount,0) > 0) THEN
			IF ip_InputFlowID IN (50,51) AND EXISTS (SELECT 1 FROM Temp_NewClassification WHERE IsFromTVS = 1) THEN
				INSERT INTO CTS_DataCenter.TVSVoidRequest (
						TVSRequestID,CustID,TVSReasonID,IssueTypeID,CreatedBy,IsParlay,SportType
					,	RequestTypeID,CreatedDate,InsertedTime)
				SELECT 	temp.TVSRequestID,temp.CustID,temp.TVSReasonID,temp.TVSIssueTypeID,temp.CreatedBy,temp.IsTVSParlay,temp.SportType
					,	CASE WHEN cc.CustomerClassName = 'Robot' THEN CONST_TVSRequestTypeID_ROBOT ELSE CONST_TVSRequestTypeID_PA END AS RequestTypeID
					,	lv_CurrentDateTime AS CreatedDate
					,	CURRENT_TIMESTAMP(3) AS InsertedTime
				FROM Temp_NewClassification AS temp
					INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON temp.TVSReasonID = cc.TVSReasonID AND cc.IsActive = 1
				WHERE temp.IsFromTVS = 1;
			END IF;
	
			IF ip_InputFlowID = 6 AND EXISTS (SELECT 1 FROM Temp_NewClassification WHERE IsFromTW = 1) THEN
				INSERT INTO CTS_DataCenter.Customer_InitialGroupBetting (CustID,GBTicketCount,SportType,SourceCreatedDate,CreatedDate)
				SELECT temp.CustID,temp.GBTicketCount,temp.SportType,temp.SourceCreatedDate,lv_CurrentDateTime AS CreatedDate
				FROM Temp_NewClassification AS temp
				WHERE temp.IsFromTW = 1 AND temp.GBTicketCount > 0;
			END IF;
			
			IF ip_InputFlowID = 7 AND EXISTS (SELECT 1 FROM Temp_NewClassification WHERE IsFromTW = 1) THEN
				INSERT INTO CTS_DataCenter.TWRobotUser (CustID,CategoryID,RobotCounter,CreatedDate)
				SELECT temp.CustID,temp.NewCategoryID,temp.RobotCounter,lv_CurrentDateTime AS CreatedDate
				FROM Temp_NewClassification AS temp
				WHERE temp.IsFromTW = 1;
			END IF;
			
			IF ip_InputFlowID = 7 AND EXISTS (SELECT 1 FROM Temp_NewClassification WHERE IsFromCTS = 1) THEN
				INSERT INTO CTS_DataCenter.CTSRobotUser (CustID,CategoryID,Remark,CreatedDate)
				SELECT temp.CustID,temp.NewCategoryID,temp.Remark,lv_CurrentDateTime AS CreatedDate
				FROM Temp_NewClassification AS temp
				WHERE temp.IsFromCTS = 1;
			END IF;
	
		END IF;
		
	END IF;
	
END$$
DELIMITER ;