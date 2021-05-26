/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Details_GetReasonGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Details_GetReasonGroup`(
	IN ip_EventDate		DATE,
    IN ip_MatchID 		BIGINT UNSIGNED,
    IN ip_BettypeID		INT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Long.Luu
		Task :		Match Monitor Details - Get Reason Group
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Long.Luu: Created [Redmine ID: 152883]
		
		Param's Explanation (filtered by):
		
		Example:
			-	CALL CTS_DC_MatchMonitor_Details_GetReasonGroup('2021-05-01',12345,1);
	*/
	
	SELECT 	DISTINCT s.GroupID
		,	s.IsHedging
	FROM   CTS_DataCenter.MatchMonitorDetails AS s
	WHERE  s.EventDate = ip_EventDate
		AND s.BettypeID = ip_BettypeID
        AND s.MatchID = ip_MatchID;
    
END$$
DELIMITER ;
