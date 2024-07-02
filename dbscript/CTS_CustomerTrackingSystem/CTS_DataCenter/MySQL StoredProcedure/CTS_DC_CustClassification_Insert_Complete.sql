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
	DECLARE CONST_CATEID_VVIP 				INT;
	DECLARE CONST_CATEID_LICVIPSUSPICIOUS 	INT;
	DECLARE CONST_CATEID_LICVIPDANGEROUS 	INT;
	DECLARE CONST_CATEID_LICBA 				INT;
	DECLARE CONST_PARENTID_VVIP 			INT;
	DECLARE CONST_PARENTID_WRAPPER 			INT;
	DECLARE CONST_PARENTID_PA 				INT;
	
	
    DECLARE lv_MaxCTSCustID					BIGINT UNSIGNED;
    DECLARE lv_LicVIPPriority				SMALLINT UNSIGNED;
    DECLARE lv_LicBAPriority				SMALLINT UNSIGNED;
	
	SET CONST_CATEID_VVIP 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	SET CONST_CATEID_LICVIPSUSPICIOUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_CATEID_LICVIPDANGEROUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
	SET CONST_CATEID_LICBA 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
	SET CONST_PARENTID_VVIP 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_VVIP');
	SET CONST_PARENTID_WRAPPER 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_PARENTID_PA 					= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
	
	IF ip_InputFlowID = 8 THEN /*Normal*/
		UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN Temp_NewClassification AS temp ON temp.CustID = cate.CustID 
															AND cate.ParentID = CONST_GROUP_WRAPPER
		SET   	cate.CategoryID = 	CASE 
										WHEN temp.NewIsDangerProbation = 1 
											THEN CONST_LICVIP_SUSPICIOUSCATEGORY
										ELSE CONST_LICVIP_DANGEROUSCATEGORY 
									END
		WHERE cate.CategoryID IN (CONST_LICVIP_SUSPICIOUSCATEGORY,CONST_LICVIP_DANGEROUSCATEGORY)
			AND temp.IsDataChanged = 1;
		
		DELETE del
		FROM CTS_DataCenter.CTSCustomerClassification AS del
			INNER JOIN Temp_NewClassification AS temp ON del.CustID = temp.CustID 
															AND del.ParentID = CONST_GROUP_NORMAL
			INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.ParentID = del.ParentID AND ccs.IsKeepOldCateID = 0 
		WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification
				CustID,CTSCustID,SubscriberID,ParentID,CategoryID,CreatedDate,CreatedBy,LastModifiedDate
			,	LastModifiedBy,LastScannedDate)
		SELECT DISTINCT 
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.SubscriberID
			, 	CONST_GROUP_NORMAL
			, 	temp.NewCateID
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
			, 	ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged
			, 	TaggingType, TargetDangerLevel1, PerformanceTime, SportType)
		SELECT DISTINCT	
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.NewCateID
			, 	CONST_GROUP_NORMAL
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	temp.TurnoverRM
			, 	temp.WinlossRM
			, 	temp.BetCount
			, 	temp.ActiveDays
			,	temp.TWBetCount
			, 	temp.TWGroupBettingRate
			, 	temp.TWTicketRejectRate
			, 	temp.TWDesktopUsageRate
			, 	temp.ActionType
			, 	1 AS IsAuto
			, 	DATE(lv_CurrentDateTime)
			,	temp.TargetCC 
			,   temp.SourceTypeID
			, 	temp.OldCateID 
			, 	temp.DWCateID
			,   temp.IsDataChanged
			,	temp.TaggingType
			,	temp.TargetDangerLevel AS TargetDangerLevel1
			,	temp.PerformanceTime
			,	temp.SportType
		FROM 	Temp_NewClassification AS temp
		WHERE temp.IsDataChanged  = 1;	
		
