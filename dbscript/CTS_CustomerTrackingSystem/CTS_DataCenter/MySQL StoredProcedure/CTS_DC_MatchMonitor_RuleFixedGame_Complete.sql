/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleFixedGame_Complete`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleFixedGame_Complete`(
		IN ip_LiveIndicator BOOLEAN
	,	IN ip_MaxSequenceID BIGINT UNSIGNED
	, 	IN ip_MatchID		INT
    , 	IN ip_TotalScore	INT 
    , 	IN ip_BettypeID		INT
    ,	IN ip_BetID			BIGINT
    ,	IN ip_Betteam		VARCHAR(10)
    , 	IN ip_TransGroup	JSON
)
  SQL SECURITY INVOKER
	BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220726@Casey.Huynh: Created [Redmine ID: #175700]
            - 20220815@Casey.Huynh: Scale Out DB [Redmine ID: #176472]
            
		Param's Explanation (filtered by):	

		Example:
			CALL CTS_DC_MatchMonitor_RuleFixedGame_Complete(@ip_LiveIndicator:=1,@ip_MaxSequenceID:=115841606929,@ip_MatchID:=1,@ip_TotalScore:=1
				,@ip_BettypeID:=1,@ip_BetID:=0,@ip_Betteam:='a',
                @ip_TransGroup:='[{"Reason":3 ,"TransIDList":"1001,1007,1008","CustIDList":"1,2"}]');
	*/ 
    DECLARE	lv_KickOffTime 			DATETIME;
    DECLARE	lv_EventStatus 			VARCHAR(50);
    DECLARE lv_HomeID 				INT UNSIGNED;
    DECLARE lv_AwayID 				INT UNSIGNED;
    DECLARE lv_LeagueID				INT UNSIGNED;
    DECLARE lv_LeagueName			VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE	lv_Sporttype			INT;
    DECLARE	lv_DetailsTransIDList	TEXT;
    DECLARE	lv_DetailsCustIDList	TEXT;
    DECLARE	lv_DetailsID			INT;
	DECLARE lv_EventDate 			DATE;
    DECLARE lv_LiveHomeScore		SMALLINT UNSIGNED;
    DECLARE lv_LiveAwayScore		SMALLINT UNSIGNED;
    DECLARE lv_MaxTransDate			DATETIME(3);	
    DECLARE	lv_NewTransIDList		TEXT;
    DECLARE	lv_NewCustIDList		TEXT;
    DECLARE	lv_Rule_Duration		SMALLINT DEFAULT 7;
    
    DECLARE	CONST_GROUPID			TINYINT DEFAULT 0;
	DECLARE	CONST_REASON_FIXEDGAME	TINYINT DEFAULT 3; #0: Group Betting, 1: Headging, 2: Arbitrage, 3: FixedGame    
        
    DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;
    CREATE TEMPORARY TABLE Temp_TransGroup
    (
			Reason 			TINYINT
        ,	TransIDList 	LONGTEXT
        ,	CustIDList		LONGTEXT 
    );
    
    SELECT s.ParameterValue INTO lv_Rule_Duration FROM CTS_DataCenter.SystemParameter AS s WHERE s.ParameterID = 107;
    
    INSERT IGNORE INTO Temp_TransGroup(Reason, TransIDList, CustIDList)
	SELECT 	js.Reason
		,	js.TransIDList
		,	js.CustIDList
	FROM JSON_TABLE(ip_TransGroup,
					 "$[*]" COLUMNS(
								Reason			TINYINT PATH "$.Reason" 
							,	TransIDList		LONGTEXT PATH "$.TransIDList"
							,	CustIDList		LONGTEXT PATH "$.CustIDList" 
						)
				) AS js;     
                
	SELECT 	tmpTg.TransIDList, tmpTg.CustIDList
    INTO 	lv_NewTransIDList, lv_NewCustIDList
	FROM 	Temp_TransGroup AS tmpTg;	
    
	IF lv_NewTransIDList IS NOT NULL THEN	
		#======Update MatchMonitorDetails====================================     
		IF (ip_LiveIndicator = 1) THEN 
		
			SELECT mms.EventDate, mms.LiveHomeScore, mms.LiveAwayScore, mms.EventDate, mms.KickOffTime, mms.EventStatus, mms.HomeID, mms.AwayID, mms.LeagueID, mms.LeagueName, mms.Sporttype
			INTO lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, lv_LeagueName, lv_Sporttype
			FROM CTS_DataCenter.MatchMonitorStagingFixedGameLive AS mms
			WHERE mms.SequenceID <= ip_MaxSequenceID AND mms.MatchID = ip_MatchID AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.TotalScore = ip_TotalScore AND mms.Betteam = ip_Betteam
			LIMIT 1;
			
		END IF;

		IF (ip_LiveIndicator = 0) THEN
			SELECT mms.EventDate, mms.LiveHomeScore, mms.LiveAwayScore, mms.EventDate, mms.KickOffTime, mms.EventStatus, mms.HomeID, mms.AwayID, mms.LeagueID, mms.LeagueName, mms.Sporttype
			INTO lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, lv_LeagueName, lv_Sporttype
			FROM CTS_DataCenter.MatchMonitorStagingFixedGameNonLive AS mms
			WHERE mms.SequenceID <= ip_MaxSequenceID AND mms.MatchID = ip_MatchID AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.Betteam = ip_Betteam
			LIMIT 1;	 
		END IF;	
		
		SELECT 	mmd.ID, mmd.ListTransID, mmd.ListCustID
		INTO 	lv_DetailsID, lv_DetailsTransIDList, lv_DetailsCustIDList
		FROM 	CTS_DataCenter.MatchMonitorDetails AS mmd
		WHERE 	mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID
			AND mmd.BetID = ip_BetID AND mmd.TotalScore = ip_TotalScore AND mmd.Betteam = ip_Betteam AND mmd.Reason = CONST_REASON_FIXEDGAME;
			
		
		IF (lv_DetailsID IS NOT NULL) THEN
			
			DROP TEMPORARY TABLE IF EXISTS Temp_DetailsTransIDList;
			CREATE TEMPORARY TABLE Temp_DetailsTransIDList(
				TransID BIGINT UNSIGNED PRIMARY KEY
			);
		
			DROP TEMPORARY TABLE IF EXISTS Temp_DetailsCustIDList;
			CREATE TEMPORARY TABLE Temp_DetailsCustIDList(
				CustID INT UNSIGNED PRIMARY KEY
			);
			
			SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_DetailsTransIDList (TransID) VALUES ('", REPLACE(lv_DetailsTransIDList, ",", "'),('"),"');");
			PREPARE 	stmt1 FROM @sql;
			EXECUTE 	stmt1;   
			
			SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_DetailsTransIDList (TransID) VALUES ('", REPLACE(lv_NewTransIDList, ",", "'),('"),"');");
			PREPARE 	stmt1 FROM @sql;
			EXECUTE 	stmt1;
			
			SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_DetailsCustIDList (CustID) VALUES ('", REPLACE(lv_DetailsCustIDList, ",", "'),('"),"');");
			PREPARE 	stmt1 FROM @sql;
			EXECUTE 	stmt1; 
			
			SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_DetailsCustIDList (CustID) VALUES ('", REPLACE(lv_NewCustIDList, ",", "'),('"),"');");
			PREPARE 	stmt1 FROM @sql;
			EXECUTE 	stmt1;  		
		
			UPDATE CTS_DataCenter.MatchMonitorDetails AS mmd
				INNER JOIN Temp_TransGroup AS tmpTg ON mmd.Reason = tmpTg.Reason
			SET 	mmd.ListCustID = (SELECT GROUP_CONCAT(tmp.CustID) FROM Temp_DetailsCustIDList AS tmp)
				,	mmd.ListTransID = (SELECT GROUP_CONCAT(tmp.TransID) FROM Temp_DetailsTransIDList AS tmp)
			WHERE mmd.ID = lv_DetailsID;
			
		ELSE  
			INSERT IGNORE INTO CTS_DataCenter.MatchMonitorDetails(MatchID, LiveIndicator, TotalScore, BettypeID, BetID, Betteam, EventDate, LiveHomeScore, LiveAwayScore, ListCustID, ListTransID, Reason, GroupID)
			SELECT ip_MatchID, ip_LiveIndicator, ip_TotalScore, ip_BettypeID, ip_BetID, ip_Betteam, lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore
				,	tmpTg.CustIDList, tmpTg.TransIDList, tmpTg.Reason, CONST_GROUPID
			FROM 	Temp_TransGroup AS tmpTg;
				
			INSERT IGNORE INTO CTS_DataCenter.MatchMonitor(MatchID, BettypeID, BetID, LiveIndicator, EventDate, KickOffTime, EventStatus, HomeID, AwayID, LeagueID, LeagueName, Sporttype, Reason)
			SELECT	ip_MatchID, ip_BettypeID, ip_BetID, ip_LiveIndicator, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, lv_LeagueName, lv_Sporttype
				,	tmpTg. Reason
			FROM Temp_TransGroup AS tmpTg;
			
		END IF;
	
    END IF;
    
	IF (ip_LiveIndicator = 1) THEN
		
        SELECT MAX(TransDate)
		INTO lv_MaxTransDate
		FROM CTS_DataCenter.MatchMonitorStagingFixedGameLive AS mmt
		WHERE mmt.SequenceID = ip_MaxSequenceID;   
        
		UPDATE CTS_DataCenter.MatchMonitorStagingFixedGameLive AS mmt
		SET mmt.StatusRule02 = 1
		WHERE mmt.TransDate <= TIMESTAMPADD(MINUTE,-lv_Rule_Duration,lv_MaxTransDate)
			AND mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam;
        
	END IF;

	IF (ip_LiveIndicator = 0) THEN
    
		SELECT MAX(TransDate)
		INTO lv_MaxTransDate
		FROM CTS_DataCenter.MatchMonitorStagingFixedGameNonLive AS mmt
		WHERE mmt.SequenceID = ip_MaxSequenceID;   
        
		UPDATE CTS_DataCenter.MatchMonitorStagingFixedGameNonLive AS mmt
		SET mmt.StatusRule02 = 1
		WHERE mmt.TransDate <= TIMESTAMPADD(MINUTE,-lv_Rule_Duration,lv_MaxTransDate)
			AND mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam;
            
	END IF;	    
   
    
END$$
DELIMITER ;