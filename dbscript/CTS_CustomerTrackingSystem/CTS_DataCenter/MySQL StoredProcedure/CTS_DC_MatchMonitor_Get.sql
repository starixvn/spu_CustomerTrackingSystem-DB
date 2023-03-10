/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Get`(
		IN	ip_MatchInfos		JSON			# MatchID, EventDate, KickOffTime, MatchSection
	,	IN 	ip_FromDate 		DATETIME
    ,	IN 	ip_ToDate 			DATETIME
    ,	IN	ip_SportType		VARCHAR(500)
    , 	IN	ip_Market 			TINYINT			# NULL if Both (Live and NonLive))
    ,	IN 	ip_IsVerified 		TINYINT(1)
    ,	IN 	ip_Bettypes 		JSON 			# BettypeID and BetID       
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
			- 	20210526@Long.Luu: 		Created [Redmine ID: 152883]
			-	20210823@Casey.Huynh: 	Return Market value [Redmine ID: 159195]
			- 	20220107@Casey.Huynh: 	Fix Issue get data for Verified Trans [Redmine ID: 167192]
			-	20211213@Casey.Huynh: 	Enhance MM, Add column LeagueName, reset IsVerified = 0 [Redmine ID: 165606]
			-	20220110@Casey.Huynh: 	Enhance MM, BetID, Reason [Redmine ID: 166986]
			- 	20220216@Casey.Huynh: 	Fix Issue, show IsVerified = 0 when all tickets were verified [Redmine ID: 166986]
			- 	20220325@Long.Luu: 		Add Reason filter [Redmine ID: 170466]
			-	20220805@Jonas.Huynh: 	Add Reason Fixed Game [Redmine ID: 175700]
			-	20221027@Casey.Huynh: 	Update Verify By Reason and Betteam [RedmineID: 179439]
			-	20230105@Casey.Huynh: 	Add search by InsertDate and remove ip_LeagueName [Redmine ID: #181995]
			-	20230214@Victoria.Le	Add ip_MatchInfos to get latest EventDate and KickOffTime (GolobalShowTime) when search by EventDate 
										Remove ip_DateType, ip_MatchSection [RedmineID: #183280]
			
            
		Param's Explanation (filtered by):
			- ip_Market: 		0 return LiveIndicator = 0, 1 return LiveIndicator = 1, NULL: Both Live And Non-Live
            - ip_Reason: 		0:Group Betting, 1: Hedging, 2: Arbitrage, 3: Fixed Game
			- ip_MatchInfos: 	= NULL: search by InsertDate
								<> NULL: search by EventDate
		Example:
			-	CALL CTS_DC_MatchMonitor_Get_xtest(@ip_MatchInfos:=NULL,@ip_FromDate:='2023-01-05',@ip_ToDate:='2023-01-8',@ip_SportType:=1,@ip_Market:=1,@ip_MatchSection:='1,2,3,4',@ip_IsVerified:=NULL
				,@ip_Bettypes:='[{"BettypeID":1,"BetID":0},{"BettypeID":3,"BetID":0},{"BettypeID":7,"BetID":0}]',@ip_Reason:='0,1,2');
	*/
	
	DECLARE lv_IsLog TINYINT DEFAULT 0;    
	DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_Get';
    DECLARE lv_LogInfo TEXT;
	
	#==================LOG=======================================================
	IF lv_IsLog = 1 THEN
		SET lv_LogInfo = CONCAT('@ip_FromDate:=''',IFNULL(ip_FromDate,'NULL'),''''
								,',@ip_ToDate:=''',IFNULL(ip_ToDate,'NULL'),''''
								,',@ip_SportType:=''',IFNULL(ip_SportType,'NULL'),''''
								,',@ip_Market:=''',IFNULL(ip_Market,'NULL'),''''
								,',@ip_IsVerified:=''',IFNULL(ip_IsVerified,'NULL'),''''
								,',@ip_Bettypes:=''',IFNULL(ip_Bettypes,'NULL'),''''
								,',@ip_Reason:=''',IFNULL(ip_Reason,'NULL'),'''');
		
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText, JsonString1)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), lv_LogInfo, ip_MatchInfos; 
	END IF;  
	#==================LOG=======================================================  
      
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
        ,	MatchSection	INT DEFAULT NULL
        ,	KickOffTime		DATETIME DEFAULT NULL
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
        
        ,	PRIMARY KEY PK_Temp_MatchTrans(MatchID,LiveIndicator,BettypeID, BetID)
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
    
    SET @sql = CONCAT("INSERT INTO Temp_Sporttype (Sporttype) VALUES ('", REPLACE(ip_Sporttype, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1; 
    
    SET @sql = CONCAT("INSERT INTO Temp_Reason (ReasonID) VALUES ('", REPLACE(ip_Reason, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1; 
    
    IF (IFNULL(ip_MatchInfos,'') = '') THEN # Search by Insert Date
		INSERT INTO Temp_MatchMonitor(ID, MatchID, EventDate, LiveIndicator, HomeID, AwayID, LeagueID, LeagueName, Sporttype, BettypeID, BetID, Reason)    
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
		FROM   CTS_DataCenter.MatchMonitor AS s
			INNER JOIN Temp_Bettype AS tmpBt ON s.BettypeID = tmpBt.BettypeID AND s.BetID = tmpBt.BetID
			INNER JOIN Temp_Sporttype AS tmpSt ON s.Sporttype = tmpSt.SportType
			INNER JOIN Temp_Reason AS r ON r.ReasonID = s.Reason
		WHERE s.InsertDate BETWEEN ip_FromDate AND ip_ToDate
			AND s.LiveIndicator = IFNULL(ip_Market, s.LiveIndicator);
    ELSE #ip_MatchInfos <> '' THEN # Search by Event Date
		
		DROP TEMPORARY TABLE IF EXISTS Temp_MatchInfo;
		CREATE TEMPORARY TABLE Temp_MatchInfo(
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
            
			,	INDEX IDX_Temp_MatchInfo(MatchID,BettypeID,BetID)
		);
		
		INSERT IGNORE INTO Temp_MatchInfo (ID, MatchID, EventDate, LiveIndicator, HomeID, AwayID, LeagueID, LeagueName, Sporttype, BettypeID, BetID, Reason, MatchSection, KickOffTime)
		SELECT  s.ID
			,	js.MatchId
			,	js.EventDate
			,	s.LiveIndicator
			,	s.HomeID
			,	s.AwayID
			,	s.LeagueID                
			,	s.LeagueName
			,	s.Sporttype
			,	s.BettypeID
			,	s.BetID
			,	s.Reason		# 0:Group Betting, 1: Hedging, 2: Arbitrage, 3: Fixed Game
			,	js.MatchSection
			, 	js.KickOffTime
		FROM CTS_DataCenter.MatchMonitor AS s
			INNER JOIN JSON_TABLE(ip_MatchInfos,
									 "$[*]" COLUMNS(
												MatchId			INT			PATH "$.MatchId"
											,	EventDate		DATETIME	PATH "$.EventDate"
											,	KickOffTime		DATETIME	PATH "$.KickOffTime"
											,	MatchSection	TINYINT		PATH "$.MatchSection"
										)
								) AS js ON js.MatchId = s.MatchId
			INNER JOIN Temp_Bettype AS tmpBt ON s.BettypeID = tmpBt.BettypeID AND s.BetID = tmpBt.BetID
			INNER JOIN Temp_Reason AS r ON r.ReasonID = s.Reason
		WHERE s.LiveIndicator = IFNULL(ip_Market, s.LiveIndicator);
	
		INSERT INTO Temp_MatchMonitor(ID, MatchID, EventDate, LiveIndicator, HomeID, AwayID, LeagueID, LeagueName, Sporttype, BettypeID, BetID, Reason, MatchSection, KickOffTime)    
		SELECT 	tmpMi.ID
			,	tmpMi.MatchID
			,	tmpMi.EventDate
			,	tmpMi.LiveIndicator
			,	tmpMi.HomeID
			,	tmpMi.AwayID
			,	tmpMi.LeagueID                
			,	tmpMi.LeagueName
			,	tmpMi.Sporttype
			,	tmpMi.BettypeID
			,	tmpMi.BetID
			,	tmpMi.Reason		# 0:Group Betting, 1: Hedging, 2: Arbitrage, 3: Fixed Game
			,	tmpMi.MatchSection
			, 	tmpMi.KickOffTime
		FROM   Temp_MatchInfo AS tmpMi 
			INNER JOIN Temp_Sporttype AS tmpSt ON tmpMi.Sporttype = tmpSt.SportType;
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
		LEFT JOIN Temp_VerfiedTrans AS tmpVt ON tmpVt.MatchID = tmpMm.MatchID AND tmpVt.LiveIndicator = tmpMm.LiveIndicator AND tmpVt.BettypeID = tmpMm.BettypeID AND tmpVt.BetID = tmpMm.BetID 
	GROUP BY MatchID, LiveIndicator, BettypeID, BetID, Reason; 

	INSERT INTO Temp_MatchGroup_NotVerified(MatchID, LiveIndicator, BettypeID, BetID)
    SELECT DISTINCT	tmpMg.MatchID
		,	tmpMg.LiveIndicator
		,	tmpMg.BettypeID
        ,	tmpMg.BetID
    FROM Temp_MatchGroup AS tmpMg
		INNER JOIN CTS_DataCenter.MatchMonitorDetails AS mmd ON tmpMg.MatchID = mmd.MatchID AND tmpMg.LiveIndicator = mmd.LiveIndicator
				AND tmpMg.BettypeID = mmd.BettypeID AND tmpMg.BetID = mmd.BetID
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(mmd.ListTransID), ',', '","'), 
						'$[*]' COLUMNS (TransID BIGINT UNSIGNED PATH '$')
						) js
	WHERE NOT EXISTS (SELECT 1 FROM Temp_VerfiedTrans AS tmpVt WHERE js.TransID = tmpVt.TransID);    

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
			,	NOT EXISTS(SELECT 1 FROM Temp_MatchGroup_NotVerified AS tmpNv WHERE tmpMm.MatchID = tmpNv.MatchID AND tmpMm.LiveIndicator = tmpNv.LiveIndicator 
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
			,	0 AS IsVerified
            ,	GROUP_CONCAT(DISTINCT tmpMg.VerifiedBy)	AS VerifiedBy
		FROM Temp_MatchMonitor AS tmpMm
		INNER JOIN Temp_MatchGroup AS tmpMg ON tmpMm.MatchID = tmpMg.MatchID AND tmpMm.LiveIndicator = tmpMg.LiveIndicator 
					AND tmpMm.BettypeID = tmpMg.BettypeID AND tmpMm.BetID = tmpMg.BetID AND tmpMm.Reason = tmpMg.Reason
		WHERE EXISTS(SELECT 1 FROM Temp_MatchGroup_NotVerified AS tmpNv WHERE tmpMm.MatchID = tmpNv.MatchID AND tmpMm.LiveIndicator = tmpNv.LiveIndicator 
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

