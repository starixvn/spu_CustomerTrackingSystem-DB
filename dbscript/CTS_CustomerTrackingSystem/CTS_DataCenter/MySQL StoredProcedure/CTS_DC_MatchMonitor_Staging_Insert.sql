/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Staging_Insert`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Staging_Insert`(
		IN ip_LiveIndicator	BOOLEAN 
    ,	IN ip_TransList 	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Insert trans ticket to Staging table
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 152883]
            -	20210719@Casey.Huynh: Fix Issue Rule Trans.StepTime and AssGroup [Redmine ID: 158946]
            -	20210823@Casey.Huynh: Seperate scan for Live and NonLive [Redmine ID: 159195]
            -	20211213@Casey.Huynh: Enhance MM, Add column LeagueName [Redmine ID: 165606]
            -	20220110@Casey.Huynh: Enhance MM, Add SportType, Betteam, BetID [Redmine ID: 166986]
            - 	20220726@Casey.Huynh: Fixed Game [Redmine ID: #175700]
            - 	20220830@Casey.Huynh: New Category for Classify Group Betting [Redmine ID: #176976]
			-	20220815@Casey.Huynh: Scale Out DB [Redmine ID: #176472]
            -	20221021@Casey.Huynh: Fixed Clean Data Staging [Redmine ID: #179427]
            - 	202201021@Casey.Huynh: Seperate pool Staging [Redmine ID: #179439]
            - 	20221115@Casey.Huynh: Detect Irrgation Rule [Redmine ID: #179499]
            
		Param's Explanation (filtered by):		

		Example:
			CALL CTS_DataCenter.CTS_DC_MatchMonitor_Staging_Insert(0,'[{"SportType": 1,"SequenceID": 1003,"IsMajorLeague": 0,"TransID": 1003,"TransDate" : "2021-05-17 07:48:52.533","MatchID" : 43614953,"EventDate" : "2021-05-17 00:00:00","KickOffTime" : "2021-05-17 00:00:00","EventStatus" : "running","HomeID" : 953,"AwayID" : 113,"LeagueID" : 3,"Bettype" : 3, "BetID" : 0,  "LiveIndicator" : "1","CustID" : 12500792,"Stake" : 20,"Betteam" : "a", "Odds" : "0.1","LiveHomeScore" : 0,"LiveAwayScore" : 2,"LeagueName":"ABC League"}]');
			CALL CTS_DataCenter.CTS_DC_MatchMonitor_Staging_Insert(0,'[{"SportType": 0,"SequenceID": 1004,"IsMajorLeague": 0,"TransID": 1004,"TransDate" : "2021-05-17 07:48:52.533","MatchID" : 43614953,"EventDate" : "2021-05-17 00:00:00","KickOffTime" : "2021-05-17 00:00:00","EventStatus" : "running","HomeID" : 953,"AwayID" : 113,"LeagueID" : 3,"Bettype" : 3, "BetID" : 0,  "LiveIndicator" : "1","CustID" : 12500792,"Stake" : 20,"Betteam" : "a", "Odds" : "0.1","LiveHomeScore" : 0,"LiveAwayScore" : 2,"LeagueName":"ABC League"}]');
            
	*/    
    
    DECLARE lv_LastSequenceID BIGINT UNSIGNED DEFAULT 0;

	INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText, JsonString1)
    SELECT'CTS_DC_MatchMonitor_Staging_Insert_xtest1', current_timestamp(),ip_LiveIndicator,ip_TransList;     
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Staging;
	CREATE TEMPORARY TABLE Temp_Staging(
			SequenceID		BIGINT UNSIGNED NOT NULL
		,	TransID			BIGINT UNSIGNED NOT NULL
		,	TransDate		DATETIME(3) DEFAULT NULL
		,	MatchID			INT DEFAULT NULL
		,	SportType		INT DEFAULT NULL
		,	TotalScore		INT DEFAULT NULL
		,	BettypeID		INT DEFAULT NULL
		,	BetID			BIGINT DEFAULT NULL
		,	Betteam			VARCHAR(10)
        ,	Odds			DECIMAL(10,4) DEFAULT NULL
		,	CustID			BIGINT UNSIGNED DEFAULT NULL
		,	Stake			DECIMAL(20,4) DEFAULT NULL
		,	GroupID			INT DEFAULT '0'
		,	LiveHomeScore	INT DEFAULT NULL
		,	LiveAwayScore	INT DEFAULT NULL
		,	EventDate		DATE DEFAULT NULL
		,	KickOffTime		DATETIME DEFAULT NULL
		,	EventStatus		VARCHAR(50)DEFAULT NULL
		,	HomeID			INT DEFAULT NULL
		,	AwayID			INT DEFAULT NULL
		,	LeagueID		INT DEFAULT NULL
		,	LeagueName		VARCHAR(500) DEFAULT NULL
        ,	IsMajorLeague	BOOLEAN
		,	PRIMARY KEY (SequenceID)
	) ENGINE=InnoDB;
	
    INSERT IGNORE INTO Temp_Staging(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, Odds, IsMajorLeague)
		SELECT  js.SequenceID
			,	js.TransID
			,	js.TransDate
            ,	js.LeagueName
            ,	js.SportType
			,	js.MatchID
			,	js.HomeID
			,	js.AwayID
			,	js.EventStatus
			,	js.KickOffTime
			,	js.LeagueID
			,	js.EventDate
			,	(CASE WHEN js.SportType = 2 THEN 0 ELSE js.LiveHomeScore END) AS LiveHomeScore
			,	(CASE WHEN js.SportType = 2 THEN 0 ELSE js.LiveAwayScore END) AS LiveAwayScore
			,	(CASE WHEN js.SportType = 2 THEN 0 ELSE js.LiveHomeScore + js.LiveAwayScore END) AS TotalScore
			,	js.BettypeID
            ,	IFNULL(js.BetID,0)
			,	js.CustID
			,	js.Stake
            ,	js.Betteam
            ,	js.Odds
            ,	js.IsMajorLeague
		FROM JSON_TABLE(ip_TransList,
					 "$[*]" COLUMNS(
								SequenceID		BIGINT UNSIGNED PATH "$.SequenceID" 	
							,	TransID			BIGINT UNSIGNED PATH "$.TransID" 
							,	TransDate		DATETIME(3) PATH "$.TransDate" 
							,	LeagueName		VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci PATH "$.LeagueName"
							,	SportType		INT PATH "$.SportType"
							,	MatchID			INT PATH "$.MatchID"
							,	HomeID			INT	PATH "$.HomeID" 
							,	AwayID			INT	PATH "$.AwayID" 
							,	EventStatus		VARCHAR(50)	PATH "$.EventStatus" 
							,	KickOffTime		DATETIME PATH "$.KickOffTime" 
							,	LeagueID		INT	PATH "$.LeagueID"
							,	EventDate		DATE PATH "$.EventDate"
							,	LiveHomeScore	INT	PATH "$.LiveHomeScore" 
							,	LiveAwayScore	INT	PATH "$.LiveAwayScore" 
							,	BettypeID		INT	PATH "$.Bettype"
							,	BetID			BIGINT	PATH "$.BetID"
							,	CustID			INT PATH "$.CustID"
							,	Stake			DECIMAL(20,4) PATH "$.Stake" 
							,	Betteam			VARCHAR(10)	PATH "$.Betteam"
                            ,	Odds			DECIMAL(10,2) PATH "$.Odds"
                            ,	IsMajorLeague	BOOLEAN	PATH "$.IsMajorLeague" 
						)
					) AS js;  
		
    
    IF ip_LiveIndicator = 1 THEN 
		#=====Staging: Group Betting(Soccer(1), Basketball(2), E-Sport(43)), Hedging(Basketball(2), E-Sport(43)), Arbitrage(Soccer(1), Basketball(2), E-Sport(43)) ================================
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, InsertTime)
		SELECT	tmpSt.SequenceID
			,	tmpSt.TransID
			,	tmpSt.TransDate
			,	tmpSt.LeagueName
			,	tmpSt.SportType
			,	tmpSt.MatchID
			,	tmpSt.HomeID
			,	tmpSt.AwayID
			,	tmpSt.EventStatus
			,	tmpSt.KickOffTime
			,	tmpSt.LeagueID
			,	tmpSt.EventDate
			,	tmpSt.LiveHomeScore
			,	tmpSt.LiveAwayScore
			,	tmpSt.TotalScore
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt;  

        #=====Staging Fixed Game Betting================================
        INSERT IGNORE INTO CTS_DataCenter.MatchMonitorTransLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, Odds, IsMajorLeague, InsertTime)
		SELECT	tmpSt.SequenceID
			,	tmpSt.TransID
			,	tmpSt.TransDate
			,	tmpSt.LeagueName
			,	tmpSt.SportType
			,	tmpSt.MatchID
			,	tmpSt.HomeID
			,	tmpSt.AwayID
			,	tmpSt.EventStatus
			,	tmpSt.KickOffTime
			,	tmpSt.LeagueID
			,	tmpSt.EventDate
			,	tmpSt.LiveHomeScore
			,	tmpSt.LiveAwayScore
			,	tmpSt.TotalScore
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
            ,	tmpSt.Odds
            ,	tmpSt.IsMajorLeague
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
		WHERE tmpSt.IsMajorLeague = 0;
        
        #=====Staging Hedging Soccer================================
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingLive03(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, InsertTime)
		SELECT	tmpSt.SequenceID
			,	tmpSt.TransID
			,	tmpSt.TransDate
			,	tmpSt.LeagueName
			,	tmpSt.SportType
			,	tmpSt.MatchID
			,	tmpSt.HomeID
			,	tmpSt.AwayID
			,	tmpSt.EventStatus
			,	tmpSt.KickOffTime
			,	tmpSt.LeagueID
			,	tmpSt.EventDate
			,	tmpSt.LiveHomeScore
			,	tmpSt.LiveAwayScore
			,	tmpSt.TotalScore
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
		WHERE tmpSt.SportType = 1;   

		#=====UPDATE SYSTEM PARAMETER: THE LAST TRANS GET FROM MAINDB===============================
		SELECT MAX(tmpSt.SequenceID)
		INTO lv_LastSequenceID
		FROM Temp_Staging AS tmpSt;              
            
		IF lv_LastSequenceID > 0 THEN	   
			UPDATE CTS_DataCenter.SystemParameter AS sys
			SET sys.ParameterValue = lv_LastSequenceID
			WHERE sys.ParameterID = 20;
		END IF;        
	ELSE
    	#=====Staging: Group Betting(Soccer(1), Basketball(2), E-Sport(43)), Hedging(Basketball(2), E-Sport(43)), Arbitrage(Soccer(1), Basketball(2), E-Sport(43)) ================================
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingNonLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, InsertTime)
		SELECT	tmpSt.SequenceID
			,	tmpSt.TransID
			,	tmpSt.TransDate
			,	tmpSt.LeagueName
			,	tmpSt.SportType
			,	tmpSt.MatchID
			,	tmpSt.HomeID
			,	tmpSt.AwayID
			,	tmpSt.EventStatus
			,	tmpSt.KickOffTime
			,	tmpSt.LeagueID
			,	tmpSt.EventDate
			,	tmpSt.LiveHomeScore
			,	tmpSt.LiveAwayScore
			,	tmpSt.TotalScore
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt;  
		
        #=====Staging Fixed Game Betting================================
        INSERT IGNORE INTO CTS_DataCenter.MatchMonitorTransNonLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, Odds, IsMajorLeague, InsertTime)
		SELECT	tmpSt.SequenceID
			,	tmpSt.TransID
			,	tmpSt.TransDate
			,	tmpSt.LeagueName
			,	tmpSt.SportType
			,	tmpSt.MatchID
			,	tmpSt.HomeID
			,	tmpSt.AwayID
			,	tmpSt.EventStatus
			,	tmpSt.KickOffTime
			,	tmpSt.LeagueID
			,	tmpSt.EventDate
			,	tmpSt.LiveHomeScore
			,	tmpSt.LiveAwayScore
			,	tmpSt.TotalScore
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
            ,	tmpSt.Odds
            ,	tmpSt.IsMajorLeague
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
		WHERE tmpSt.IsMajorLeague = 0;
        
        #=====Staging Hedging Soccer================================
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingNonLive03(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, InsertTime)
		SELECT	tmpSt.SequenceID
			,	tmpSt.TransID
			,	tmpSt.TransDate
			,	tmpSt.LeagueName
			,	tmpSt.SportType
			,	tmpSt.MatchID
			,	tmpSt.HomeID
			,	tmpSt.AwayID
			,	tmpSt.EventStatus
			,	tmpSt.KickOffTime
			,	tmpSt.LeagueID
			,	tmpSt.EventDate
			,	tmpSt.LiveHomeScore
			,	tmpSt.LiveAwayScore
			,	tmpSt.TotalScore
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
		WHERE tmpSt.SportType = 1;   
        
        #=====Staging - Irrigation - Soccer================================
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingIrrigationNonLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, Odds, InsertTime)
		SELECT	tmpSt.SequenceID
			,	tmpSt.TransID
			,	tmpSt.TransDate
			,	tmpSt.LeagueName
			,	tmpSt.SportType
			,	tmpSt.MatchID
			,	tmpSt.HomeID
			,	tmpSt.AwayID
			,	tmpSt.EventStatus
			,	tmpSt.KickOffTime
			,	tmpSt.LeagueID
			,	tmpSt.EventDate
			,	tmpSt.LiveHomeScore
			,	tmpSt.LiveAwayScore
			,	tmpSt.TotalScore
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
            ,	tmpSt.Odds
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
		WHERE tmpSt.SportType = 1;   
        
		#=====UPDATE SYSTEM PARAMETER: THE LAST TRANS GET FROM MAINDB===============================
		SELECT MAX(tmpSt.SequenceID)
		INTO lv_LastSequenceID
		FROM Temp_Staging AS tmpSt;              
            
		IF lv_LastSequenceID > 0 THEN	   
			UPDATE CTS_DataCenter.SystemParameter AS sys
			SET sys.ParameterValue = lv_LastSequenceID
			WHERE sys.ParameterID = 29;
		END IF;
        
	END IF;
    
END$$
DELIMITER ;