̣		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log (
				CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM
			, 	BetCount, ActiveDays, TWBetCount, TWGroupBettingRate, TWTicketRejectRate, TWDesktopUsageRate
			, 	ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged
			, 	TaggingType, TargetDangerLevel1, PerformanceTime, SportType)
		SELECT DISTINCT	
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.NewCateID
			, 	CONST_GROUP_NORMAL
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	temp.TurnoverRM
			, 	temp.WinlossRM
			, 	temp.BetCount
			, 	temp.ActiveDays
			,	temp.TWBetCount
			, 	temp.TWGroupBettingRate
			, 	temp.TWTicketRejectRate
			, 	temp.TWDesktopUsageRate
			, 	temp.ActionType
			, 	1
			, 	DATE(lv_CurrentDateTime)
			,	temp.TargetCC 
			,   temp.SourceTypeID
			, 	temp.OldCateID 
			, 	temp.DWCateID
			,   temp.IsDataChanged
			,	temp.TaggingType
			,	temp.TargetDangerLevel AS TargetDangerLevel1
			,	temp.PerformanceTime
			,	temp.SportType
		FROM 	Temp_NewClassification AS temp;
		
		
	ELSEIF ip_InputFlowID IN (50,51,6,7) THEN 
		-- ADD MAIN TABLE CC - FROM OLD - isnew = 1
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
				CustID, CTSCustID, SubscriberID, ParentID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
			, 	LastScannedDate, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsMarkedDirect, InsertTime, TVSRequestID, IsParlay, SportType, IssueTypeID) 
		SELECT temp_old.CustID
			, temp_old.CTSCustID
			, temp_old.SubscriberID
			, temp_old.ParentID
			, temp_old.CategoryID
			, temp_old.Remark
			, temp_old.CreatedDate
			, temp_old.CreatedBy
			, temp_old.LastModifiedDate
			, temp_old.LastModifiedBy
			, temp_old.LastScannedDate
			, temp_old.IsFromTVS
			, temp_old.IsFromTW
			, temp_old.IsFromCTS
			, temp_old.IsFromAI
			, temp_old.IsMarkedDirect
			, CURRENT_TIMESTAMP(3) AS InsertTime
			, temp_old.TVSRequestID
			, temp_old.IsParlay
			, temp_old.SportType
			, temp_old.IssueTypeID
		FROM Temp_CTSCustomerClassification_Old AS temp_old
		WHERE temp_old.IsNew = 1;
		
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
			,	cls.CategoryID 			=  temp.CategoryID
			, 	cls.LastScannedDate 	=  DATE(lv_CurrentDateTime); 
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
				CustID, CTSCustID, SubscriberID, CategoryID, ParentID, CreatedDate, CreatedBy, LastModifiedDate
			, 	LastModifiedBy, LastScannedDate, IsMarkedDirect, Remark, IsFromCTS, IsFromAI, IsFromTVS, IsFromTW
			, 	TVSRequestID, IsTVSParlay, SportType, TVSIssueTypeID)
		SELECT 	temp.CustID
			,	temp.CTSCustID
			, 	temp.SubscriberID
			, 	temp.NewCategoryGroupID AS CategoryID
			, 	temp.ParentID
			, 	NOW()
			, 	temp.CreatedBy
			, 	IFNULL(temp.LastModifiedDate, NOW()) AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			, 	NOW() AS LastScannedDate
			,	temp.IsMarkedDirect
			,	temp.Remark
			,	temp.IsFromCTS
			,	temp.IsFromAI
			,	temp.IsFromTVS
			,	temp.IsFromTW
			,	temp.TVSRequestID
			,	temp.IsTVSParlay
			,	temp.SportType
			,	temp.TVSIssueTypeID
		FROM Temp_NewClassification AS temp 
		WHERE temp.DataChangeType = 0 OR temp.IsFromOldPA = 1;   
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(
				CustID, CTSCustID, CategoryID, ParentID, LastModifiedDate, LastModifiedBy, ActionType
			, 	InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays
			, 	IsMarkedDirect, Remark, TVSRequestID, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsParlay, SportType, IssueTypeID )
		SELECT 	temp.CustID
			, 	temp.CTSCustID
			, 	temp.NewCategoryID
			,	temp.ParentID
			, 	NOW() AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			, 	temp.ActionType
			, 	NOW() AS InsertDate
			, 	temp.TargetCC
			, 	(CASE	WHEN ccs.CategoryID IS NOT NULL THEN ccs.RemarkTemplateID
						WHEN temp.MatchID IS NOT NULL OR ccs.CategoryID IS NOT NULL THEN ccs.RemarkTemplateID
						WHEN temp.IsMarkedDirect = 1 THEN 31 
						WHEN temp.IsMarkedDirect = 0 THEN 32 END) AS SourceTypeID
			,  	1 AS IsDataChanged
			,	temp.TargetDangerLevel AS TargetDangerLevel1
			,	temp.TurnoverRM
			,	temp.WinlossRM
			, 	temp.BetCount
			, 	temp.ActiveDays
			,	temp.IsMarkedDirect
			,	temp.Remark
			,	temp.TVSRequestID
			,	temp.IsFromTVS
			,	temp.IsFromTW
			,	temp.IsFromCTS
			,	temp.IsFromAI
			,	temp.IsTVSParlay
			,	temp.SportType
			,	temp.TVSIssueTypeID
		FROM Temp_NewClassification AS temp
			LEFT JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.CategoryID = temp.NewCategoryID 
		WHERE temp.IsDataChanged = 1 
		ORDER BY temp.LastModifiedDate ASC, temp.NewCategoryID ASC;
		
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(
				CustID, CTSCustID, CategoryID, ParentID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate
			, 	TargetCC, SourceTypeID, IsDataChanged,TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsMarkedDirect, Remark, TVSRequestID
			, 	IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsParlay, SportType, IssueTypeID)
		SELECT 	temp.CustID
			,	temp.CTSCustID
			,	temp.NewCategoryID
			,	temp.ParentID
			,	IFNULL(temp.LastModifiedDate,NOW())
			,	temp.CreatedBy AS LastModifiedBy
			,	temp.ActionType
			,	1 AS IsAuto 
			,	NOW() AS InsertDate
			,	temp.TargetCC
			, 	(CASE	WHEN ccs.CategoryID IS NOT NULL THEN ccs.RemarkTemplateID
						WHEN temp.MatchID IS NOT NULL OR ccs.CategoryID IS NOT NULL THEN ccs.RemarkTemplateID
						WHEN temp.IsMarkedDirect = 1 THEN 31 
						WHEN temp.IsMarkedDirect = 0 THEN 32 END) AS SourceTypeID
			,	temp.IsDataChanged
			,	temp.TargetDangerLevel AS TargetDangerLevel1
			,	temp.TurnoverRM
			,	temp.WinlossRM
			,	temp.BetCount
			,	temp.ActiveDays
			,	temp.IsMarkedDirect
			,	temp.Remark
			,	temp.TVSRequestID
			,	temp.IsFromTVS
			,	temp.IsFromTW
			,	temp.IsFromCTS
			,	temp.IsFromAI
			,	temp.IsTVSParlay
			,	temp.SportType
			,	temp.TVSIssueTypeID
		FROM Temp_NewClassification AS temp
			LEFT JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.CategoryID = temp.NewCategoryID ;
	
	END IF;
	
END$$
DELIMITER ;