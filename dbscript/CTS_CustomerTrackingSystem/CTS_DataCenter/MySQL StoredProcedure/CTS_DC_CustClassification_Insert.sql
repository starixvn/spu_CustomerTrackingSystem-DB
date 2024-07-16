/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_FromAction			TINYINT
	,	IN	ip_UplineRoleID			INT
	,	IN	ip_QueueID				BIGINT
	,	IN	ip_AffectDownline		TINYINT(1)
	,	IN	ip_IsToQueue			TINYINT(1)
	,	IN	ip_CustInfo				JSON
	,	OUT op_ErrorMessage 		VARCHAR(2000)
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
		
		Example:
			- CALL CTS_DC_CustClassification_Insert(8, 0, 0, 0, false, false, '[{"CustID":1275,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":1280,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5002646,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5022391,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0}]', @outParam7);
*/
	DECLARE CONST_CATEID_VVIP 				INT;
	DECLARE CONST_CATEID_LICVIPSUSPICIOUS 	INT;
	DECLARE CONST_CATEID_LICVIPDANGEROUS 	INT;
	DECLARE CONST_CATEID_LICBA 				INT;
	DECLARE CONST_CATEID_SPECIALCC 			INT;
	DECLARE CONST_CC_LICVIPSUSPICIOUS		INT;
	DECLARE CONST_CC_LICVIPDANGEROUS		INT;
	DECLARE CONST_CC_LICBA					INT;
	
	DECLARE CONST_PARENTID_WRAPPER 			INT;
	
	DECLARE lv_MaxCTSCustID					BIGINT;
	
	DECLARE lv_IsParallelParentID			TINYINT(1);  
	DECLARE lv_ParentID						INT UNSIGNED;  
	DECLARE lv_SourceTypeID					INT;  
	DECLARE lv_ActionType					INT;  
	DECLARE lv_IsAuto						TINYINT(1);  
	DECLARE lv_IsMarkedDirectly				TINYINT(1);  

	DECLARE lv_CustomerClass				SMALLINT UNSIGNED;  
	DECLARE lv_CategoryPriority				SMALLINT UNSIGNED;  
	DECLARE lv_BACatePriority				SMALLINT;
    DECLARE lv_BA_CC						SMALLINT;
	
	DECLARE lv_LogTypeID					INT;
	DECLARE lv_CreatedBy					INT;
	DECLARE	lv_CurrentDateTime				DATETIME(3) DEFAULT CURRENT_TIME();
	DECLARE lv_SPName 						VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_Insert';
	
	
	SET CONST_CATEID_VVIP 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_VVIP');
	SET CONST_CATEID_LICVIPSUSPICIOUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_CATEID_LICVIPDANGEROUS 		= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
	SET CONST_CATEID_LICBA 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
	SET CONST_CATEID_SPECIALCC				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SPECIALCC');
	SET CONST_CC_LICVIPSUSPICIOUS			= CTS_DC_CategoryTypeParent_Get ('CONST_CC_LICVIPSUSPICIOUS');
	SET CONST_CC_LICVIPDANGEROUS			= CTS_DC_CategoryTypeParent_Get ('CONST_CC_LICVIPDANGEROUS');
	SET CONST_CC_LICBA						= CTS_DC_CategoryTypeParent_Get ('CONST_CC_LICBA');

	SET CONST_PARENTID_WRAPPER 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	
	/*STEP 1: Parse raw data and get custinfo*/
	CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_GetInfo (ip_InputFlowID,ip_CustInfo);
	
	IF ip_InputFlowID = 1 THEN /*VVIP*/
		SELECT  ccs.IsParallelParentID, cc.ParentID, cc.CategoryPriority
		INTO lv_IsParallelParentID, lv_ParentID, lv_CategoryPriority
		FROM CTS_DataCenter.CustomerCategorySettings AS ccs
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = ccs.CategoryID
		WHERE ccs.CategoryID = CONST_CATEID_VVIP;
	
		SET lv_SourceTypeID = CASE 	WHEN ip_FromAction = 1 THEN 13
									WHEN ip_FromAction = 2 AND ip_UplineRoleID = 4 THEN 24
									WHEN ip_FromAction = 2 AND ip_UplineRoleID = 3 THEN 25
									WHEN ip_FromAction = 2 AND ip_UplineRoleID = 2 THEN 26
									WHEN ip_FromAction = 3 THEN 30
							  END;
							  
		SET lv_IsAuto = 0;
		
		IF ip_FromAction = 1 THEN
			SET lv_IsMarkedDirectly = 1;
		ELSE
			SET lv_IsMarkedDirectly = 0;
		END IF;
		
		IF lv_IsParallelParentID = 0 THEN
			/*Remove all categories which IsKeepOldCateID = 0*/							
			DELETE cls							
			FROM CTS_DataCenter.CTSCustomerClassification AS cls							
				INNER JOIN Temp_NewClassification AS temp ON cls.CustID = temp.CustID						
			WHERE temp.IsExistVVIP = 0							
				AND NOT EXISTS (SELECT 1 
								FROM CTS_DataCenter.CustomerCategorySettings AS cs	
									INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cs.CategoryID
								WHERE cs.CategoryID = cls.CategoryID	
									AND cs.CategoryPriority > lv_CategoryPriority 
									AND (cs.ParentID <> lv_ParentID OR (cs.ParentID = lv_ParentID AND cs.IsMultiCateIDSameParentID = 1))
									AND cs.IsKeepOldCateID = 1);	
		
			DELETE cls							
			FROM CTS_DataCenter.SpecialCustomerClass AS cls							
				INNER JOIN Temp_NewClassification AS temp ON cls.CustID = temp.CustID						
			WHERE temp.IsExistVVIP = 0							
				AND cls.CreatedFromFunction = 1;
		END IF;

		/*Insert VVIP*/
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification (
				CustID, CTSCustID, SubscriberID, RoleID, ParentID, CategoryID
			, 	Remark, CreatedBy, LastModifiedBy, CreatedDate, LastModifiedDate
			, 	LastScannedDate, IsAffectToDownline, IsMarkedDirectly)
		SELECT 	temp.CustID
			, 	temp.CTSCustID
			, 	temp.SubscriberID
			,	temp.RoleID
			,	temp.ParentID
			,	temp.NewCategoryID
			,	temp.Remark
			,   temp.CreatedBy AS CreatedBy
			,   temp.CreatedBy AS LastModifiedBy
			, 	lv_CurrentDateTime AS CreatedDate
			,   lv_CurrentDateTime AS LastModifiedDate 
			,   DATE(lv_CurrentDateTime) AS LastScannedDate 
			,	ip_AffectDownline AS IsAffectToDownline
			,	lv_IsMarkedDirectly AS IsMarkedDirectly
		FROM Temp_NewClassification AS temp
		WHERE temp.IsExistVVIP = 0;
		
		/*Insert VVIP history*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(
				CustID, CTSCustID, ParentID, CategoryID, LastModifiedDate
			, 	InsertDate, LastModifiedBy, Remark, IsAuto, TargetCC, SourceTypeID
			, 	IsDataChanged, IsMarkedDirectly)
		SELECT 	temp.CustID
			, 	temp.CTSCustID
			,	temp.ParentID
			,	temp.NewCategoryID
			, 	lv_CurrentDateTime AS LastModifiedDate
			,   DATE(lv_CurrentDateTime) AS InsertDate  
			, 	temp.CreatedBy AS LastModifiedBy
			,	temp.Remark
			,	lv_IsAuto AS IsAuto
			,   cat.CustomerClass AS TargetCC
			,   lv_SourceTypeID AS SourceTypeID
			,	1 AS IsDataChanged
			,	lv_IsMarkedDirectly AS IsMarkedDirectly
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = temp.NewCategoryID
		WHERE temp.IsExistVVIP = 0;
		
		/*Insert VVIP log*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(
				CustID, CTSCustID, ParentID, CategoryID ,LastModifiedDate, InsertDate, LastModifiedBy
			, 	IsAuto, TargetCC, SourceTypeID, IsDataChanged, IsMarkedDirectly)
		SELECT 	temp.CustID
			, 	temp.CTSCustID
			,	temp.ParentID
			,	temp.NewCategoryID
			, 	lv_CurrentDateTime AS LastModifiedDate
			,   DATE(lv_CurrentDateTime) AS InsertDate
			, 	temp.CreatedBy AS LastModifiedBy
			,	lv_IsAuto AS IsAuto
			,   cat.CustomerClass AS TargetCC
			,   lv_SourceTypeID AS SourceTypeID
			,	1 AS IsDataChanged
			,	lv_IsMarkedDirectly AS IsMarkedDirectly
		FROM Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = temp.NewCategoryID
		WHERE temp.IsExistVVIP = 0;
		
		IF ip_FromAction = 2 AND ip_QueueID IS NOT NULL THEN
			SELECT MAX(tmpCus.CTSCustID)
			INTO lv_MaxCTSCustID
			FROM Temp_NewClassification AS tmpCus;
		
			UPDATE CTS_DataCenter.CTSCustomerClassificationQueue AS que
			SET que.LastDownlineCTSCustID = lv_MaxCTSCustID
			WHERE que.ID = ip_QueueID;
		END IF;

	ELSEIF ip_InputFlowID = 2 THEN /*SpecialCC*/
		
		SET lv_SourceTypeID = 10;
		SET lv_ActionType 	= 0;
		SET lv_IsAuto 		= 0;
		
		SELECT  ccs.IsParallelParentID, cc.ParentID, cc.CategoryPriority
		INTO lv_IsParallelParentID, lv_ParentID, lv_CategoryPriority
		FROM CTS_DataCenter.CustomerCategorySettings AS ccs
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = ccs.CategoryID
		WHERE ccs.CategoryID = CONST_CATEID_SPECIALCC;
		
		IF lv_IsParallelParentID = 0 THEN
			/*Remove all categories which IsKeepOldCateID = 0*/							
			DELETE cls							
			FROM CTS_DataCenter.CTSCustomerClassification AS cls							
				INNER JOIN Temp_NewClassification AS temp ON cls.CustID = temp.CustID						
			WHERE NOT EXISTS (SELECT 1 
								FROM CTS_DataCenter.CustomerCategorySettings AS cs	
									INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cs.CategoryID
								WHERE cs.CategoryID = cls.CategoryID AND cc.IsActive = 1
									AND cs.CategoryPriority > lv_CategoryPriority 
									AND (cs.ParentID <> lv_ParentID OR (cs.ParentID = lv_ParentID AND cs.IsMultiCateIDSameParentID = 1))
									AND cs.IsKeepOldCateID = 1);	
									
		ELSE
			UPDATE CTS_DataCenter.CTSCustomerClassification AS cls
				INNER JOIN Temp_NewClassification AS temp ON temp.CustID = cls.CustID
				INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cls.CategoryID 
																	AND cc.IsActive = 1 AND cc.RelevantCategoryID IS NOT NULL
																	AND cc.IsPAProbation = 1
			SET 	cls.CategoryID 		= cc.RelevantCategoryID
				,	clss.LastModifiedBy	= temp.CreatedBy
			WHERE 	temp.IsDataChanged 	= 1;
			
		END IF;
		
		/*	INSERT VALID SPECIAL CUSTOMER CLASS	*/
		INSERT INTO CTS_DataCenter.SpecialCustomerClass(
				CTSCustID, CustID, RootCTSCustID, SubscriberID, RoleID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction)
		SELECT 	temp.CTSCustID
			,	temp.CustID
			,	temp.CTSCustID AS RootCTSCustID
			,	temp.SubscriberID
			,	temp.RoleID
			,	temp.TargetCC AS CustomerClass
			,	temp.CreatedBy
			,	lv_CurrentDateTime AS CreatedDate
			,	temp.CreatedBy AS LastModifiedBy
			,	lv_CurrentDateTime AS LastModifiedDate
			,   1 AS CreatedFromFunction -- for Special Customer
		FROM Temp_NewCustomerClass AS temp;
		
		/*	INSERT LOG FOR SPECIAL CUSTOMER CLASS	*/
		INSERT INTO CTS_DataCenter.SpecialCustomerClass_History(
				CTSCustID, CustID, RootCTSCustID, SubscriberID, CustomerClass, CreatedBy
			, 	CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction, Remark, ActionType)
		SELECT 	temp.CTSCustID
			,	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.TargetCC AS CustomerClass
			,	temp.CreatedBy
			,	lv_CurrentDateTime AS CreatedDate
			,	temp.CreatedBy AS LastModifiedBy
			,	lv_CurrentDateTime AS LastModifiedDate
			,   1 AS CreatedFromFunction -- for Special Customer
			,	temp.Remark
			,	lv_ActionType AS ActionType -- insert
		FROM Temp_NewCustomerClass AS temp;
		
		/*	INSERT */
		INSERT INTO CTS_DataCenter.CTSCustomerClassification (
				CustID, CTSCustID, SubscriberID, RoleID, ParentID, CategoryID, CreatedDate, CreatedBy
			, 	LastModifiedDate, LastModifiedBy, LastScannedDate, ActionType, IsAuto, Remark)
		SELECT  temp.CustID
			, 	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.RoleID
			,	CONST_PARENTID_WRAPPER
			,	CONST_CATEID_SPECIALCC
			, 	lv_CurrentDateTime AS CreatedDate
			, 	temp.CreatedBy AS CreatedBy
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			, 	DATE(lv_CurrentDateTime) AS LastScannedDate
			, 	lv_ActionType  AS ActionType 
			, 	lv_IsAuto AS IsAuto
			, 	temp.Remark
		FROM Temp_NewCustomerClass AS temp
		WHERE NOT EXISTS (SELECT 1
							FROM CTS_DataCenter.CTSCustomerClassification AS cls
							WHERE cls.CustID = temp.CustID
								AND cls.CategoryID = CONST_CATEID_SPECIALCC);
		
		/*	INSERT HISTORY	*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History (
				CustID, CTSCustID, ParentID, CategoryID, LastModifiedDate, LastModifiedBy, ActionType
			, 	IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, Remark)
		SELECT  temp.CustID
			, 	temp.CTSCustID
			,	CONST_PARENTID_WRAPPER
			,	CONST_CATEID_SPECIALCC
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			, 	lv_ActionType  AS ActionType 
			, 	lv_IsAuto AS IsAuto
			, 	DATE(lv_CurrentDateTime) AS InsertDate
			,	temp.TargetCC AS TargetCC
			, 	lv_SourceTypeID AS SourceTypeID
			, 	temp.IsDataChanged
			, 	temp.Remark
		FROM Temp_NewCustomerClass AS temp
		WHERE temp.IsDataChanged = 1;
		
		/*	INSERT LOG*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log (
				CustID, CTSCustID, ParentID, CategoryID, LastModifiedDate, LastModifiedBy, ActionType
			, 	IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, Remark)
		SELECT  temp.CustID
			, 	temp.CTSCustID
			,	CONST_PARENTID_WRAPPER
			,	CONST_CATEID_SPECIALCC
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			, 	lv_ActionType AS ActionType 
			, 	lv_IsAuto AS IsAuto
			, 	DATE(lv_CurrentDateTime) AS InsertDate
			,	temp.TargetCC AS TargetCC
			, 	lv_SourceTypeID AS SourceTypeID
			, 	temp.IsDataChanged
			, 	temp.Remark
		FROM Temp_NewCustomerClass AS temp;

	ELSEIF ip_InputFlowID = 3 THEN /*LicVIP*/
		SET lv_SourceTypeID 			= 28;
		SET lv_ActionType 				= 0;
		SET lv_IsAuto 					= 0;
		SET lv_IsMarkedDirectly 		= 1;
		
		SELECT  ccs.IsParallelParentID, cc.ParentID, cc.CategoryPriority
		INTO lv_IsParallelParentID, lv_ParentID, lv_CategoryPriority
		FROM CTS_DataCenter.CustomerCategorySettings AS ccs
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = ccs.CategoryID
		WHERE ccs.CategoryID = CONST_CATEID_LICVIPSUSPICIOUS;
		
		INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, SubscriberID, RoleID, CreatedBy, IsLicenseeVIP, NewCategoryID
			, 	IsDangerProbation, CategoryPriority, CustomerClassPriority, TargetCC ) 
		WITH CTE_LastCategory AS
		(SELECT	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.RoleID
			,	temp.CreatedBy
			,	temp.IsLicenseeVIP
			,	tmpLastCat.CategoryID
			,	tmpLastCat.IsDangerProbation
			,	tmpLastCat.CategoryPriority
			,	tmpLastCat.CustomerClassPriority
			,	tmpLastCat.CustomerClass AS TargetCC
		FROM Temp_Customer AS temp,
		LATERAL (
					SELECT cls.CategoryID, cat.CategoryPriority, cat.CustomerClassPriority, cat.IsDangerProbation, cat.CustomerClass 
					FROM CTS_DataCenter.CTSCustomerClassification AS cls
						LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = cls.CategoryID
																				AND cat.CategoryID <> CONST_CATEID_SPECIALCC
																				AND cat.CategoryPriority < lv_CategoryPriority
					WHERE cls.CustID = temp.CustID
					ORDER BY cls.CustID, cls.LastModifiedDate DESC
					LIMIT 1) AS tmpLastCat) 
		SELECT 	cte.CustID
			,	cte.CTSCustID
			,	cte.SubscriberID
			,	cte.RoleID
			,	cte.CreatedBy
			,	cte.IsLicenseeVIP
			,	cte.CategoryID AS NewCategoryID
			,	cte.IsDangerProbation
			,	cte.CategoryPriority
			,	cte.CustomerClassPriority
			,	cte.TargetCC
		FROM  CTE_LastCategory AS cte; 
	
		INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, SubscriberID, RoleID, CreatedBy, IsLicenseeVIP, NewCategoryID
			, 	IsDangerProbation, CategoryPriority, CustomerClassPriority, TargetCC ) 
		SELECT 	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.RoleID
			,	temp.CreatedBy
			,	temp.IsLicenseeVIP
			,	cc.CategoryID AS NewCategoryID
			,	cc.IsDangerProbation
			,	cc.CategoryPriority
			,	cc.CustomerClassPriority
			,	cc.CustomerClass
		FROM Temp_Customer AS temp
			INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = temp.CustID
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON sc.CustomerClass = cc.CustomerClass;
	
		UPDATE Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = temp.CustID
		SET temp.CategoryPriority = -1
		WHERE temp.CategoryPriority IS NULL;
	
		UPDATE Temp_NewClassification AS temp
		SET 	temp.IsDataChanged 	= 1
			, 	temp.ParentID 		= CONST_PARENTID_WRAPPER
			, 	temp.NewCategoryID 	= (CASE WHEN temp.IsDangerProbation = 1 THEN CONST_CATEID_LICVIPSUSPICIOUS 
											ELSE CONST_CATEID_LICVIPDANGEROUS END) 
			, 	temp.TargetCC 		= (CASE WHEN temp.IsDangerProbation = 1 THEN CONST_CC_LICVIPSUSPICIOUS 
											ELSE CONST_CC_LICVIPDANGEROUS END)
			, 	temp.IsReturnData	= 1
		WHERE temp.IsLicenseeVIP = 0 
			AND ( temp.CategoryPriority IS NULL 
					OR temp.CategoryPriority > lv_CategoryPriority);

		IF lv_IsParallelParentID = 0 THEN
			/*Remove all categories which IsKeepOldCateID = 0*/							
			DELETE cls							
			FROM CTS_DataCenter.CTSCustomerClassification AS cls							
				INNER JOIN Temp_NewClassification AS temp ON cls.CustID = temp.CustID						
			WHERE temp.IsLicenseeVIP = 0							
				AND NOT EXISTS (SELECT 1 
								FROM CTS_DataCenter.CustomerCategorySettings AS cs	
									INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cs.CategoryID
								WHERE cs.CategoryID = cls.CategoryID AND cc.IsActive = 1
									AND cs.CategoryPriority > lv_CategoryPriority 
									AND (cs.ParentID <> lv_ParentID OR (cs.ParentID = lv_ParentID AND cs.IsMultiCateIDSameParentID = 1))
									AND cs.IsKeepOldCateID = 1);
		END IF;

		UPDATE CTS_DataCenter.CTSCustomer AS cus
			INNER JOIN Temp_Customer AS temp ON cus.CTSCustID = temp.CTSCustID
		SET 	cus.IsLicenseeVIP = 1
			, 	cus.ModifiedTime = lv_CurrentDateTime
		WHERE cus.IsLicenseeVIP = 0;   
		
		IF EXISTS (SELECT 1 FROM Temp_NewClassification AS temp) THEN
			INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
				CTSCustID, CustID, SubscriberID, RoleID, ParentID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsMarkedDirectly) 
			SELECT	temp.CTSCustID
				,	temp.CustID
				,	temp.SubscriberID
				,	temp.RoleID
				,	temp.ParentID
				,	temp.NewCategoryID
				,	lv_CurrentDateTime AS CreatedDate
				,	temp.CreatedBy
				,	lv_CurrentDateTime AS LastModifiedDate
				,	temp.CreatedBy AS LastModifiedBy
				,	DATE(lv_CurrentDateTime) LastScannedDate
				,	lv_IsMarkedDirectly AS IsMarkedDirectly
			FROM Temp_NewClassification AS temp;
		
			/*Insert history*/
			INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(
					CustID, CTSCustID, ParentID, CategoryID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, IsMarkedDirectly)
			SELECT 	temp.CustID
				, 	temp.CTSCustID
				,	temp.ParentID
				,	temp.NewCategoryID
				, 	lv_CurrentDateTime AS LastModifiedDate
				, 	temp.CreatedBy AS LastModifiedBy
				,	lv_ActionType AS ActionType
				,	lv_IsAuto AS IsAuto
				,   DATE(lv_CurrentDateTime) AS InsertDate
				,   temp.TargetCC
				,   lv_SourceTypeID AS SourceTypeID
				,	1 AS IsDataChanged
				,	lv_IsMarkedDirectly AS IsMarkedDirectly
			FROM Temp_NewClassification AS temp
			WHERE temp.IsDataChanged = 1;
			
			/*Insert log*/
			INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(
					CustID, CTSCustID, ParentID, CategoryID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, IsMarkedDirectly)
			SELECT 	temp.CustID
				, 	temp.CTSCustID
				,	temp.ParentID
				,	temp.NewCategoryID
				, 	lv_CurrentDateTime AS LastModifiedDate
				, 	temp.CreatedBy AS LastModifiedBy
				,	lv_ActionType AS ActionType
				,	lv_IsAuto AS IsAuto
				,   DATE(lv_CurrentDateTime) AS InsertDate
				,   temp.TargetCC
				,   lv_SourceTypeID AS SourceTypeID
				,	temp.IsDataChanged
				,	lv_IsMarkedDirectly AS IsMarkedDirectly
			FROM Temp_NewClassification AS temp;
			
		ELSE
			INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
					CTSCustID, CustID, SubscriberID, RoleID, ParentID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsMarkedDirectly) 
			SELECT	temp.CTSCustID
				,	temp.CustID
				,	temp.SubscriberID
				,	temp.RoleID
				,	CONST_PARENTID_WRAPPER AS ParentID
				,	CONST_CATEID_LICVIPDANGEROUS AS CategoryID 
				,	lv_CurrentDateTime AS CreatedDate
				,	temp.CreatedBy
				,	lv_CurrentDateTime AS LastModifiedDate
				,	temp.CreatedBy AS LastModifiedBy
				,	DATE(lv_CurrentDateTime) LastScannedDate
				,	lv_IsMarkedDirectly AS IsMarkedDirectly
			FROM Temp_Customer AS temp
				LEFT JOIN Temp_NewClassification AS tmpCat ON tmpCat.CustID = temp.CustID
			WHERE tmpCat.CustID IS NULL;

		END IF;
	
	ELSEIF ip_InputFlowID = 4 THEN /*LicBA*/
		SET lv_SourceTypeID 		= 38;
		SET lv_ActionType 			= 0;
		SET lv_IsAuto 				= 0; 
		SET lv_IsMarkedDirectly 	= 1;
	
		SELECT  ccs.IsParallelParentID, cc.ParentID, cc.CategoryPriority
		INTO lv_IsParallelParentID, lv_ParentID, lv_CategoryPriority
		FROM CTS_DataCenter.CustomerCategorySettings AS ccs
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = ccs.CategoryID
		WHERE ccs.CategoryID = CONST_CATEID_LICBA;
	
		INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, SubscriberID, RoleID, CreatedBy, IsLicenseeBA, ParentID, NewCategoryID
			, 	CategoryPriority, CustomerClassPriority, TargetCC, IsReturnData ) 
		WITH CTE_LastCategory AS
		(
		 SELECT	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.RoleID
			,	temp.CreatedBy
			,	temp.IsLicenseeBA
			,	tmpLastCat.ParentID
			,	tmpLastCat.CategoryID
			,	tmpLastCat.CategoryPriority
			,	tmpLastCat.CustomerClassPriority
			,	tmpLastCat.CustomerClass AS TargetCC
		 FROM Temp_Customer AS temp,
		 LATERAL (
					SELECT cls.ParentID, cls.CategoryID, cat.CategoryPriority, cat.CustomerClassPriority, cat.CustomerClass 
					FROM CTS_DataCenter.CTSCustomerClassification AS cls
						LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = cls.CategoryID 
																			AND cat.CategoryID <> CONST_CATEID_SPECIALCC
																			AND cat.CategoryPriority < lv_CategoryPriority
					WHERE cls.CustID = temp.CustID
					ORDER BY cls.CustID, cls.LastModifiedDate DESC
					LIMIT 1
				  ) AS tmpLastCat
		) 
		SELECT cte.CustID
		,	cte.CTSCustID
		,	cte.SubscriberID
		,	cte.RoleID
		,	cte.CreatedBy
		,	cte.IsLicenseeBA
		,	cte.ParentID
		,	cte.CategoryID AS NewCategoryID
		,	cte.CategoryPriority
		,	cte.CustomerClassPriority
		,	cte.TargetCC
		,	1 AS IsReturnData
		FROM  CTE_LastCategory AS cte;  
		
		INSERT INTO Temp_NewClassification(
				CustID, CTSCustID, SubscriberID, RoleID, CreatedBy, IsLicenseeVIP, NewCategoryID
			, 	IsDangerProbation, CategoryPriority, CustomerClassPriority, TargetCC ) 
		SELECT 	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.RoleID
			,	temp.CreatedBy
			,	temp.IsLicenseeVIP
			,	cc.CategoryID AS NewCategoryID
			,	cc.IsDangerProbation
			,	cc.CategoryPriority
			,	cc.CustomerClassPriority
			,	cc.CustomerClass
		FROM Temp_Customer AS temp
			INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = temp.CustID
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON sc.CustomerClass = cc.CustomerClass;

		UPDATE Temp_NewClassification AS temp
			INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = temp.CustID
		SET temp.CategoryPriority = -1
		WHERE temp.CategoryPriority IS NULL;
		
		UPDATE Temp_NewClassification AS temp
		SET 	temp.IsDataChanged 		= 1
			, 	temp.ParentID 			= CONST_PARENTID_WRAPPER
			, 	temp.NewCategoryID		= CONST_CATEID_LICBA
			, 	temp.TargetCC 			= CONST_CC_LICBA
			, 	temp.IsReturnData		= 1
		WHERE temp.IsLicenseeBA = 0
			AND ( temp.CategoryPriority IS NULL OR temp.CategoryPriority > lv_CategoryPriority); 
		
		IF lv_IsParallelParentID = 0 THEN
			/*Remove all categories which IsKeepOldCateID = 0*/							
			DELETE cls							
			FROM CTS_DataCenter.CTSCustomerClassification AS cls							
				INNER JOIN Temp_NewClassification AS temp ON cls.CustID = temp.CustID						
			WHERE temp.IsLicenseeVIP = 0							
				AND NOT EXISTS (SELECT 1 
								FROM CTS_DataCenter.CustomerCategorySettings AS cs	
									INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cs.CategoryID
								WHERE cs.CategoryID = cls.CategoryID AND cc.IsActive = 1
									AND cs.CategoryPriority > lv_CategoryPriority 
									AND (cs.ParentID <> lv_ParentID OR (cs.ParentID = lv_ParentID AND cs.IsMultiCateIDSameParentID = 1))
									AND cs.IsKeepOldCateID = 1);
		END IF;
		
		UPDATE CTS_DataCenter.CTSCustomer AS cus
			INNER JOIN Temp_Customer AS temp ON cus.CTSCustID = temp.CTSCustID
		SET 	cus.IsLicenseeBA = 1
			, 	cus.ModifiedTime = lv_CurrentDateTime
		WHERE cus.IsLicenseeBA = 0; 

		IF EXISTS (SELECT 1 FROM Temp_NewClassification AS temp) THEN		
			INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
				CTSCustID, CustID, SubscriberID, RoleID, ParentID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate) 
			SELECT	temp.CTSCustID
				,	temp.CustID
				,	temp.SubscriberID
				,	temp.RoleID
				,	temp.ParentID
				,	temp.NewCategoryID 
				,	lv_CurrentDateTime AS CreatedDate
				,	temp.CreatedBy
				,	lv_CurrentDateTime AS LastModifiedDate
				,	temp.CreatedBy AS LastModifiedBy
				,	DATE(lv_CurrentDateTime) LastScannedDate
				,	lv_IsMarkedDirectly AS IsMarkedDirectly
			FROM Temp_NewClassification AS temp;
		
			/*Insert history*/
			INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(
					CustID, CTSCustID, ParentID, CategoryID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
			SELECT 	temp.CustID
				, 	temp.CTSCustID
				,	temp.ParentID
				,	temp.NewCategoryID 
				, 	lv_CurrentDateTime AS LastModifiedDate
				, 	temp.CreatedBy AS LastModifiedBy
				,	lv_ActionType  AS ActionType
				,	lv_IsAuto  AS IsAuto
				,   DATE(lv_CurrentDateTime) AS InsertDate
				,   temp.TargetCC
				,   lv_SourceTypeID AS SourceTypeID
				,	1 AS IsDataChanged
				,	lv_IsMarkedDirectly AS IsMarkedDirectly
			FROM Temp_NewClassification AS temp
			WHERE temp.IsDataChanged = 1;
			
			/*Insert log*/
			INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(
					CustID, CTSCustID, ParentID, CategoryID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
			SELECT 	temp.CustID
				, 	temp.CTSCustID
				,	temp.ParentID
				,	temp.NewCategoryID 
				, 	lv_CurrentDateTime AS LastModifiedDate
				, 	temp.CreatedBy AS LastModifiedBy
				,	lv_ActionType  AS ActionType
				,	lv_IsAuto  AS IsAuto
				,   DATE(lv_CurrentDateTime) AS InsertDate
				,   temp.TargetCC
				,   lv_SourceTypeID AS SourceTypeID
				,	temp.IsDataChanged
				,	lv_IsMarkedDirectly AS IsMarkedDirectly
			FROM Temp_NewClassification AS temp;
			
		ELSE
			INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
					CTSCustID, CustID, SubscriberID, RoleID, ParentID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsMarkedDirectly) 
			SELECT	temp.CTSCustID
				,	temp.CustID
				,	temp.SubscriberID
				,	temp.RoleID
				,	CONST_PARENTID_WRAPPER AS ParentID
				,	CONST_CATEID_LICBA AS CategoryID 
				,	lv_CurrentDateTime AS CreatedDate
				,	temp.CreatedBy
				,	lv_CurrentDateTime AS LastModifiedDate
				,	temp.CreatedBy AS LastModifiedBy
				,	DATE(lv_CurrentDateTime) LastScannedDate
				,	lv_IsMarkedDirectly AS IsMarkedDirectly
			FROM Temp_Customer AS temp
				LEFT JOIN Temp_NewClassification AS tmpCat ON tmpCat.CustID = temp.CustID
			WHERE tmpCat.CustID IS NULL;
		
		END IF;
		
	ELSE
		/*STEP 2: Preprocess*/
		CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_PreProcess (ip_InputFlowID);
		
		
		/*STEP 3: Process*/
		CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_Process (ip_InputFlowID);
		
		
		/*STEP 4: Complete*/
		CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_Complete (ip_InputFlowID);
	
	END IF;

	/*STEP 5: User Log*/
	IF ip_FromAction = 1 THEN /*VVIP*/
		SET lv_LogTypeID = 10;
		
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT  lv_LogTypeID
			, 	lv_SPName
			, 	CONCAT('Insert VVIP: CTSCustID_', temp.CTSCustID,'; CustID_', temp.CustID,'; RoleID_', temp.RoleID, '; AffectDownline_', ip_AffectDownline,'; SubscriberID_', temp.SubscriberID, '; CategoryID_', temp.NewCategoryID, '; Remark_', temp.Remark)
            ,	lv_CurrentDateTime AS CreatedDate
            , 	temp.CreatedBy
        FROM Temp_NewClassification AS temp;
	
	ELSEIF ip_InputFlowID = 2 THEN /*Special*/
		SET lv_LogTypeID = 19;
		
		SELECT CreatedBy
		INTO lv_CreatedBy
		FROM Temp_NewClassification
		LIMIT 1;
	
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT	lv_LogTypeID
			,	lv_SPName
			,	CONCAT('Insert SpecialCustomerClass: CTSCustList: ', GROUP_CONCAT(CTSCustID),';CustIDList: ', GROUP_CONCAT(CustID), ';CustomerClass: ', GROUP_CONCAT(DISTINCT TargetCC)) AS LogInfo
			,	lv_CurrentDateTime AS CreatedDate
			,	lv_CreatedBy
		FROM Temp_NewClassification;

	END IF;
	
	/*STEP 6: AffectedDownline*/
	IF (ip_IsToQueue = 1 OR (ip_FromAction = 2 AND ip_AffectDownline = 1)) THEN
		CALL CTS_DC_CustClassification_AffectedDownline_Insert ('Temp_NewClassification',ip_InputFlowID);
	END IF;

	
	/*STEP N: Return data*/
	SELECT DISTINCT 
			CTSCustID
		,  	CustID
		,	TargetCC AS CustomerClass
		,  	NewCategoryID AS CategoryID /*-1 AS Category; SpecialCC4x*/
		,	lv_CurrentDateTime AS ScannedTime 
	FROM Temp_NewClassification AS temp
	WHERE temp.IsReturnData = 1;
	
END$$
DELIMITER ;