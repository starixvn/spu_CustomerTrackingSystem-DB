/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Remove`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_FromAction			TINYINT
	,	IN	ip_UplineRoleID			INT
	,	IN	ip_QueueID				BIGINT
	,	IN	ip_AffectDownline		TINYINT(1)
	,	IN	ip_IsFromQueue			TINYINT(1)
	,	IN	ip_CustInfo				JSON
	,	OUT op_ErrorMessage 		VARCHAR(200)
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Remove main customer categories for Customer Classification
		DB:			CTS_DataCenter
		
		Revisions: 
			-	20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
		Param's Expanation:
		
		Example:
			- CALL CTS_DC_CustClassification_Remove(8, 0, 0, 0, false, false, '[{"CustID":1275,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":1280,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5002646,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5022391,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0}]', @outParam7);
*/
	DECLARE CONST_PARENTID_VVIP 						INT;
	DECLARE CONST_PARENTID_WRAPPER 						INT;
	DECLARE CONST_PARENTID_PA	 						INT;
	DECLARE CONST_CATEID_SPECIALCC 						INT;
	DECLARE CONST_CATEID_LICVIPDANGEROUS 				INT;
	DECLARE CONST_CATEID_LICVIPSUSPICIOUS 				INT;
	DECLARE CONST_CATEID_LICBA			 				INT;
	
	DECLARE CONST_ACTIONTYPE_REMOVE 					INT DEFAULT 2;

	DECLARE lv_SourceTypeID								INT;
	DECLARE lv_MaxCTSCustID								BIGINT UNSIGNED;
	
	DECLARE lv_CurrentDateTime 							DATETIME DEFAULT CURRENT_TIME();
	DECLARE lv_IsAuto									INT;
	DECLARE lv_ActionType								INT;
	DECLARE lv_IsDataChanged							INT;
	DECLARE lv_TargetCC									INT;
	DECLARE lv_LogTypeID								INT;
	DECLARE lv_CreatedBy								INT;
	DECLARE lv_IsExceptDirectDownline					TINYINT(1);
	DECLARE lv_CategoryPriority							SMALLINT UNSIGNED;  
	DECLARE lv_SPName 									VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_Remove';
	DECLARE lv_LogInfo 									VARCHAR(500);
	
	SET CONST_PARENTID_VVIP 							= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_VVIP');
	SET CONST_PARENTID_WRAPPER 							= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_PARENTID_PA	 							= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
	SET CONST_CATEID_SPECIALCC							= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_SPECIALCC');
	SET CONST_CATEID_LICVIPDANGEROUS					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPDANGEROUS');
	SET CONST_CATEID_LICVIPSUSPICIOUS					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICVIPSUSPICIOUS');
	SET CONST_CATEID_LICBA								= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_LICBA');
	
	/*STEP 1: Parse raw data and get custinfo*/
	CALL CTS_DataCenter.CTS_DC_CustClassification_Remove_GetInfo (ip_InputFlowID,ip_CustInfo);
	
	IF ip_InputFlowID = 221 THEN /*VVIP*/
		SET lv_ActionType 			= CONST_ACTIONTYPE_REMOVE;
		SET lv_IsAuto 				= 0;
		SET lv_TargetCC				= -1;
		SET lv_IsDataChanged		= 1;
		
		SET lv_SourceTypeID = 	CASE 	WHEN ip_FromAction = 1 THEN 14
										WHEN ip_FromAction = 2 AND ip_UplineRoleID = 4 THEN 27
										WHEN ip_FromAction = 2 AND ip_UplineRoleID = 3 THEN 28
										WHEN ip_FromAction = 2 AND ip_UplineRoleID = 2 THEN 29
								END;
								
		DELETE cls
		FROM CTS_DataCenter.CTSCustomerClassification AS cls
			INNER JOIN Temp_CustomerClassification AS temp ON temp.CustID = cls.CustID
																	AND temp.CategoryID = cls.CategoryID
																	AND temp.IsExistVVIP = 1;
		
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(
				CustID, CTSCustID, CategoryID, ParentID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto
			, 	InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT 	temp.CustID
			, 	temp.CTSCustID
			,   temp.CategoryID
			,   CONST_PARENTID_VVIP AS ParentID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			,   lv_ActionType AS ActionType
			,   lv_IsAuto AS IsAuto
			,   DATE(lv_CurrentDateTime) AS InsertDate
			,   lv_TargetCC AS TargetCC
			,   lv_SourceTypeID AS SourceTypeID
			,	lv_IsDataChanged AS IsDataChanged
		FROM Temp_CustomerClassification AS temp
		WHERE temp.IsExistVVIP = 1;
		
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(
				CustID, CTSCustID, CategoryID, ParentID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto
			, 	InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT 	temp.CustID
			, 	temp.CTSCustID
			,   temp.CategoryID
			,   CONST_PARENTID_VVIP AS ParentID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			,   lv_ActionType AS ActionType
			,   lv_IsAuto AS IsAuto
			,   DATE(lv_CurrentDateTime) AS InsertDate
			,   lv_TargetCC AS TargetCC
			,   lv_SourceTypeID AS SourceTypeID
			,	lv_IsDataChanged AS IsDataChanged
		FROM Temp_CustomerClassification AS temp
		WHERE temp.IsExistVVIP = 1;	

		IF ip_FromAction = 2 AND ip_QueueID IS NOT NULL THEN
			SELECT MAX(temp.CTSCustID)
			INTO lv_MaxCTSCustID
			FROM Temp_CustomerClassification AS temp;
		
			UPDATE CTS_DataCenter.CTSCustomerClassificationQueue AS que
			SET que.LastDownlineCTSCustID = lv_MaxCTSCustID
			WHERE que.ID = ip_QueueID;
		END IF;
	
	ELSEIF ip_InputFlowID = 222 THEN /*SpecialCC*/
		SET lv_ActionType 			= CONST_ACTIONTYPE_REMOVE;
		SET lv_IsAuto 				= 0;
		SET lv_TargetCC				= -1;
		SET lv_IsDataChanged		= 1;
		SET lv_SourceTypeID			= 12;
	
		DELETE s
		FROM CTS_DataCenter.SpecialCustomerClass AS s
			INNER JOIN Temp_CustomerClassification AS temp ON temp.CTSCustID = s.CTSCustID
		WHERE s.CreatedFromFunction = 1;
		
		INSERT INTO CTS_DataCenter.SpecialCustomerClass_History(
				CTSCustID, CustID, RootCTSCustID, SubscriberID, CustomerClass, CreatedBy
			, 	CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction, Remark
			, 	ActionType)
		SELECT 	temp.CTSCustID
			,	temp.CustID
			,	temp.CTSCustID AS RootCTSCustID
			,	temp.SubscriberID
			,	lv_TargetCC AS CustomerClass
			,	temp.CreatedBy
			,	lv_CurrentDateTime AS CreatedDate
			,	temp.CreatedBy AS LastModifiedBy
			,	lv_CurrentDateTime AS LastModifiedDate
			,   1 AS CreatedFromFunction
			,	temp.Remark
			,	lv_ActionType AS ActionType
		FROM Temp_CustomerClassification AS temp;
		
		DELETE cls
		FROM CTS_DataCenter.CTSCustomerClassification AS cls
			INNER JOIN Temp_CustomerClassification AS temp ON temp.CustID = cls.CustID
																AND cls.CategoryID = CONST_CATEID_SPECIALCC;
		
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(
				CustID, CTSCustID, ParentID, CategoryID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto
			, 	InsertDate, TargetCC, SourceTypeID, IsDataChanged, Remark)
		SELECT  temp.CustID
			,   temp.CTSCustID
			,   CONST_PARENTID_WRAPPER AS ParentID
			,   CONST_CATEID_SPECIALCC AS CategoryID
			,   lv_CurrentDateTime AS LastModifiedDate
			,   temp.CreatedBy
			,   lv_ActionType
			,   lv_IsAuto
			,   DATE(lv_CurrentDateTime) AS InsertDate
			,   lv_TargetCC 
			,   lv_SourceTypeID
			,   lv_IsDataChanged
			,	temp.Remark
		FROM Temp_CustomerClassification AS temp;
		
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(
				CustID, CTSCustID, ParentID, CategoryID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto
			, 	InsertDate, TargetCC, SourceTypeID, IsDataChanged, Remark)
		SELECT  temp.CustID
			,   temp.CTSCustID
			,   CONST_PARENTID_WRAPPER AS ParentID
			,   CONST_CATEID_SPECIALCC AS CategoryID
			,   lv_CurrentDateTime AS LastModifiedDate
			,   temp.CreatedBy
			,   lv_ActionType
			,   lv_IsAuto
			,   DATE(lv_CurrentDateTime) AS InsertDate
			,   lv_TargetCC 
			,   lv_SourceTypeID
			,   lv_IsDataChanged
			,	temp.Remark
		FROM Temp_CustomerClassification AS temp;	
		
	ELSEIF ip_InputFlowID = 223 THEN /*LicVIP*/
		SET lv_ActionType 			= CONST_ACTIONTYPE_REMOVE;
		SET lv_IsAuto 				= 0;
		SET lv_IsDataChanged		= 0;
		SET lv_SourceTypeID			= 38;
		
		SELECT  cc.CategoryPriority
		INTO lv_CategoryPriority
		FROM CTS_DataCenter.CustomerCategory AS cc
		WHERE cc.CategoryID = CONST_CATEID_LICVIPSUSPICIOUS;
		
		INSERT INTO Temp_CustomerClassification (
				CustID, CTSCustID, SubscriberID, CreatedBy, IsLicenseeVIP
			, 	CategoryID, IsDangerProbation, CategoryPriority, CustomerClass)
		WITH CTE_LastCategory AS (
		SELECT 	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.CreatedBy
			,	temp.IsLicenseeVIP
			,	tmpLastCat.CategoryID
			,	tmpLastCat.CategoryPriority
			,	tmpLastCat.IsDangerProbation
			,	tmpLastCat.CustomerClass
		FROM Temp_Customer AS temp,
			LATERAL (
						SELECT cls.CategoryID, cc.CategoryPriority, cc.IsDangerProbation, cc.CustomerClass 
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
							LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cls.CategoryID
																				AND cc.CategoryID <> CONST_CATEID_SPECIALCC
																				AND cc.CategoryPriority < lv_CategoryPriority
						WHERE cls.CustID = temp.CustID
						ORDER BY cls.CustID, cls.LastModifiedDate DESC
						LIMIT 1) AS tmpLastCat)
		SELECT 	cte.CustID
			,	cte.CTSCustID
			,	cte.SubscriberID
			,	cte.CreatedBy
			,	cte.IsLicenseeVIP
			,	cte.CategoryID
			,	cte.IsDangerProbation
			,	cte.CategoryPriority
			,	cte.CustomerClass
		FROM CTE_LastCategory AS cte;  

		INSERT IGNORE INTO Temp_CustomerClassification (
				CustID, CTSCustID, SubscriberID, CreatedBy, IsLicenseeVIP
			, 	CategoryID, IsDangerProbation, CategoryPriority, CustomerClass)
		SELECT 	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.CreatedBy
			,	temp.IsLicenseeVIP
			,	cc.CategoryID
			,	cc.IsDangerProbation
			,	cc.CategoryPriority
			,	cc.CustomerClass
		FROM Temp_Customer AS temp
			INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = temp.CustID
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON sc.CustomerClass = cc.CustomerClass;
		
		UPDATE Temp_CustomerClassification AS temp
			INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = temp.CustID
		SET temp.CategoryPriority = -1
		WHERE temp.CategoryPriority IS NULL;
		
		UPDATE Temp_CustomerClassification AS temp
		SET temp.IsReturnData = 1
		WHERE temp.CategoryPriority > lv_CategoryPriority 
			OR temp.CategoryPriority IS NULL;
		
		UPDATE CTS_DataCenter.CTSCustomer AS cus
			INNER JOIN Temp_Customer AS temp ON cus.CTSCustID = temp.CTSCustID
		SET 	cus.IsLicenseeVIP = 0
			, 	cus.ModifiedTime = lv_CurrentDateTime
		WHERE cus.IsLicenseeVIP <> 0;
		
		DELETE del
		FROM CTS_DataCenter.CTSCustomerClassification AS del
			INNER JOIN Temp_CustomerClassification AS temp ON del.CustID = temp.CustID
		WHERE del.CategoryID IN (CONST_CATEID_LICVIPDANGEROUS,CONST_CATEID_LICVIPSUSPICIOUS);
		
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(
				CustID, CTSCustID, CategoryID, ParentID ,LastModifiedDate, LastModifiedBy, ActionType
			, 	IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, IsMarkedDirectly)
		SELECT 	temp.CustID
			, 	temp.CTSCustID
			, 	(CASE WHEN temp.IsDangerProbation = 1 THEN CONST_CATEID_LICVIPSUSPICIOUS 
					  ELSE CONST_CATEID_LICVIPDANGEROUS END) AS CategoryID
			, 	CONST_PARENTID_WRAPPER AS ParentID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			,	lv_ActionType
			,	lv_IsAuto
			,   DATE(lv_CurrentDateTime) AS InsertDate
			,   temp.CustomerClass AS TargetCC
			,   lv_SourceTypeID AS SourceTypeID
			,	lv_IsDataChanged AS IsDataChanged
			,	1 AS IsMarkedDirectly
		FROM Temp_CustomerClassification AS temp;
		
	ELSEIF ip_InputFlowID = 224 THEN /*LicBA*/
		SET lv_ActionType 			= CONST_ACTIONTYPE_REMOVE;
		SET lv_IsAuto 				= 0;
		SET lv_IsDataChanged		= 0;
		SET lv_SourceTypeID			= 38;
		
		SELECT cc.CategoryPriority
		INTO lv_CategoryPriority
		FROM CTS_DataCenter.CustomerCategory AS cc
		WHERE cc.CategoryID = CONST_CATEID_LICBA;

		INSERT INTO Temp_CustomerClassification (
				CustID, CTSCustID, SubscriberID, CreatedBy, IsLicenseeVIP
			, 	CategoryID, IsDangerProbation, CategoryPriority, CustomerClass)
		WITH CTE_LastCategory AS (
		SELECT 	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.CreatedBy
			,	temp.IsLicenseeVIP
			,	tmpLastCat.CategoryID
			,	tmpLastCat.CategoryPriority
			,	tmpLastCat.IsDangerProbation
			,	tmpLastCat.CustomerClass
		FROM Temp_Customer AS temp,
			LATERAL (
						SELECT cls.CategoryID, cc.CategoryPriority, cc.IsDangerProbation, cc.CustomerClass 
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
							LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cls.CategoryID
																				AND cc.CategoryID <> CONST_CATEID_SPECIALCC
																				AND cc.CategoryPriority < lv_CategoryPriority
						WHERE cls.CustID = temp.CustID
						ORDER BY cls.CustID, cls.LastModifiedDate DESC
						LIMIT 1) AS tmpLastCat)
		SELECT 	cte.CustID
			,	cte.CTSCustID
			,	cte.SubscriberID
			,	cte.CreatedBy
			,	cte.IsLicenseeVIP
			,	cte.CategoryID
			,	cte.IsDangerProbation
			,	cte.CategoryPriority
			,	cte.CustomerClass
		FROM CTE_LastCategory AS cte;  
		
		INSERT IGNORE INTO Temp_CustomerClassification (
				CustID, CTSCustID, SubscriberID, CreatedBy, IsLicenseeVIP
			, 	CategoryID, IsDangerProbation, CategoryPriority, CustomerClass)
		SELECT 	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.CreatedBy
			,	temp.IsLicenseeVIP
			,	cc.CategoryID
			,	cc.IsDangerProbation
			,	cc.CategoryPriority
			,	cc.CustomerClass
		FROM Temp_Customer AS temp
			INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = temp.CustID
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON sc.CustomerClass = cc.CustomerClass;
		
		UPDATE Temp_CustomerClassification AS temp
			INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc ON sc.CustID = temp.CustID
		SET temp.CategoryPriority = -1
		WHERE temp.CategoryPriority IS NULL;
		
		UPDATE Temp_CustomerClassification AS temp
		SET temp.IsReturnData = 1
		WHERE temp.CategoryPriority > lv_CategoryPriority 
			OR temp.CategoryPriority IS NULL;
		
		UPDATE CTS_DataCenter.CTSCustomer AS cus
			INNER JOIN Temp_Customer AS temp ON cus.CTSCustID = temp.CTSCustID
		SET 	cus.IsLicenseeBA = 0
			, 	cus.ModifiedTime = lv_CurrentDateTime
		WHERE cus.IsLicenseeBA <> 0;
		
		DELETE del
		FROM CTS_DataCenter.CTSCustomerClassification AS del
			INNER JOIN Temp_CustomerClassification AS temp ON del.CustID = temp.CustID
		WHERE del.CategoryID = CONST_CATEID_LICBA;
		
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(
				CustID, CTSCustID, CategoryID, ParentID ,LastModifiedDate, LastModifiedBy, ActionType
			, 	IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, IsMarkedDirectly)
		SELECT 	temp.CustID
			, 	temp.CTSCustID
			, 	CONST_CATEID_LICBA AS CategoryID
			, 	CONST_PARENTID_WRAPPER AS ParentID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			,	lv_ActionType
			,	lv_IsAuto
			,   DATE(lv_CurrentDateTime) AS InsertDate
			,   temp.CustomerClass AS TargetCC
			,   lv_SourceTypeID AS SourceTypeID
			,	lv_IsDataChanged AS IsDataChanged
			,	1 AS IsMarkedDirectly
		FROM Temp_CustomerClassification AS temp;
	
	ELSEIF ip_InputFlowID = 225 THEN /*PA*/
		SET lv_ActionType 			= 4; /*4: UnMark PA, 3: Mark PA*/
		SET lv_IsAuto 				= 0;
		SET lv_IsDataChanged		= 0;
		SET lv_SourceTypeID			= 38;
	
		INSERT IGNORE INTO Temp_CustomerClassification (
				CustID, CTSCustID, SubscriberID, RoleID, CreatedBy, Remark, IsMarkedDirectly
			, 	CategoryID, Ext_EvidenceID_Licensee, Ext_EvidenceID_Credit, IsRemovedPA
			,	IsExistRobot, IsFromTW, IsFromTVS, IsFromAI, IsFromCTS, IsReturnData)
		SELECT 	temp.CustID
			,	temp.CTSCustID
			,	temp.SubscriberID
			,	temp.RoleID
			,	temp.CreatedBy
			,	temp.Remark
			,	temp.IsMarkedDirectly
			,	cls.CategoryID
			,	cc.Ext_EvidenceID_Licensee
			,	cc.Ext_EvidenceID_Credit
			,	(CASE WHEN (IsExceptDirectDownline = 1 AND IsMarkedDirectly = 1 AND ip_IsFromQueue = 1) THEN 0 
					  ELSE 1 END) AS IsRemovedPA
			,	IsCheckExistRobot.IsExistRobot
			,	IsCheckSourceTW.IsFromTW
			,	IsCheckSourceTVS.IsFromTVS
			,	IsCheckSourceAI.IsFromAI
			,	IsCheckSourceCTS.IsFromCTS
			,	1 AS IsReturnData
		FROM Temp_Customer AS temp
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON temp.CustID = cls.CustID 
																			AND cls.ParentID = CONST_PARENTID_PA
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cls.CategoryID = cc.CategoryID AND cc.IsActive = 1
			, LATERAL (
						SELECT 1 AS IsExistRobot
						FROM CTS_DataCenter.CTSCustomerClassification AS clsR 
							INNER JOIN CTS_DataCenter.CustomerCategory AS ccR ON cls.CategoryID = cc.CategoryID 
																					AND ccR.CustomerClassName = 'Robot'
																					AND cc.IsActive = 1
						WHERE clsR.CustID = temp.CustID
						LIMIT 1
					  ) AS IsCheckExistRobot
			, LATERAL (
						SELECT clsR.IsFromTW
						FROM CTS_DataCenter.CTSCustomerClassification AS clsR 
							INNER JOIN CTS_DataCenter.CustomerCategory AS ccR ON cls.CategoryID = cc.CategoryID
																					AND cc.IsActive = 1
						WHERE clsR.CustID = temp.CustID AND clsR.IsFromTW = 1
						LIMIT 1
					  ) AS IsCheckSourceTW
			, LATERAL (
						SELECT clsR.IsFromTVS
						FROM CTS_DataCenter.CTSCustomerClassification AS clsR 
							INNER JOIN CTS_DataCenter.CustomerCategory AS ccR ON cls.CategoryID = cc.CategoryID
																					AND cc.IsActive = 1
						WHERE clsR.CustID = temp.CustID AND clsR.IsFromTVS = 1
						LIMIT 1
					  ) AS IsCheckSourceTVS
			, LATERAL (
						SELECT clsR.IsFromAI
						FROM CTS_DataCenter.CTSCustomerClassification AS clsR 
							INNER JOIN CTS_DataCenter.CustomerCategory AS ccR ON cls.CategoryID = cc.CategoryID
																					AND cc.IsActive = 1
						WHERE clsR.CustID = temp.CustID AND clsR.IsFromAI = 1
						LIMIT 1
					  ) AS IsCheckSourceAI
			, LATERAL (
						SELECT clsR.IsFromCTS
						FROM CTS_DataCenter.CTSCustomerClassification AS clsR 
							INNER JOIN CTS_DataCenter.CustomerCategory AS ccR ON cls.CategoryID = cc.CategoryID
																					AND cc.IsActive = 1
						WHERE clsR.CustID = temp.CustID AND clsR.IsFromCTS = 1
						LIMIT 1
					  ) AS IsCheckSourceCTS
			; 
		
		INSERT INTO Temp_KeepDirect
		SELECT DISTINCT temp.CustID
		FROM Temp_CustomerClassification AS temp 
		WHERE temp.IsRemovedPA = 0;
		
		UPDATE Temp_CustomerClassification AS temp
			INNER JOIN Temp_KeepDirect AS tmpKd ON temp.CustID = tmpKd.CustID
		SET temp.IsCleanPA = 0;
		
		INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueRemove(CTSCustID, EvidenceID, Created)
		SELECT	temp.CTSCustID
			,	ce.EvidenceID
			,	lv_CurrentDateTime AS Created
		FROM CTS_DataCenter.CustEvidence AS ce
			INNER JOIN Temp_CustomerClassification AS temp ON ce.CTSCustID = temp.CTSCustID AND ce.Level = 0 
																AND ce.EvidenceID IN (temp.Ext_EvidenceID_Licensee, temp.Ext_EvidenceID_Credit)
		WHERE temp.IsRemovedPA = 1; 
		
		DELETE ce
		FROM CTS_DataCenter.CustEvidence AS ce
			INNER JOIN Temp_CustomerClassification AS temp ON ce.CTSCustID = temp.CTSCustID 
																AND ce.Level = 0
																AND ce.EvidenceID IN (temp.Ext_EvidenceID_Licensee, temp.Ext_EvidenceID_Credit)					
		WHERE temp.IsRemovedPA = 1;
		
		IF(ip_IsFromQueue = 0) THEN
			INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationQueue(
					CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, LastDownlineCTSCustID, ActionType
				, 	InsertTime, IsExceptDirectDownline)
			SELECT 	temp.CTSCustID
				,	temp.CustID
				,	temp.RoleID
				,	temp.SubscriberID
				,	temp.CreatedBy
				,	temp.Remark    
				,	0 AS LastDownlineCTSCustID
				,	lv_ActionType AS ActionType
				,	lv_CurrentDateTime AS InsertTime
				, 	temp.IsExceptDirectDownline
			FROM Temp_Customer AS temp
			WHERE temp.RoleID > 1;    

		END IF;
		
		UPDATE CTS_DataCenter.RobotDetection AS rd
			INNER JOIN Temp_CustomerClassification AS temp ON rd.CustID = temp.CustID
																AND temp.IsExistRobot = 1 AND temp.IsFromAI = 1
		SET rd.IsDisabled = 1
		WHERE NOT EXISTS (SELECT 1 FROM Temp_KeepDirect AS tmpKD WHERE temp.CustID = tmpKD.CustID);
		
		-- ROBOT TW
		UPDATE CTS_DataCenter.TWRobotUser AS rd
			INNER JOIN Temp_CustomerClassification AS temp ON rd.CustID = temp.CustID 
																AND temp.IsExistRobot = 1 AND temp.IsFromTW = 1
		SET rd.IsDisabled = 1
		WHERE NOT EXISTS (SELECT 1 FROM Temp_KeepDirect AS tmpKD WHERE temp.CustID = tmpKD.CustID);
		
		-- ROBOT CTS
		UPDATE CTS_DataCenter.CTSRobotUser AS rd
			INNER JOIN Temp_CustomerClassification AS temp ON rd.CustID = temp.CustID 
																AND temp.IsExistRobot = 1 AND temp.IsFromCTS = 1
		SET rd.IsDisabled = 1
		WHERE NOT EXISTS (SELECT 1 FROM Temp_KeepDirect AS tmpKD WHERE temp.CustID = tmpKD.CustID);
		
		-- PA/ROBOT TVS <ADD INSERT PA - SOURCETYPEID>
		UPDATE CTS_DataCenter.TVSVoidRequest AS rd
			INNER JOIN Temp_CustomerClassification AS temp ON rd.CustID = temp.CustID 
																AND temp.IsFromTVS = 1
		SET rd.IsDisabled = 1
		WHERE NOT EXISTS (SELECT 1 FROM Temp_KeepDirect AS tmpKD WHERE temp.CustID = tmpKD.CustID);
		
		-- DELETE PA 305/3005
		DELETE cld
		FROM CTS_DataCenter.CustomerLoginInfoDetection AS cld
			INNER JOIN Temp_CustomerClassification AS temp ON cld.CustID = temp.CustID
																AND cls.CategoryID = temp.CategoryID
																AND temp.IsFromCTS = 1
		WHERE NOT EXISTS (SELECT 1 FROM Temp_KeepDirect AS tmpKD WHERE temp.CustID = tmpKD.CustID);
		
		DELETE cls
		FROM CTS_DataCenter.CTSCustomerClassification AS cls
			INNER JOIN Temp_CustomerClassification AS temp ON cls.CustID = temp.CustID
																AND cls.CategoryID = temp.CategoryID
																AND temp.IsFromCTS = 1
		WHERE temp.IsRemovedPA = 1;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(
				CustID, CTSCustID, CategoryID, ParentID, LastModifiedDate, LastModifiedBy, ActionType
			, 	InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM
			, 	BetCount, ActiveDays, IsMarkedDirectly, Remark)
		SELECT DISTINCT 
				temp.CustID
			, 	temp.CTSCustID
			, 	NULL AS CategoryID
			, 	CONST_PARENTID_PA AS ParentID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			, 	CONST_ACTIONTYPE_REMOVE AS ActionType
			, 	DATE(lv_CurrentDateTime) AS InsertDate
			, 	NULL AS TargetCC
			, 	(CASE WHEN temp.IsMarkedDirectly = 1 THEN 33 
					  WHEN temp.IsMarkedDirectly = 0 THEN 34 END) AS SourceTypeID
			,  	1 AS IsDataChanged
			,	NULL AS TargetDangerLevel1
			,	NULL AS TurnoverRM
			,	NULL AS WinlossRM
			, 	NULL AS BetCount
			, 	NULL AS ActiveDays
			,	NULL AS IsMarkedDirectly
			,	temp.Remark
		FROM Temp_CustomerClassification AS temp
		WHERE temp.IsRemovedPA = 1;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(
				CustID, CTSCustID, CategoryID, ParentID, LastModifiedDate, LastModifiedBy, ActionType
			, 	InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM
			, 	BetCount, ActiveDays, IsMarkedDirectly)
		SELECT DISTINCT 
				temp.CustID
			, 	temp.CTSCustID
			, 	NULL AS CategoryID
			, 	CONST_PARENTID_PA AS ParentID
			, 	lv_CurrentDateTime AS LastModifiedDate
			, 	temp.CreatedBy AS LastModifiedBy
			, 	CONST_ACTIONTYPE_REMOVE AS ActionType
			, 	DATE(lv_CurrentDateTime) AS InsertDate
			, 	NULL AS TargetCC
			, 	(CASE WHEN temp.IsMarkedDirectly = 1 THEN 33 
					  WHEN temp.IsMarkedDirectly = 0 THEN 34 END) AS SourceTypeID
			,  	1 AS IsDataChanged
			,	NULL AS TargetDangerLevel1
			,	NULL AS TurnoverRM
			,	NULL AS WinlossRM
			, 	NULL AS BetCount
			, 	NULL AS ActiveDays
			,	NULL AS IsMarkedDirectly
		FROM Temp_Customer AS temp;

	END IF;

	/*STEP 5: User Log*/
	IF ip_FromAction = 1 THEN
        SET lv_LogTypeID = 10;
		
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT 	lv_LogTypeID  AS LogTypeID
			, 	lv_SPName
			, 	CONCAT('Remove VVIP: CTSCustID', temp.CTSCustID,'; CustID', temp.CustID,'; AffectDownline_', ip_AffectDownline,'; CategoryID_', temp.CategoryID)
            ,	lv_CurrentDateTime
            , 	temp.CreatedBy
        FROM Temp_CustomerClassification AS temp;
		
	ELSEIF ip_InputFlowID = 222 THEN /*SpecialCC*/
		SET lv_LogTypeID = 20;
		
		SELECT CreatedBy
		INTO lv_CreatedBy
		FROM Temp_CustomerClassification AS temp
		LIMIT 1;
		
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT	lv_LogTypeID AS LogTypeID
			,	lv_SPName
			,	CONCAT('Remove special customer class: CTSCustList: ', GROUP_CONCAT(temp.CTSCustID),';CustIDList: ', GROUP_CONCAT(temp.CustID))
			,	lv_CurrentDateTime
			,	lv_CreatedBy
		FROM Temp_CustomerClassification AS temp;
	
	ELSEIF ip_IsFromQueue = 0 THEN /*PA*/
		SET lv_LogTypeID = 33;
	
		SELECT temp.CreatedBy, temp.IsExceptDirectDownline
		INTO lv_CreatedBy, lv_IsExceptDirectDownline
		FROM Temp_Customer AS temp 
		LIMIT 1;
		
		IF (lv_CreatedBy IS NOT NULL) THEN
			SELECT LEFT(CONCAT('CustNo.:',COUNT(1),'_IsExceptDirectDL:',lv_IsExceptDirectDownline,'_CustList',GROUP_CONCAT(DISTINCT temp.CTSCustID)),500)
			INTO lv_LogInfo
			FROM Temp_Customer AS temp;
		
			INSERT IGNORE INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
			SELECT 	lv_LogTypeID AS LogTypeID
				,	lv_SPName AS SPName
				,	lv_LogInfo AS LogInfo
				,	lv_CurrentDateTime AS CreatedDate
				,	lv_CreatedBy AS CreatedBy;
		
		END IF;
    END IF;
	
	/*STEP N: Return data*/
	SELECT DISTINCT temp.CustID, temp.CTSCustID, temp.IsCleanPA
	FROM Temp_CustomerClassification AS temp
	WHERE temp.IsReturnData = 1;
	
END$$
DELIMITER ;