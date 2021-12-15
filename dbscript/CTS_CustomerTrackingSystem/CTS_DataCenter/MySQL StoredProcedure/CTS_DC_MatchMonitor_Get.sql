/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Get`(
		IN 	ip_FromDate 		DATE
    ,	IN 	ip_ToDate 			DATE
    ,	IN 	ip_LeagueName		VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
    , 	IN	ip_Market 			TINYINT
    , 	IN	ip_MatchSection		VARCHAR(50)
    ,	IN 	ip_Bettypes 		VARCHAR(50)
    ,	IN 	ip_IsVerified 		BIT
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
            -	20210823@Casey.Huynh: Return Market value [Redmine ID: 159195]
			-	20211213@Casey.Huynh: Enhance MM, Add column LeagueName, reset IsVerified = 0 [Redmine ID: 165606]
		Param's Explanation (filtered by):
			- ip_Market: 0 return LiveIndicator = 0, 1 return LiveIndicator = 1
            
		Example:
			-	CALL CTS_DC_MatchMonitor_Get('2021-12-11','2021-12-14','Test',NULL,'1,2,3,4','1,3,7,8',NULL);
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Bettype;
    CREATE TEMPORARY TABLE Temp_Bettype(
		BettypeID 	INT UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchSection;
    CREATE TEMPORARY TABLE Temp_MatchSection(
		MatchSection 	TINYINT
	);
 
	SET @sql = CONCAT("INSERT INTO Temp_Bettype (BettypeID) VALUES ('", REPLACE(ip_Bettypes, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
       
	SET @sql = CONCAT("INSERT INTO Temp_MatchSection (MatchSection) VALUES ('", REPLACE(ip_MatchSection, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
    
    SELECT	tmp.ID
		,	tmp.MatchID
		,	tmp.EventDate
		,	tmp.LiveIndicator AS Market
		,	tmp.HomeID
		,	tmp.AwayID
		,	tmp.LeagueID                
		,	tmp.LeagueName
		,	tmp.BettypeID
		,	tmp.IsHedging
		,	tmp.IsVerified
		,	tmp.MatchSection
    FROM ( 
			SELECT 	s.ID
				,	s.MatchID
				,	s.EventDate
				,	s.LiveIndicator
				,	s.HomeID
				,	s.AwayID
				,	s.LeagueID                
				,	s.LeagueName
				,	s.BettypeID
				,	s.IsHedging		#CASE WHEN s.IsHedging = 1 THEN 'Hedging' ELSE 'Group Betting' END AS Reason
				,	s.IsVerified
				,	CASE WHEN NOW() BETWEEN s.KickOffTime AND TIMESTAMPADD(MINUTE, 150, s.KickOffTime ) AND LiveIndicator = 1 THEN 1 #Live
						WHEN s.EventDate = CURDATE() AND s.KickOffTime > NOW() THEN 2 #'Today'
						WHEN s.EventDate > CURDATE() THEN 3 #'Early'
						ELSE 4 #'Closed'
					END	AS MatchSection
			FROM   CTS_DataCenter.MatchMonitor AS s
				INNER JOIN Temp_Bettype AS b ON s.BettypeID = b.BettypeID
			WHERE s.EventDate BETWEEN ip_FromDate AND ip_ToDate
				AND (ip_IsVerified IS NULL OR s.IsVerified = ip_IsVerified)
			) AS tmp
            INNER JOIN Temp_MatchSection AS tmpMst ON tmpMst.MatchSection = tmp.MatchSection
       WHERE  (ip_LeagueName IS NULL OR (tmp.LeagueName LIKE CONCAT('%',ip_LeagueName,'%')))
			AND tmp.LiveIndicator = IFNULL(ip_Market, tmp.LiveIndicator);
            
END$$
DELIMITER ;


