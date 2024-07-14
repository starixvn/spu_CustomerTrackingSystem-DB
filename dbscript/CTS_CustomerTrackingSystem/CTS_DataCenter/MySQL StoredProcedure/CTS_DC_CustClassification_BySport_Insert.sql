/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_BySport_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_Insert`(
		IN	ip_InputFlowID			INT
	,	IN	ip_CustInfo				JSON
	,	OUT op_ErrorMessage 		VARCHAR(2000)
)
SQL SECURITY INVOKER
BEGIN
/*
		Created:	20240618@Victoria.Le
		Task:		Insert main customer categories for Customer Classification - BySport
		DB:			CTS_DataCenter
		
		Revisions: 
			-	20240618@Victoria.Le: 		Initial Writing [Redmine ID: #205317]
			
		Param's Expanation:
		
		Example:
			- CALL CTS_DC_CustClassification_BySport_Insert(8, 0, 0, 0, false, false, '[{"CustID":1275,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":1280,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5002646,"CategoryID":40700,"CategoryGroupID":0,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0},{"CustID":5022391,"CategoryID":0,"CategoryGroupID":40100,"CreatedTime":"2024-07-02T02:32:57.063","TurnoverRM":0.0,"WinlossRM":0.0,"BetCount":0,"ActiveDays":0,"PerformanceTime":"2024-07-02T02:32:57.063","LastXDaysMargin":0.0,"ProbationPeriodWinloss":0.0,"TaggingID":0,"TaggingType":0,"TWBetCount":0,"TWGroupBettingRate":0.0,"TWTicketRejectRate":0.0,"TWDesktopUsageRate":0.0,"ScanTaggingType":0}]', @outParam7);
*/
	DECLARE lv_SportID				SMALLINT UNSIGNED;
	DECLARE lv_CreatedBy			INT;
	DECLARE lv_LogTypeID			INT;
	DECLARE	lv_CurrentDateTime		DATETIME(3) DEFAULT CURRENT_TIME();
	DECLARE lv_SPName 				VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_BySport_Insert';

	/*STEP 1: Parse raw data and get custinfo*/
	CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_Insert_GetInfo (ip_InputFlowID,ip_CustInfo);
	
	IF ip_InputFlowID = 339 THEN /*Normal*/
		
		/*STEP 2: PreProcess*/
		CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_Insert_PreProcess ();
		
		/*STEP 3: Process*/
		CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_Insert_Process ();
		
	END IF;
	
	/*STEP 4: Complete*/
	CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_Insert_Complete (ip_InputFlowID);
	
	/*STEP 5:  User Log*/
	IF ip_InputFlowID = 332 THEN /*SpecialCC*/
		SET lv_LogTypeID	= 19;
	
		SELECT DISTINCT SportID, CreatedBy
		INTO lv_SportID, lv_CreatedBy
		FROM Temp_NewClassification;
		
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT	lv_LogTypeID AS LogTypeID
			,	lv_SPName
			,	CONCAT('Insert SpecialCustomerClass_BySport: CTSCustList: ', GROUP_CONCAT(CTSCustID),';SportID: ', lv_SportID, ';CustomerClass: ', GROUP_CONCAT(DISTINCT TargetCC)) AS LogInfo
			,	lv_CurrentDateTime
			,	lv_CreatedBy
		FROM Temp_NewClassification;
		
	END IF;
	
	/*STEP N: Return data*/
	SELECT DISTINCT temp.CustID, temp.SportID AS SportGroup, temp.TargetCC AS CustomerClass
	FROM Temp_NewClassification AS temp
	WHERE temp.IsReturnData = 1;

END$$
DELIMITER ;