/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Remove`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_FromAction			TINYINT
	,	IN	ip_UplineRoleID			INT
	,	IN	ip_QueueID				BIGINT
	,	IN	ip_AffectDownline		BIT(1)
	,	IN	ip_IsFromQueue			BIT(1)
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
	DECLARE CONST_ACTIONTYPE_REMOVE 					INT DEFAULT 2;

	DECLARE lv_SourceTypeID								INT;
	DECLARE lv_MaxCTSCustID								BIGINT UNSIGNED;
	
	DECLARE lv_CurrentDateTime 							DATETIME DEFAULT CURRENT_TIME();
	DECLARE lv_IsAuto									INT;
	DECLARE lv_ActionType								INT;
	DECLARE lv_IsDataChanged							INT;
	DECLARE lv_TargetCC									INT;
	
	SET CONST_PARENTID_VVIP 					= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_VVIP');

	/*STEP 1: Parse raw data and get custinfo*/
	CALL CTS_DataCenter.CTS_DC_CustClassification_Insert_GetInfo (ip_InputFlowID,ip_CustInfo);
	
	IF ip_InputFlowID = 221 THEN /*VVIP*/
		SET lv_ActionType 			= CONST_ACTIONTYPE_REMOVE;
		SET lv_IsAuto 				= 0;
		SET lv_TargetCC				= -1;
		SET lv_IsDataChanged		= 1;
		
		SELECT MAX(temp.CTSCustID)
		INTO lv_MaxCTSCustID
		FROM Temp_CustomerClassification AS temp;
		
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
		
	END IF;
	
	/*STEP 2: Preprocess*/
	/*STEP 3: Process*/
	/*STEP 4: Complete*/
	/*STEP 5: User Log*/
	/*STEP 6: AffectedDownline*/
	/*STEP N: Return data*/
	
	

	
END$$
DELIMITER ;