/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_HoldKey_InsertLog`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_HoldKey_InsertLog`(
		IN ip_UserID	BIGINT UNSIGNED
    , 	IN ip_Status	BOOLEAN
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20240129@Jonas.Huynh
		Task:		Hold Key [Redmine ID: 197914].
		DB:			CTS_DataCenter
		Original:

		Revisions:
			-	20240129@Jonas.Huynh: Created [Redmine ID: 197914]
		Param's Explanation (filtered by):
        
        CALL CTS_DC_MatchMonitor_HoldKey_InsertLog (10, true);
	*/
        
    INSERT INTO CTS_DataCenter.MatchMonitorHoldKey_ActionLog(UserID, Status)
	SELECT		ip_UserId, ip_Status;

END$$
DELIMITER ;