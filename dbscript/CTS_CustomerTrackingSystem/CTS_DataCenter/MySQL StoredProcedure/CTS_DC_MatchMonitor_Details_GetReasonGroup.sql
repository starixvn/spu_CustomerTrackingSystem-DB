/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Details_GetReasonGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Details_GetReasonGroup`(
		IN ip_MatchID 		BIGINT UNSIGNED
    ,	IN ip_BettypeID		INT UNSIGNED
    ,	IN ip_BetID			BIGINT
    ,	IN ip_LiveIndicator BOOLEAN
	,	IN ip_Reason		TINYINT
    
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
			- -	20210823@Casey.Huynh: Remove ListCustID from return result[Redmine ID: 159195]
            -	20211213@Casey.Huynh: Enhance MM, Remove input Parameter ip_EventDate [Redmine ID: 165606]
            -	20220110@Casey.Huynh: Enhance MM, BetID, Reason [Redmine ID: 166986]\
            - 	20221122@Casey.Huynh: Update TotalScore to ScoreDiff [Redmine ID: #179499]
		Param's Explanation (filtered by): 
		
		Example:
			-	CALL CTS_DC_MatchMonitor_Details_GetReasonGroup(48995415,1,0,1,0);;
	*/
	
	SELECT 	mm.ScoreDiff
		, 	mm.GroupID
	FROM   CTS_DataCenter.MatchMonitorDetails AS mm
	WHERE  	mm.BettypeID = ip_BettypeID
		AND mm.BetID = ip_BetID
        AND mm.MatchID = ip_MatchID
        AND mm.LiveIndicator = ip_LiveIndicator
        AND mm.Reason = ip_Reason
	GROUP BY mm.ScoreDiff,	mm.GroupID
	ORDER BY mm.ScoreDiff, mm.GroupID;
    
END$$
DELIMITER ;
