/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Get`(
		IN	ip_DateType			TINYINT(1) #1: InsertDate, 2: EvenDate
	,	IN 	ip_FromDate 		DATETIME
    ,	IN 	ip_ToDate 			DATETIME
    ,	IN	ip_SportType		VARCHAR(500)
    , 	IN	ip_Market 			TINYINT			# NULL if Both (Live and NonLive)
    , 	IN	ip_MatchSection		VARCHAR(50)
    ,	IN 	ip_IsVerified 		TINYINT(1)
    ,	IN 	ip_Bettypes 		JSON # BettypeID and BetID       
    ,	IN	ip_Reason			VARCHAR(50)
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
            - 	20220107@Casey.Huynh: Fix Issue get data for Verified Trans [Redmine ID: 167192]
			-	20211213@Casey.Huynh: Enhance MM, Add column LeagueName, reset IsVerified = 0 [Redmine ID: 165606]
            -	20220110@Casey.Huynh: Enhance MM, BetID, Reason [Redmine ID: 166986]
            - 	20220216@Casey.Huynh: Fix Issue, show IsVerified = 0 when all tickets were verified [Redmine ID: 166986]
            - 	20220325@Long.Luu: Add Reason filter [Redmine ID: 170466]
            -	20220805@Jonas.Huynh: Add Reason Fixed Game [Redmine ID: 175700]
            -	20221027@Casey.Huynh: Update Verify By Reason and Betteam [RedmineID: 179439]
            -	20230105@Casey.Huynh: Add search by InsertDate and remove ip_LeagueName [Redmine ID: #181995]
            
		Param's Explanation (filtered by):
			- ip_Market: 0 return LiveIndicator = 0, 1 return LiveIndicator = 1, NULL: Both Live And Non-Live
            - ip_Reason: 0:Group Betting, 1: Hedging, 2: Arbitrage, 3: Fixed Game
            - ip_DateType: 1: by InsertDate, 2:EventDate
		Example:
			-	CALL CTS_DC_MatchMonitor_Get(@ip_DateType:=1,@ip_FromDate:='2023-01-05',@ip_ToDate:='2023-01-8',@ip_SportType:=1,@ip_Market:=1,@ip_MatchSection:='1,2,3,4',@ip_IsVerified:=NULL
				,@ip_Bettypes:='[{"BettypeID":1,"BetID":0},{"BettypeID":3,"BetID":0},{"BettypeID":7,"BetID":0}]',@ip_Reason:='0,1,2');
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
        ,	LeagueName		VARCHAR(500) 
        ,	Sporttype		INT
        ,	BettypeID		INT
        ,	BetID			BIGINT
        ,	Reason			TINYINT
        ,	MatchSection	INT   
        ,	KickOffTime		DATETIME
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Bettype;
    CREATE TEMPORARY TABLE Temp_Bettype(
			BettypeID 	INT UNSIGNED
        ,	BetID		BIGINT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Sporttype;
    CREATE TEMPORARY TABLE Temp_Sporttype(
			Sporttype 	INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Reason;
    CREATE TEMPORARY TABLE Temp_Reason(
			ReasonID 	INT
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
        ,	BetID			INT
        ,	Reason			INT
        ,	VerifiedBy		VARCHAR(1000)
        
        ,	PRIMARY KEY PK_Temp_MatchTrans(MatchID,LiveIndicator,BettypeID, BetID, Reason)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchGroup_NotVerified;
    CREATE TEMPORARY TABLE Temp_MatchGroup_NotVerified(
			MatchID 		INT
        ,	LiveIndicator	TINYINT
		,	BettypeID		INT
        ,	BetID		INT
        ,	Reason		INT
        
        ,	PRIMARY KEY PK_Temp_MatchTrans(MatchID,LiveIndicator,BettypeID, BetID, Reason)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_VerfiedTrans;
    CREATE TEMPORARY TABLE Temp_VerfiedTrans(
			TransID			BIGINT UNSIGNED
        ,	Reason			TINYINT        
		,	MatchID 		INT
        ,	LiveIndicator	TINYINT
		,	BettypeID		INT
        ,	BetID			INT
        ,	VerifiedBy 		VARCHAR(50)
        ,	INDEX IX_Temp_VerfiedTrans(TransID,Reason)
        ,	INDEX IX_Temp_MatchGroup(MatchID,LiveIndicator,BettypeID, BetID, Reason)
	);
    
    INSERT IGNORE INTO Temp_Bettype(BettypeID, BetID)
	SELECT  js.BettypeID
		,	js.BetID
	FROM JSON_TABLE(ip_Bettypes,
					 "$[*]" COLUMNS(
								BettypeID		INT	PATH "$.BettypeID"
							,	BetID			BIGINT	PATH "$.BetID"
						)
				) AS js;  
          
	SET @sql = CONCAT("INSERT INTO Temp_MatchSection (MatchSection) VALUES ('", REPLACE(ip_MatchSection, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1; 
    
    SET @sql = CONCAT("INSERT INTO Temp_Sporttype (Sporttype) VALUES ('", REPLACE(ip_Sporttype, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1; 
    
    SET @sql = CONCAT("INSERT INTO Temp_Reason (ReasonID) VALUES ('", REPLACE(ip_Reason, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1; 
    
    IF (ip_DateType = 1) THEN # Search by Insert Date
		INSERT INTO Temp_MatchMonitor(ID, MatchID, EventDate, LiveIndicator, HomeID, AwayID, LeagueID, LeagueName, Sporttype, BettypeID, BetID, Reason, MatchSection, KickOffTime)    
		SELECT	tmp.ID
			,	tmp.MatchID
			,	tmp.EventDate
			,	tmp.LiveIndicator
			,	tmp.HomeID
			,	tmp.AwayID
			,	tmp.LeagueID                
			,	tmp.LeagueName
			,	tmp.Sporttype
			,	tmp.BettypeID
			,	tmp.BetID
			,	tmp.Reason
			,	tmp.MatchSection
            ,	tmp.KickOffTime
		FROM ( 
				SELECT 	s.ID
					,	s.MatchID
					,	s.EventDate
					,	s.LiveIndicator
					,	s.HomeID
					,	s.AwayID
					,	s.LeagueID                
					,	s.LeagueName
					,	s.Sporttype
					,	s.BettypeID
					,	s.BetID
					,	s.Reason		# 0:Group Betting, 1: Hedging, 2: Arbitrage, 3: Fixed Game , 58: Irrigition
					,	CASE WHEN NOW() BETWEEN s.KickOffTime AND TIMESTAMPADD(MINUTE, 150, s.KickOffTime ) AND LiveIndicator = 1 THEN 1 #Live
							WHEN s.EventDate = CURDATE() AND s.KickOffTime > NOW() THEN 2 #'Today'
							WHEN s.EventDate > CURDATE() THEN 3 #'Early'
							ELSE 4 #'Closed'
						END	AS MatchSection
					,	s.KickOffTime
				FROM   CTS_DataCenter.MatchMonitor AS s
					INNER JOIN Temp_Bettype AS tmpBt ON s.BettypeID = tmpBt.BettypeID AND s.BetID = tmpBt.BetID
					INNER JOIN Temp_Sporttype AS tmpSt ON s.Sporttype = tmpSt.SportType
					INNER JOIN Temp_Reason AS r ON r.ReasonID = s.Reason
				WHERE s.InsertDate BETWEEN ip_FromDate AND ip_ToDate
				) AS tmp
				INNER JOIN Temp_MatchSection AS tmpMst ON tmpMst.MatchSection = tmp.MatchSection
		   WHERE tmp.LiveIndicator = IFNULL(ip_Market, tmp.LiveIndicator);
    ELSE #ip_DateType = 2 THEN # Search by Event Date
		INSERT INTO Temp_MatchMonitor(ID, MatchID, EventDate, LiveIndicator, HomeID, AwayID, LeagueID, LeagueName, Sporttype, BettypeID, BetID, Reason, MatchSection, KickOffTime)    
		SELECT	tmp.ID
			,	tmp.MatchID
			,	tmp.EventDate
			,	tmp.LiveIndicator
			,	tmp.HomeID
			,	tmp.AwayID
			,	tmp.LeagueID                
			,	tmp.LeagueName
			,	tmp.Sporttype
			,	tmp.BettypeID
			,	tmp.BetID
			,	tmp.Reason
			,	tmp.MatchSection
            ,	tmp.KickOffTime
		FROM ( 
				SELECT 	s.ID
					,	s.MatchID
					,	s.EventDate
					,	s.LiveIndicator
					,	s.HomeID
					,	s.AwayID
					,	s.LeagueID                
					,	s.LeagueName
					,	s.Sporttype
					,	s.BettypeID
					,	s.BetID
					,	s.Reason		# 0:Group Betting, 1: Hedging, 2: Arbitrage, 3: Fixed Game
					,	CASE WHEN NOW() BETWEEN s.KickOffTime AND TIMESTAMPADD(MINUTE, 150, s.KickOffTime ) AND LiveIndicator = 1 THEN 1 #Live
							WHEN s.EventDate = CURDATE() AND s.KickOffTime > NOW() THEN 2 #'Today'
							WHEN s.EventDate > CURDATE() THEN 3 #'Early'
							ELSE 4 #'Closed'
						END	AS MatchSection
					, s.KickOffTime
				FROM   CTS_DataCenter.MatchMonitor AS s
					INNER JOIN Temp_Bettype AS tmpBt ON s.BettypeID = tmpBt.BettypeID AND s.BetID = tmpBt.BetID
					INNER JOIN Temp_Sporttype AS tmpSt ON s.Sporttype = tmpSt.SportType
					INNER JOIN Temp_Reason AS r ON r.ReasonID = s.Reason
				WHERE s.EventDate BETWEEN ip_FromDate AND ip_ToDate
				) AS tmp
				INNER JOIN Temp_MatchSection AS tmpMst ON tmpMst.MatchSection = tmp.MatchSection
		   WHERE tmp.LiveIndicator = IFNULL(ip_Market, tmp.LiveIndicator);
    END IF;
    

    
    INSERT IGNORE INTO Temp_VerfiedTrans(TransID, Reason, VerifiedBy, MatchID,LiveIndicator,BettypeID, BetID)
    SELECT js.TransID, mdv.Reason, us.UserName, mdv.MatchID, mdv.LiveIndicator, mdv.BettypeID, mdv.BetID
    FROM CTS_DataCenter.MatchMonitorDetailsVerifiedTrans AS mdv
		LEFT JOIN CTS_Admin.CTSUser AS us ON us.UserID = mdv.VerifiedBy
		INNER JOIN Temp_MatchMonitor AS tmpMm ON mdv.MatchID = tmpMm.MatchID AND mdv.LiveIndicator = tmpMm.LiveIndicator AND mdv.BettypeID = tmpMm.BettypeID AND mdv.BetID = tmpMm.BetID 
			AND ((mdv.Reason = tmpMm.Reason) OR mdv.Reason IS NULL)
			JOIN JSON_TABLE(REPLACE(JSON_ARRAY(mdv.ListTransID), ',', '","'), 
						'$[*]' COLUMNS (TransID BIGINT UNSIGNED PATH '$')
						) js;
    
    INSERT INTO Temp_MatchGroup(MatchID, LiveIndicator, BettypeID, BetID, Reason, VerifiedBy)
    SELECT	tmpMm.MatchID
			,	tmpMm.LiveIndicator
			,	tmpMm.BettypeID
            ,	tmpMm.BetID
			,	tmpMm.Reason
            ,	GROUP_CONCAT(DISTINCT tmpVt.VerifiedBy)
	FROM Temp_MatchMonitor AS tmpMm
		LEFT JOIN Temp_VerfiedTrans AS tmpVt ON tmpVt.MatchID = tmpMm.MatchID AND tmpVt.LiveIndicator = tmpMm.LiveIndicator AND tmpVt.BettypeID = tmpMm.BettypeID AND tmpVt.BetID = tmpMm.BetID AND tmpVt.Reason = tmpMm.Reason
	GROUP BY MatchID, LiveIndicator, BettypeID, BetID, Reason; 
    
	INSERT INTO Temp_MatchGroup_NotVerified(MatchID, LiveIndicator, BettypeID, BetID, Reason)
    SELECT DISTINCT	tmpMg.MatchID
		,	tmpMg.LiveIndicator
		,	tmpMg.BettypeID
        ,	tmpMg.BetID
		,	tmpMg.Reason
    FROM Temp_MatchGroup AS tmpMg
		INNER JOIN CTS_DataCenter.MatchMonitorDetails AS mmd ON tmpMg.MatchID = mmd.MatchID AND tmpMg.LiveIndicator = mmd.LiveIndicator
				AND tmpMg.BettypeID = mmd.BettypeID AND tmpMg.BetID = mmd.BetID AND tmpMg.Reason = mmd.Reason
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(mmd.ListTransID), ',', '","'), 
						'$[*]' COLUMNS (TransID BIGINT UNSIGNED PATH '$')
						) js
	WHERE NOT EXISTS (SELECT 1 FROM Temp_VerfiedTrans AS tmpVt WHERE js.TransID = tmpVt.TransID AND ((mmd.Reason = tmpVt.Reason) OR tmpVt.Reason IS NULL));    

    IF (ip_IsVerified IS NULL)
    THEN
		SELECT	tmpMm.MatchID
            ,	tmpMm.MatchSection
			,	tmpMm.EventDate
            ,	tmpMm.KickOffTime
			,	tmpMm.LiveIndicator AS Market
			,	tmpMm.HomeID
			,	tmpMm.AwayID
			,	tmpMm.LeagueID                
			,	tmpMm.LeagueName
            ,	tmpMm.Sporttype
			,	tmpMm.BettypeID
            ,	tmpMm.BetID
			,	GROUP_CONCAT(DISTINCT tmpMm.Reason)	AS Reason		
			,	(SELECT 0 FROM Temp_MatchGroup_NotVerified AS tmpNv WHERE tmpMm.MatchID = tmpNv.MatchID AND tmpMm.LiveIndicator = tmpNv.LiveIndicator 
					AND tmpMm.BettypeID = tmpNv.BettypeID AND tmpMm.BetID = tmpNv.BetID LIMIT 1) IsVerified
            ,	GROUP_CONCAT(DISTINCT tmpMg.VerifiedBy)	AS VerifiedBy
		FROM Temp_MatchMonitor AS tmpMm
			LEFT JOIN Temp_MatchGroup AS tmpMg ON tmpMm.MatchID = tmpMg.MatchID AND tmpMm.LiveIndicator = tmpMg.LiveIndicator 
					AND tmpMm.BettypeID = tmpMg.BettypeID AND tmpMm.BetID = tmpMg.BetID 
		GROUP BY tmpMm.MatchID
            ,	tmpMm.MatchSection
			,	tmpMm.EventDate
            ,	tmpMm.KickOffTime
			,	tmpMm.LiveIndicator
			,	tmpMm.HomeID
			,	tmpMm.AwayID
			,	tmpMm.LeagueID                
			,	tmpMm.LeagueName
            ,	tmpMm.Sporttype
			,	tmpMm.BettypeID
            ,	tmpMm.BetID;
	END IF;
    
	IF (ip_IsVerified = 0)
    THEN
		SELECT	tmpMm.ID
			,	tmpMm.MatchID
			,	tmpMm.EventDate
            ,	tmpMm.KickOffTime
			,	tmpMm.LiveIndicator AS Market
			,	tmpMm.HomeID
			,	tmpMm.AwayID
			,	tmpMm.LeagueID                
			,	tmpMm.LeagueName
            ,	tmpMm.Sporttype
			,	tmpMm.BettypeID
            ,	tmpMm.BetID
			,	tmpMm.Reason
			,	tmpMm.MatchSection
			,	0 AS  IsVerified
			,	NULL AS VerifiedBy
		FROM Temp_MatchMonitor AS tmpMm
		INNER JOIN Temp_MatchGroup_NotVerified AS tmpNv ON tmpMm.MatchID = tmpNv.MatchID AND tmpMm.LiveIndicator = tmpNv.LiveIndicator 
					AND tmpMm.BettypeID = tmpNv.BettypeID AND tmpMm.BetID = tmpNv.BetID AND tmpMm.Reason = tmpNv.Reason;
	END IF;
    
    IF (ip_IsVerified = 1)
    THEN
		SELECT	tmpMm.MatchID
            ,	tmpMm.MatchSection
			,	tmpMm.EventDate
            ,	tmpMm.KickOffTime
			,	tmpMm.LiveIndicator AS Market
			,	tmpMm.HomeID
			,	tmpMm.AwayID
			,	tmpMm.LeagueID                
			,	tmpMm.LeagueName
            ,	tmpMm.Sporttype
			,	tmpMm.BettypeID
            ,	tmpMm.BetID
			,	GROUP_CONCAT(DISTINCT tmpMm.Reason)	AS Reason		
			,	1 AS IsVerified
            ,	GROUP_CONCAT(DISTINCT tmpMg.VerifiedBy)	AS VerifiedBy
		FROM Temp_MatchMonitor AS tmpMm
		INNER JOIN Temp_MatchGroup AS tmpMg ON tmpMm.MatchID = tmpMg.MatchID AND tmpMm.LiveIndicator = tmpMg.LiveIndicator 
					AND tmpMm.BettypeID = tmpMg.BettypeID AND tmpMm.BetID = tmpMg.BetID AND tmpMm.Reason = tmpMg.Reason
		WHERE NOT EXISTS(SELECT 1 FROM Temp_MatchGroup_NotVerified AS tmpNv WHERE tmpMm.MatchID = tmpNv.MatchID AND tmpMm.LiveIndicator = tmpNv.LiveIndicator 
					AND tmpMm.BettypeID = tmpNv.BettypeID AND tmpMm.BetID = tmpNv.BetID)
        GROUP BY tmpMm.MatchID
            ,	tmpMm.MatchSection
			,	tmpMm.EventDate
            ,	tmpMm.KickOffTime
			,	tmpMm.LiveIndicator
			,	tmpMm.HomeID
			,	tmpMm.AwayID
			,	tmpMm.LeagueID                
			,	tmpMm.LeagueName
            ,	tmpMm.Sporttype
			,	tmpMm.BettypeID
            ,	tmpMm.BetID;
	END IF;
                   
END$$
DELIMITER ;

