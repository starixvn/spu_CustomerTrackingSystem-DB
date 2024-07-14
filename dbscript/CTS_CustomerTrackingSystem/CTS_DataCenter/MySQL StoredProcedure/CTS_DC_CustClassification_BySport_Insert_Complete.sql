/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_BySport_Insert_Complete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_Insert_Complete`(
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
	-- DECLARE CONST_PARENTID_WRAPPER 			INT;
	DECLARE CONST_CATEID_SPECIALCC 			INT;
	
	DECLARE CONST_ACTIONTYPE_INSERT 		INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 		INT DEFAULT 1;

	DECLARE	lv_CurrentDateTime				DATETIME(3) DEFAULT CURRENT_TIME();
	DECLARE lv_ActionType					INT;
	DECLARE lv_SourceTypeID					INT;
	
	-- SET CONST_PARENTID_WRAPPER				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_CATEID_SPECIALCC				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SPECIALCC');

	IF ip_InputFlowID = 332 THEN /*SpecialCC*/
		SET lv_ActionType 		= 0;
		SET lv_SourceTypeID 	= 10;
		
		/*	INSERT VALID SPECIAL CUSTOMER CLASS	*/
		INSERT INTO CTS_DataCenter.SpecialCustomerClass_BySport(
				CTSCustID, CustID, SportID, SubscriberID, CustomerClass, CreatedBy
			, 	CreatedDate, LastModifiedBy, LastModifiedDate)
		SELECT 	temp.CTSCustID
			,	temp.CustID
			,	temp.SportID
			,	temp.SubscriberID
			,	temp.TargetCC AS CustomerClass
			,	temp.CreatedBy
			,	lv_CurrentDateTime AS CreatedDate
			,	temp.CreatedBy AS LastModifiedBy
			,	lv_CurrentDateTime AS LastModifiedDate
		FROM Temp_NewClassification AS temp;
		
		/*	INSERT LOG FOR SPECIAL CUSTOMER CLASS	*/
		INSERT INTO CTS_DataCenter.SpecialCustomerClass_BySport_History(
				CTSCustID, CustID, SportID, SubscriberID, CustomerClass, CreatedBy
			, 	CreatedDate, LastModifiedBy, LastModifiedDate, Remark, ActionType)
		SELECT 	temp.CTSCustID
			,	temp.CustID
			,	temp.SportID
			,	temp.SubscriberID
			,	temp.TargetCC AS CustomerClass
			,	temp.CreatedBy
			,	lv_CurrentDateTime AS CreatedDate
			,	temp.CreatedBy AS LastModifiedBy
			,	lv_CurrentDateTime AS LastModifiedDate
			,	temp.Remark
			,	lv_ActionType AS ActionType
		FROM Temp_NewClassification AS temp;
		
		/*	INSERT */
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport (
				CustID, CTSCustID, SportID, CategoryID, CreatedDate, CreatedBy
			, 	LastModifiedDate, LastModifiedBy, LastScannedDate)
		SELECT DISTINCT 
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.SportID
			, 	CONST_CATEID_SPECIALCC AS CategoryID
			, 	lv_CurrentDateTime AS CreatedDate
			, 	temp.CreatedBy AS CreatedBy
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	lv_CreatedBy AS LastModifiedBy
			, 	DATE(lv_CurrentDateTime) AS LastScannedDate
		FROM Temp_NewClassification AS temp
		WHERE NOT EXISTS (SELECT 1
							FROM CTS_DataCenter.CTSCustomerClassification_BySport AS cls
							WHERE cls.CustID = temp.CustID
								AND cls.SportID = temp.SportID
								AND cls.CategoryID = CONST_CATEID_SPECIALCC);
		
		/*	INSERT HISTORY	*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_BySport_History (
				CustID, CTSCustID, SportID, CategoryID, LastModifiedDate, LastModifiedBy
			, 	ActionType, InsertDate, TargetCC, Remark, SourceTypeID)
		SELECT	temp.CustID
			,	temp.CTSCustID
			,	temp.SportID
			, 	CONST_CATEID_SPECIALCC AS CategoryID
			,	lv_CurrentDateTime AS LastModifiedDate
			,	temp.CreatedBy AS LastModifiedBy
			,	lv_ActionType AS ActionType
			,	DATE(lv_CurrentDateTime) AS InsertDate
			, 	temp.TargetCC
			,	temp.Remark
			,	lv_SourceTypeID AS SourceTypeID
		FROM Temp_NewClassification AS temp;
		
		/*	INSERT LOG	*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_BySport_Log (
				CustID, CTSCustID, SportID, CategoryID, LastModifiedDate, LastModifiedBy
			, 	ActionType, InsertDate, TargetCC, Remark, SourceTypeID)
		SELECT	temp.CustID
			,	temp.CTSCustID
			,	temp.SportID
			, 	CONST_CATEID_SPECIALCC AS CategoryID
			,	lv_CurrentDateTime AS LastModifiedDate
			,	temp.CreatedBy AS LastModifiedBy
			,	lv_ActionType AS ActionType
			,	DATE(lv_CurrentDateTime) AS InsertDate
			, 	temp.TargetCC
			,	temp.Remark
			,	lv_SourceTypeID AS SourceTypeID
		FROM Temp_NewClassification AS temp;
		
	ELSEIF ip_InputFlowID = 339 THEN /*Normal*/
		
	
		UPDATE CTS_DataCenter.CTSCustomerClassification_BySport AS cate
			INNER JOIN Temp_NewClassification AS temp ON cate.CustID = temp.CustID
															AND cate.SportID = temp.SportID
		SET   	cate.CTSCustID 			= temp.CTSCustID
			, 	cate.CategoryID 		= temp.NewCategoryID
			, 	cate.LastModifiedDate 	= lv_CurrentDateTime
			, 	cate.LastScannedDate 	= DATE(lv_CurrentDateTime)
		WHERE temp.ActionType 			= CONST_ACTIONTYPE_UPDATE;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport (
				CustID, CTSCustID, SportID, CategoryID, CreatedDate, CreatedBy
			, 	LastModifiedDate, LastModifiedBy, LastScannedDate)
		SELECT DISTINCT 
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.SportID
			, 	temp.NewCategoryID AS CategoryID
			, 	lv_CurrentDateTime AS CreatedDate
			, 	lv_CreatedBy AS CreatedBy
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	lv_CreatedBy AS LastModifiedBy
			, 	DATE(lv_CurrentDateTime) AS LastScannedDate
		FROM Temp_NewClassification AS temp
		WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport_History (
				CustID, CTSCustID, CategoryID, SportID, LastModifiedDate, LastModifiedBy
			, 	TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, InsertDate, TargetCC
			, 	PerformanceTime, SourceTypeID, IsDataChanged)
		SELECT DISTINCT	
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.NewCategoryID AS CategoryID
			, 	temp.SportID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	lv_CreatedBy AS LastModifiedBy
			, 	temp.TurnoverRM
			, 	temp.WinlossRM
			, 	temp.BetCount
			, 	temp.ActiveDays
			, 	temp.ActionType
			, 	DATE(lv_CurrentDateTime) AS InsertDate
			,	temp.TargetCC 
			,	temp.PerformanceTime	
			,	temp.SourceTypeID
			,	temp.IsDataChanged
		FROM 	Temp_NewClassification AS temp
		WHERE temp.IsDataChanged  = 1;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport_Log (
				CustID, CTSCustID, CategoryID, SportID, LastModifiedDate, LastModifiedBy
			, 	TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, InsertDate, TargetCC
			, 	PerformanceTime, SourceTypeID, OldCategoryID, DWCategoryID, IsDataChanged)
		SELECT DISTINCT	
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.NewCategoryID AS CategoryID
			, 	temp.SportID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	lv_CreatedBy AS LastModifiedBy
			, 	temp.TurnoverRM
			, 	temp.WinlossRM
			, 	temp.BetCount
			, 	temp.ActiveDays
			, 	temp.ActionType
			, 	DATE(lv_CurrentDateTime) AS InsertDate
			,	temp.TargetCC 
			,	temp.PerformanceTime	
			,	temp.SourceTypeID
			,	temp.OldCategoryID
			,	temp.DWCategoryID
			,	temp.IsDataChanged
		FROM 	Temp_NewClassification AS temp;
		
	END IF;
	
END$$
DELIMITER ;