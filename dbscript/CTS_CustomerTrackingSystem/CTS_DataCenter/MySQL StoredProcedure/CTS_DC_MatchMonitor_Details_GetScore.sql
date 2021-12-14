/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Details_GetScore`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Details_GetScore`(
		IN ip_MatchID 		BIGINT UNSIGNED
    ,	IN ip_BettypeID		INT UNSIGNED
	,	IN ip_LiveIndicator BOOLEAN
	,	IN ip_IsHedging		BOOLEAN
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Long.Luu
		Task :		Match Monitor Details - Get Scores
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Long.Luu: Created [Redmine ID: 152883]
            -	20211213@Casey.Huynh: Enhance MM, Remove input Parameter ip_EventDate [Redmine ID: 165606]
		
		Param's Explanation (filtered by):
		
		Example:
			-	CALL CTS_DC_MatchMonitor_Details_GetScore('2021-05-01',12345,1);
	*/
    
	SELECT 	DISTINCT s.TotalScore
		,	s.LiveHomeScore
        ,	s.LiveAwayScore
	FROM   CTS_DataCenter.MatchMonitorDetails AS s
	WHERE  	s.BettypeID = ip_BettypeID
        AND s.MatchID = ip_MatchID
        AND s.LiveIndicator = ip_LiveIndicator
        AND s.IsHedging = ip_IsHedging;
    
END$$
DELIMITER ;
