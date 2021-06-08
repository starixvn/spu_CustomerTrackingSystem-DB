/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Get`(
	IN ip_FromDate 		DATE,
    IN ip_ToDate 		DATE,
    IN ip_Bettypes 		VARCHAR(50),
    IN ip_IsVerified 	BIT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Long.Luu
		Task :		Get Match Monitor report
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Long.Luu: Created [Redmine ID: 152883]
		
		Param's Explanation (filtered by):
		
		Example:
			-	CALL CTS_DC_MatchMonitor_Get('2021-05-01','2021-05-03','1',0);
	*/
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Bettype;
    CREATE TEMPORARY TABLE Temp_Bettype(
		BettypeID 	INT UNSIGNED
	);
 
	SET @sql = CONCAT("INSERT INTO Temp_Bettype (BettypeID) VALUES ('", REPLACE(ip_Bettypes, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SELECT 	s.ID
		,	s.MatchID
		,	s.EventDate
        ,	s.HomeID
        ,	s.AwayID
        ,	s.LeagueID
        ,	s.BettypeID
        ,	CASE WHEN s.IsHedging = 1 THEN 'Hedging' ELSE 'Group Betting' END AS Reason
        ,	s.IsVerified
        ,	s.VerifiedDate
        ,	u.UserName AS VerifiedBy
        ,	CASE WHEN s.EventStatus = 'Completed' THEN 4 #'Closed'
                WHEN s.EventStatus IN ('running', 'closed') AND s.KickOffTime <= NOW() THEN 1 # 'Live'
				WHEN s.EventDate = CURDATE() AND s.KickOffTime > NOW() THEN 2 #'Today'
				WHEN s.EventDate > CURDATE() THEN 3 #'Early'
			END AS EventGroup
	FROM   CTS_DataCenter.MatchMonitor AS s
		INNER JOIN Temp_Bettype AS b ON s.BettypeID = b.BettypeID
        LEFT JOIN CTS_Admin.CTSUser AS u ON s.VerifiedBy = u.UserID
	WHERE  s.EventDate BETWEEN ip_FromDate AND ip_ToDate
		AND (ip_IsVerified IS NULL OR s.IsVerified = ip_IsVerified);

END$$
DELIMITER ;
