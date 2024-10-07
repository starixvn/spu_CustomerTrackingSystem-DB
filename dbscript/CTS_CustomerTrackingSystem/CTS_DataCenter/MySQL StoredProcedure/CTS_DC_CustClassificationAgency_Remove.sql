/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassificationAgency_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassificationAgency_Remove`(
		IN	ip_InputFlowID			INT 
	,	IN	ip_FromAction			TINYINT
	,	IN	ip_UplineRoleID			INT
	,	IN	ip_QueueID				BIGINT
	,	IN	ip_IsAffectDownline		TINYINT(1)
	,	IN	ip_IsFromQueue			TINYINT(1)
	,	IN	ip_CustInfo				JSON
	,	OUT op_ErrorMessage 		VARCHAR(2000)
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240927@Thomas.Nguyen
		Task:		
		DB:			CTS_DataCenter
			
		Param's Expanation:
			1. ip_InputFlowID: Used to identify flows: Insert/Rescan/Remove. Details of this can be found from StaticList (ListID = 24)
			2. ip_FromAction: From CTSWeb (1), From CTS API (2), From CTS Service (3), From Manual Trigger (4)
			3. ip_UplineRoleID: From Web (NULL), From Service (<UplineRoleID>)
			4. ip_QueueID: From Web (NULL), From Service (<QueueID>)
			5. ip_IsAffectDownline: From Web (0,1), From Service (NULL)
			6. ip_IsFromQueue: Remove from queue PA
			7. ip_CustInfo
			8. op_ErrorMessage
			- Param's Input:
				+ InputFlow = VVIP: 2 + 3 + 4 + 5 + 7
				+ InputFlow = SpecialCC: 7
				+ InputFlow = LicVIP: 7
				+ InputFlow = LicBA: 7
				+ InputFlow = PA: 6 + 7
			
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassificationAgency_Remove(225, 0, 0, 0, false, false, '[{"CustID":1275,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":1280,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5002646,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5022391,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0}]', @outParam7);

		Revisions: 
			- 20240927@Thomas.Nguyen:	        Created [Redmine ID: #185799]
*/
	DECLARE CONST_AGENCY_INPUTFLOWID_GENERAL_REMOVE_VVIP 			INT;
	
	DECLARE lv_CurrentDateTime 								DATETIME DEFAULT CURRENT_TIMESTAMP();
	DECLARE lv_LogTypeID									INT;
	DECLARE lv_CreatedBy									INT;
	DECLARE lv_IsExceptDirectDownline						TINYINT(1);
	DECLARE lv_SPName 										VARCHAR(200) DEFAULT 'CTS_DC_CustClassificationAgency_Remove';
	DECLARE lv_LogInfo 										VARCHAR(500);
	DECLARE lv_MaxCTSCustID									BIGINT;
	
	SET CONST_AGENCY_INPUTFLOWID_GENERAL_REMOVE_VVIP				= CTS_DC_CategoryTypeParent_Get ('CONST_AGENCY_INPUTFLOWID_GENERAL_REMOVE_VVIP');

	/*STEP 1: Parse raw data and get custinfo*/
	CALL CTS_DataCenter.CTS_DC_CustClassificationAgency_Remove_GetInfo (ip_InputFlowID,ip_CustInfo);
	
	/*STEP 2: Process and Complete*/
	CALL CTS_DataCenter.CTS_DC_CustClassificationAgency_Remove_Complete (ip_InputFlowID,ip_FromAction,ip_UplineRoleID,ip_IsFromQueue,ip_CustInfo);

	IF ip_InputFlowID = CONST_AGENCY_INPUTFLOWID_GENERAL_REMOVE_VVIP AND ip_FromAction = 3 AND ip_QueueID IS NOT NULL THEN
		SELECT MAX(temp.CTSCustID)
		INTO lv_MaxCTSCustID
		FROM Temp_CustomerClassification AS temp;
	
		UPDATE CTS_DataCenter.CTSCustomerClassificationQueue AS que
		SET que.LastDownlineCTSCustID = lv_MaxCTSCustID
		WHERE que.ID = ip_QueueID;
	END IF;

	/*STEP 3: User Log*/
	IF ip_InputFlowID = CONST_AGENCY_INPUTFLOWID_GENERAL_REMOVE_VVIP AND ip_FromAction = 1 THEN
        SET lv_LogTypeID = 10;
		
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT 	lv_LogTypeID  AS LogTypeID
			, 	lv_SPName
			, 	CONCAT('Remove VVIP: CTSCustID', temp.CTSCustID,'; CustID', temp.CustID,'; AffectDownline_', ip_IsAffectDownline,'; CategoryID_', temp.CategoryID)
            ,	lv_CurrentDateTime
            , 	temp.CreatedBy
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