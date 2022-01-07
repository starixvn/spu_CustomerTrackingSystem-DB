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
            - 	20220107@Casey.Huynh: Fix Issue get data for Verified Trans [Redmine ID: 167192]
		Param's Explanation (filtered by):
			- ip_Market: 0 return LiveIndicator = 0, 1 return LiveIndicator = 1
            
		Example:
			-	CALL CTS_DC_MatchMonitor_Get('2021-12-11','2021-12-14','Test',NULL,'1,2,3,4','1,3,7,8',NULL);
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitor;
    CREATE TEMPORARY TABLE Temp_MatchMonitor(
			ID				BIGINT UNSIGNED
        ,	MatchID 		INT
        ,	EventDate		DATETIME
        ,	LiveIndicator	TINYINT
        ,	HomeID			INT
        ,	AwayID			INT
        ,	LeagueID		INT
        ,	LeagueName		VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
        ,	BettypeID		INT
        ,	IsHedging		TINYINT
        ,	MatchSection	INT   
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Bettype;
    CREATE TEMPORARY TABLE Temp_Bettype(
		BettypeID 	INT UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchSection;
    CREATE TEMPORARY TABLE Temp_MatchSection(
		MatchSection 	TINYINT
	);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchGroup;
    CREATE TEMPORARY TABLE Temp_MatchGroup(
			MatchID 		INT
        ,	LiveIndicator	TINYINT
		,	BettypeID		INT
        ,	IsHedging		INT
        
        ,	PRIMARY KEY PK_Temp_MatchTrans(MatchID,LiveIndicator,BettypeID,IsHedging)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchGroup_NotVerified;
    CREATE TEMPORARY TABLE Temp_MatchGroup_NotVerified(
			MatchID 		INT
        ,	LiveIndicator	TINYINT
		,	BettypeID		INT
        ,	IsHedging		INT
        
        ,	PRIMARY KEY PK_Temp_MatchTrans(MatchID,LiveIndicator,BettypeID,IsHedging)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_VerfiedTrans;
    CREATE TEMPORARY TABLE Temp_VerfiedTrans(
        TransID	BIGINT UNSIGNED PRIMARY KEY
	);
    
    
    
	SET @sql = CONCAT("INSERT INTO Temp_Bettype (BettypeID) VALUES ('", REPLACE(ip_Bettypes, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
       
	SET @sql = CONCAT("INSERT INTO Temp_MatchSection (MatchSection) VALUES ('", REPLACE(ip_MatchSection, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1; 
    
    INSERT INTO Temp_MatchMonitor(ID, MatchID, EventDate, LiveIndicator, HomeID, AwayID, LeagueID, LeagueName, BettypeID, IsHedging, MatchSection)    
    SELECT	tmp.ID
		,	tmp.MatchID
		,	tmp.EventDate
		,	tmp.LiveIndicator
		,	tmp.HomeID
		,	tmp.AwayID
		,	tmp.LeagueID                
		,	tmp.LeagueName
		,	tmp.BettypeID
		,	tmp.IsHedging
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
				,	CASE WHEN NOW() BETWEEN s.KickOffTime AND TIMESTAMPADD(MINUTE, 150, s.KickOffTime ) AND LiveIndicator = 1 THEN 1 #Live
						WHEN s.EventDate = CURDATE() AND s.KickOffTime > NOW() THEN 2 #'Today'
						WHEN s.EventDate > CURDATE() THEN 3 #'Early'
						ELSE 4 #'Closed'
					END	AS MatchSection
			FROM   CTS_DataCenter.MatchMonitor AS s
				INNER JOIN Temp_Bettype AS b ON s.BettypeID = b.BettypeID
			WHERE s.EventDate BETWEEN ip_FromDate AND ip_ToDate
			) AS tmp
            INNER JOIN Temp_MatchSection AS tmpMst ON tmpMst.MatchSection = tmp.MatchSection
       WHERE  (ip_LeagueName IS NULL OR (tmp.LeagueName LIKE CONCAT('%',ip_LeagueName,'%')))
			AND tmp.LiveIndicator = IFNULL(ip_Market, tmp.LiveIndicator);
    
    INSERT IGNORE INTO Temp_VerfiedTrans(TransID)
    SELECT js.TransID
    FROM CTS_DataCenter.MatchMonitorDetailsVerifiedTrans AS mdv 
    INNER JOIN Temp_MatchMonitor AS tmpMm ON mdv.MatchID = tmpMm.MatchID AND mdv.LiveIndicator = tmpMm.LiveIndicator AND mdv.BettypeID = tmpMm.BettypeID 
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(mdv.ListTransID), ',', '","'), 
						'$[*]' COLUMNS (TransID BIGINT UNSIGNED PATH '$')
						) js
	;

    INSERT IGNORE INTO Temp_MatchGroup(MatchID, LiveIndicator, BettypeID, IsHedging)
    SELECT	tmpMm.MatchID
				,	tmpMm.LiveIndicator
				,	tmpMm.BettypeID
				,	tmpMm.IsHedging
	FROM Temp_MatchMonitor AS tmpMm;
    
	INSERT INTO Temp_MatchGroup_NotVerified(MatchID, LiveIndicator, BettypeID, IsHedging)
    SELECT DISTINCT	tmpMg.MatchID
		,	tmpMg.LiveIndicator
		,	tmpMg.BettypeID
		,	tmpMg.IsHedging
    FROM Temp_MatchGroup AS tmpMg
		INNER JOIN CTS_DataCenter.MatchMonitorDetails AS mmd ON tmpMg.MatchID = mmd.MatchID AND tmpMg.LiveIndicator = mmd.LiveIndicator 
				AND tmpMg.BettypeID = mmd.BettypeID AND tmpMg.IsHedging = mmd.IsHedging
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(mmd.ListTransID), ',', '","'), 
						'$[*]' COLUMNS (TransID BIGINT UNSIGNED PATH '$')
						) js
	WHERE NOT EXISTS (SELECT 1 FROM Temp_VerfiedTrans AS tmpVt WHERE js.TransID = tmpVt.TransID);    
    
    IF (ip_IsVerified IS NULL)
    THEN
		SELECT	tmpMm.ID
			,	tmpMm.MatchID
			,	tmpMm.EventDate
			,	tmpMm.LiveIndicator AS Market
			,	tmpMm.HomeID
			,	tmpMm.AwayID
			,	tmpMm.LeagueID                
			,	tmpMm.LeagueName
			,	tmpMm.BettypeID
			,	tmpMm.IsHedging
			,	tmpMm.MatchSection 
			,	(CASE WHEN tmpNv.MatchID IS NULL THEN 1 ELSE 0 END) IsVerified
		FROM Temp_MatchMonitor AS tmpMm
        	LEFT JOIN Temp_MatchGroup_NotVerified AS tmpNv ON tmpMm.MatchID = tmpNv.MatchID AND tmpMm.LiveIndicator = tmpNv.LiveIndicator 
					AND tmpMm.BettypeID = tmpNv.BettypeID AND tmpMm.IsHedging = tmpNv.IsHedging;
	END IF;
    
	IF (ip_IsVerified = 0)
    THEN
		SELECT	tmpMm.ID
			,	tmpMm.MatchID
			,	tmpMm.EventDate
			,	tmpMm.LiveIndicator AS Market
			,	tmpMm.HomeID
			,	tmpMm.AwayID
			,	tmpMm.LeagueID                
			,	tmpMm.LeagueName
			,	tmpMm.BettypeID
			,	tmpMm.IsHedging
			,	tmpMm.MatchSection 
			,	0 AS  IsVerified
		FROM Temp_MatchMonitor AS tmpMm
		INNER JOIN Temp_MatchGroup_NotVerified AS tmpNv ON tmpMm.MatchID = tmpNv.MatchID AND tmpMm.LiveIndicator = tmpNv.LiveIndicator 
					AND tmpMm.BettypeID = tmpNv.BettypeID AND tmpMm.IsHedging = tmpNv.IsHedging;
	END IF;
    
    IF (ip_IsVerified = 1)
    THEN
		SELECT	tmpMm.ID
			,	tmpMm.MatchID
			,	tmpMm.EventDate
			,	tmpMm.LiveIndicator AS Market
			,	tmpMm.HomeID
			,	tmpMm.AwayID
			,	tmpMm.LeagueID                
			,	tmpMm.LeagueName
			,	tmpMm.BettypeID
			,	tmpMm.IsHedging
			,	tmpMm.MatchSection 
			,	1 AS  IsVerified
		FROM Temp_MatchMonitor AS tmpMm
		LEFT JOIN Temp_MatchGroup_NotVerified AS tmpNv ON tmpMm.MatchID = tmpNv.MatchID AND tmpMm.LiveIndicator = tmpNv.LiveIndicator 
					AND tmpMm.BettypeID = tmpNv.BettypeID AND tmpMm.IsHedging = tmpNv.IsHedging
		WHERE tmpNv.MatchID IS NULL;
	END IF;
                
END$$
DELIMITER ;


