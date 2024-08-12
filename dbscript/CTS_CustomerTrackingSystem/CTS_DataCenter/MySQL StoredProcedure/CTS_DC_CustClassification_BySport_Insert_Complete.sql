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
		
		Param's Expanation:
			- 
			
		Example:
			- CALL CTS_DC_CustClassification_BySport_Insert_Complete(332);
			
		Revisions: 
			- 20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
*/
	DECLARE CONST_CATEID_SPECIALCC 							INT;
	DECLARE CONST_PARENTID_WRAPPER 							INT;
	DECLARE CONST_PARENTID_NORMAL							INT;
	DECLARE CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL			INT;
	DECLARE CONST_INPUTFLOWID_BYSPORT_INSERT_SPECIALCC		INT;
	DECLARE CONST_ACTIONTYPE_INSERT 						INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 						INT DEFAULT 1;
	DECLARE CONST_SOURCETYPE_CUSTOMERCLASS_ADD_MANUAL		INT DEFAULT 10;

	DECLARE	lv_CurrentDateTime								DATETIME(3) DEFAULT CURRENT_TIME(3);
	DECLARE lv_ActionType									INT;
	DECLARE lv_CreatedBy									INT DEFAULT 10278938;
	
	SET CONST_CATEID_SPECIALCC								= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SPECIALCC');
	SET CONST_PARENTID_WRAPPER								= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_PARENTID_NORMAL								= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');
	SET CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL				= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL');
	SET CONST_INPUTFLOWID_BYSPORT_INSERT_SPECIALCC			= CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_BYSPORT_INSERT_SPECIALCC');
	
	IF ip_InputFlowID = CONST_INPUTFLOWID_BYSPORT_INSERT_SPECIALCC THEN
		SET lv_ActionType 		= 0;
		
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
		FROM Temp_NewClassification AS temp
		WHERE temp.IsDataChanged = 1;
		
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
		FROM Temp_NewClassification AS temp
		WHERE temp.IsDataChanged = 1;
		
		/*	INSERT */
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport (
				CustID, CTSCustID, SportID, ParentID, CategoryID, CreatedDate, CreatedBy
			, 	LastModifiedDate, LastModifiedBy, LastScannedDate)
		SELECT DISTINCT 
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.SportID
			,	CONST_PARENTID_WRAPPER
			, 	temp.NewCategoryID
			, 	lv_CurrentDateTime AS CreatedDate
			, 	temp.CreatedBy AS CreatedBy
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	lv_CreatedBy AS LastModifiedBy
			, 	DATE(lv_CurrentDateTime) AS LastScannedDate
		FROM Temp_NewClassification AS temp
		WHERE temp.IsDataChanged = 1;
		
		/*	INSERT HISTORY	*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_BySport_History (
				CustID, CTSCustID, SportID, ParentID, CategoryID, LastModifiedDate, LastModifiedBy
			, 	ActionType, InsertDate, TargetCC, Remark, SourceTypeID)
		SELECT	temp.CustID
			,	temp.CTSCustID
			,	temp.SportID
			,	CONST_PARENTID_WRAPPER
			, 	temp.NewCategoryID
			,	lv_CurrentDateTime AS LastModifiedDate
			,	temp.CreatedBy AS LastModifiedBy
			,	lv_ActionType AS ActionType
			,	DATE(lv_CurrentDateTime) AS InsertDate
			, 	temp.TargetCC
			,	temp.Remark
			,	CONST_SOURCETYPE_CUSTOMERCLASS_ADD_MANUAL
		FROM Temp_NewClassification AS temp
		WHERE temp.IsDataChanged = 1;
		
		/*	INSERT LOG	*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_BySport_Log (
				CustID, CTSCustID, SportID, ParentID, CategoryID, LastModifiedDate, LastModifiedBy
			, 	ActionType, InsertDate, TargetCC, Remark, SourceTypeID)
		SELECT	temp.CustID
			,	temp.CTSCustID
			,	temp.SportID
			,	CONST_PARENTID_WRAPPER
			, 	temp.NewCategoryID
			,	lv_CurrentDateTime AS LastModifiedDate
			,	temp.CreatedBy AS LastModifiedBy
			,	lv_ActionType AS ActionType
			,	DATE(lv_CurrentDateTime) AS InsertDate
			, 	temp.TargetCC
			,	temp.Remark
			,	CONST_SOURCETYPE_CUSTOMERCLASS_ADD_MANUAL
		FROM Temp_NewClassification AS temp;
		
	ELSEIF ip_InputFlowID = CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL THEN
		
		UPDATE CTS_DataCenter.CTSCustomerClassification_BySport AS cate
			INNER JOIN Temp_NewClassification AS temp ON cate.CustID = temp.CustID AND cate.SportID = temp.SportID AND cate.ParentID = CONST_PARENTID_NORMAL
		SET   	cate.CTSCustID 			= temp.CTSCustID
			, 	cate.CategoryID 		= temp.NewCategoryID
			, 	cate.LastModifiedDate 	= CASE WHEN temp.IsFromOld = 0 THEN lv_CurrentDateTime ELSE cate.LastModifiedDate END 
			, 	cate.LastScannedDate 	= DATE(lv_CurrentDateTime)
		WHERE temp.ActionType 			= CONST_ACTIONTYPE_UPDATE;

		DELETE del
		FROM CTS_DataCenter.CTSCustomerClassification_BySport AS del
			INNER JOIN Temp_NewClassification AS temp ON del.CustID = temp.CustID AND del.SportID = temp.SportID
															AND del.ParentID = CONST_PARENTID_NORMAL
		WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport (
				CustID, CTSCustID, SportID, ParentID, CategoryID, CreatedDate, CreatedBy
			, 	LastModifiedDate, LastModifiedBy, LastScannedDate)
		SELECT DISTINCT 
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.SportID
			,	CONST_PARENTID_NORMAL
			, 	temp.NewCategoryID AS CategoryID
			, 	lv_CurrentDateTime AS CreatedDate
			, 	lv_CreatedBy AS CreatedBy
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	lv_CreatedBy AS LastModifiedBy
			, 	DATE(lv_CurrentDateTime) AS LastScannedDate
		FROM Temp_NewClassification AS temp
		WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport_History (
				CustID, CTSCustID, ParentID, CategoryID, SportID, LastModifiedDate, LastModifiedBy
			, 	TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, InsertDate, TargetCC
			, 	PerformanceTime, SourceTypeID)
		SELECT DISTINCT	
				temp.CustID
			, 	temp.CTSCustID
			,	CONST_PARENTID_NORMAL
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
		FROM 	Temp_NewClassification AS temp
		WHERE temp.IsDataChanged  = 1;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport_Log (
				CustID, CTSCustID, ParentID, CategoryID, SportID, LastModifiedDate, LastModifiedBy
			, 	TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, InsertDate, TargetCC
			, 	PerformanceTime, SourceTypeID, OldCategoryID, DWCategoryID, IsDataChanged)
		SELECT DISTINCT	
				temp.CustID
			, 	temp.CTSCustID
			,	CONST_PARENTID_NORMAL
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