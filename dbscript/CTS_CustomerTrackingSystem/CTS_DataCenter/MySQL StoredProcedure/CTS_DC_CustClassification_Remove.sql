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

	/*STEP 1: Parse raw data and get custinfo*/
	
	
	
	/*STEP 2: Preprocess*/
	/*STEP 3: Process*/
	/*STEP 4: Complete*/
	/*STEP 5: User Log*/
	/*STEP 6: AffectedDownline*/
	/*STEP N: Return data*/

	
END$$
DELIMITER ;