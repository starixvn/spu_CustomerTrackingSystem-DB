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
            - 	20221206@Casey.Huynh: Change Table Nane, ScoreDiff and add HDP, Odds range for Fixed Game [Redmine ID: #181205]
			- 	20221228@Victoria.Le: Add HDP for Irrgation Rule [Redmine ID: #181990]
			-	20230203@Victoria.Le: Change Odds Range for Fixed Game Rule - Malayisan Odds [Redmine ID: #183277]
            -	20231120@Casey.Huynh: E-Sport GB support New Bettypes, change setting table [Redmine ID: #196396]
            -	20240109@Casey.Huynh: Enhance Hedging Rule, execlute Licensee Cust and Limit stake [Redmine ID: #192172]
            
		Param's Explanation (filtered by):		

		Example:
			CALL CTS_DataCenter.CTS_DC_MatchMonitor_Staging_Insert(0,'[{"SportType": 1,"SequenceID": 1003,"IsMajorLeague": 0,"TransID": 1003,"TransDate" : "2021-05-17 07:48:52.533","MatchID" : 43614953,"EventDate" : "2021-05-17 00:00:00","KickOffTime" : "2021-05-17 00:00:00","EventStatus" : "running","HomeID" : 953,"AwayID" : 113,"LeagueID" : 3,"Bettype" : 3, "BetID" : 0,  "LiveIndicator" : "1","CustID" : 12500792,"Stake" : 20,"Betteam" : "a", "Odds" : "0.1","LiveHomeScore" : 0,"LiveAwayScore" : 2,"LeagueName":"ABC League"}]');
			
	*/
    DECLARE CONS_LOG 						TINYINT DEFAULT 0; #0:LogOff, 1:LogOn
	DECLARE CONST_RULE_GROUPID_GROUPBETTING	INT DEFAULT 1;
    DECLARE CONST_RULE_GROUPID_FIXEDGAME	INT DEFAULT 2;
    DECLARE CONST_RULE_GROUPID_HEDGING		INT DEFAULT 3;
    DECLARE CONST_RULE_GROUPID_IRRIGATION	INT DEFAULT 4;
    DECLARE CONST_RULE_GROUPID_ARBITRAGE	INT DEFAULT 5;
    
    DECLARE lv_LastSequenceID 			BIGINT UNSIGNED DEFAULT 0; 
    DECLARE lv_Rule_FixedGame_MinOdds	DECIMAL(10,4);
    DECLARE lv_Rule_FixedGame_MaxOdds	DECIMAL(10,4);
    
    #==================LOG=======================================================
    DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_Staging_Insert';
    IF CONS_LOG = 1 THEN     
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), CONCAT('@ip_LiveIndicator:=',ip_LiveIndicator);
    END IF;
    #==================LOG=======================================================   
    #==========================================================================
    #Error Code: 1054. Unknown column 'tmpSt.CTSCustID' in 'field list'

    DROP TEMPORARY TABLE IF EXISTS Temp_Staging;
	CREATE TEMPORARY TABLE Temp_Staging(
			SequenceID		BIGINT UNSIGNED NOT NULL
		,	SportType		INT NOT NULL
        ,	IsMajorLeague	BOOLEAN NOT NULL
        ,	Odds			DECIMAL(10,4) NOT NULL
		,	TransID			BIGINT UNSIGNED NOT NULL
		,	TransDate		DATETIME(3) NULL
		,	MatchID			INT NULL		
		,	ScoreDiff		INT NULL
		,	BettypeID		INT NULL
		,	BetID			BIGINT NULL
		,	Betteam			VARCHAR(10) NULL        
		,	CustID			BIGINT UNSIGNED NULL
		,	Stake			DECIMAL(20,4) NULL
		,	GroupID			INT DEFAULT '0'
		,	LiveHomeScore	INT NULL
		,	LiveAwayScore	INT NULL
		,	EventDate		DATE NULL
		,	KickOffTime		DATETIME NULL
		,	EventStatus		VARCHAR(50) NULL
		,	HomeID			INT NULL
		,	AwayID			INT NULL
		,	LeagueID		INT NULL
		,	LeagueName		VARCHAR(500) NULL        
        ,	HDP				DECIMAL(8,4) NULL
        ,	Hdp1			DECIMAL(8,4) NULL
        ,	Hdp2			DECIMAL(8,4) NULL
		,	PRIMARY KEY (SportType, IsMajorLeague, Odds, SequenceID)
		,	INDEX SequenceID(SequenceID)
	) ENGINE=InnoDB;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitorRuleSetting;
    CREATE TEMPORARY TABLE Temp_MatchMonitorRuleSetting(
			RuleGroupID TINYINT 
		,	SportType 	INT
        ,	BettypeID	INT
		,	LeagueType 	BOOLEAN
		,	MinOdds 	DECIMAL(10,4) 
		,	MaxOdds 	DECIMAL(10,4)
        ,	MinStake	DECIMAL(20,4) NULL
        
        ,	PRIMARY KEY PK_Temp_MatchMonitorRuleSetting(RuleGroupID, SportType, BettypeID, LeagueType)
        
	);
    
    INSERT INTO Temp_MatchMonitorRuleSetting(RuleGroupID, SportType, BettypeID, LeagueType,  MinOdds, MaxOdds, MinStake)
    SELECT 	mst.RuleGroupID
		,	mst.SportType
        ,	tmp.BettypeID
		,	mst.LeagueType
		,	mst.MinOdds
        ,	mst.MaxOdds
        ,	mst.HighStake
    FROM (	SELECT sbs.SportTypeID, sbs.BetTypeID, js.Reason 
			FROM CTS_DataCenter.SportBettypeSetting AS sbs
			, JSON_TABLE(CONCAT('["', REPLACE(IFNULL(MMReason,''), ',', '","'), '"]'),
								  '$[*]' COLUMNS (Reason VARCHAR(2) PATH '$')) js) AS tmp
		 INNER JOIN CTS_DataCenter.MatchMonitorRuleSetting AS mst ON mst.SportType = tmp.SportTypeID AND mst.Reason = tmp.Reason; 
    
    INSERT IGNORE INTO Temp_Staging(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, ScoreDiff, BettypeID, BetID, CustID, Stake, Betteam, Odds, IsMajorLeague, HDP, Hdp1, Hdp2)
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
			,	(CASE WHEN js.SportType = 2 THEN 0 ELSE (js.LiveHomeScore*10000) + js.LiveAwayScore END) AS ScoreDiff
			,	js.BettypeID
            ,	IFNULL(js.BetID,0)
			,	js.CustID
			,	js.Stake
            ,	js.Betteam
            ,	js.Odds
            ,	js.IsMajorLeague
            ,	(js.Hdp1 - js.Hdp2) AS HDP
            ,	js.Hdp1
            ,	js.Hdp2
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
                            ,	Odds			DECIMAL(10,4) PATH "$.Odds"
                            ,	IsMajorLeague	BOOLEAN	PATH "$.IsMajorLeague" 
                            ,	Hdp1			DECIMAL(8,4) PATH "$.Hdp1" 
                            ,	Hdp2			DECIMAL(8,4) PATH "$.Hdp2" 
						)
					) AS js;  

    IF ip_LiveIndicator = 1 THEN 
		#=====GROUP BETTING===================
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingGroupBettingLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, ScoreDiff, BettypeID, BetID, CustID, Stake, Betteam, Odds, IsMajorLeague, Hdp1, Hdp2, HDP, InsertTime)
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
			,	tmpSt.ScoreDiff
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
            ,	tmpSt.Odds
            ,	tmpSt.IsMajorLeague            
            ,	tmpSt.Hdp1
            ,	tmpSt.Hdp2
            ,	tmpSt.HDP
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpMst ON  tmpMst.RuleGroupID = CONST_RULE_GROUPID_GROUPBETTING
																AND tmpMst.SportType = tmpSt.SportType 
																AND (tmpMst.LeagueType = 2 OR (tmpMst.LeagueType = tmpSt.IsMajorLeague))
																AND tmpMst.BettypeID = tmpSt.BettypeID;  

        #=====Staging Fixed Game Betting================================
        INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingFixedGameLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, ScoreDiff, BettypeID, BetID, CustID, Stake, Betteam, Odds, IsMajorLeague, Hdp1, Hdp2, HDP, InsertTime)
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
			,	tmpSt.ScoreDiff
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
            ,	tmpSt.Odds
            ,	tmpSt.IsMajorLeague
            ,	tmpSt.Hdp1
            ,	tmpSt.Hdp2
            ,	tmpSt.HDP
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpMst ON  tmpMst.RuleGroupID = CONST_RULE_GROUPID_FIXEDGAME
						AND tmpMst.SportType = tmpSt.SportType AND (tmpMst.LeagueType = 2 OR (tmpMst.LeagueType = tmpSt.IsMajorLeague))
                        AND tmpMst.BettypeID = tmpSt.BettypeID  
                        AND ABS(tmpSt.Odds) >= tmpMst.MinOdds;

        #=====Staging Hedging Soccer Live================================
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingHedgingLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, ScoreDiff, BettypeID, BetID, CustID
        , CTSCustID, SubscriberID, Stake, Betteam, InsertTime)
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
			,	tmpSt.ScoreDiff
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
            ,	cus.CTSCustID 
            ,	cus.SubscriberID
			,	tmpSt.Stake
			,	tmpSt.Betteam
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON tmpSt.CustID = cus.CustID
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpMst ON  tmpMst.RuleGroupID = CONST_RULE_GROUPID_HEDGING
																AND tmpMst.SportType = tmpSt.SportType 
                                                                AND (tmpMst.LeagueType = 2 OR (tmpMst.LeagueType = tmpSt.IsMajorLeague))
																AND tmpMst.BettypeID = tmpSt.BettypeID
		WHERE tmpSt.Stake >= tmpMst.MinStake AND cus.IsLicensee = 0;     

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
        #=====GROUP BETTING===================
        
        INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingGroupBettingNonLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, ScoreDiff, BettypeID, BetID, CustID, Stake, Betteam,	Odds, IsMajorLeague, Hdp1, Hdp2, HDP, InsertTime)
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
			,	tmpSt.ScoreDiff
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
            ,	tmpSt.Odds
            ,	tmpSt.IsMajorLeague            
            ,	tmpSt.Hdp1
            ,	tmpSt.Hdp2
            ,	tmpSt.HDP
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpMst ON  tmpMst.RuleGroupID = CONST_RULE_GROUPID_GROUPBETTING
																AND tmpMst.SportType = tmpSt.SportType 
																AND (tmpMst.LeagueType = 2 OR (tmpMst.LeagueType = tmpSt.IsMajorLeague))
																AND tmpMst.BettypeID = tmpSt.BettypeID;

        #=====Staging Fixed Game Betting================================
        
        INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingFixedGameNonLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, ScoreDiff, BettypeID, BetID, CustID, Stake, Betteam, Odds, IsMajorLeague, Hdp1, Hdp2, HDP, InsertTime)
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
			,	tmpSt.ScoreDiff
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
            ,	tmpSt.Odds
            ,	tmpSt.IsMajorLeague
            ,	tmpSt.Hdp1
            ,	tmpSt.Hdp2
            ,	tmpSt.HDP
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpMst ON  tmpMst.RuleGroupID = CONST_RULE_GROUPID_FIXEDGAME
													AND tmpMst.SportType = tmpSt.SportType 
													AND (tmpMst.LeagueType = 2 OR (tmpMst.LeagueType = tmpSt.IsMajorLeague))
													AND tmpMst.BettypeID = tmpSt.BettypeID
													AND ABS(tmpSt.Odds) >= tmpMst.MinOdds;     
                                                    
		#=====Staging Hedging Soccer Live================================
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingHedgingNonLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, ScoreDiff, BettypeID, BetID, CustID, CTSCustID, SubscriberID, Stake, Betteam, InsertTime)
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
			,	tmpSt.ScoreDiff
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
            ,	cus.CTSCustID 
            ,	cus.SubscriberID
			,	tmpSt.Stake
			,	tmpSt.Betteam
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
			INNER JOIN CTS_DataCenter.CTSCustomer cus ON tmpSt.CustID = cus.CustID
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpMst ON  tmpMst.RuleGroupID = CONST_RULE_GROUPID_HEDGING
																AND tmpMst.SportType = tmpSt.SportType 
                                                                AND (tmpMst.LeagueType = 2 OR (tmpMst.LeagueType = tmpSt.IsMajorLeague))
																AND tmpMst.BettypeID = tmpSt.BettypeID
		WHERE tmpSt.Stake >= tmpMst.MinStake AND cus.IsLicensee = 0;        

        #=====Staging - Irrigation - Soccer================================        

		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingIrrigationNonLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, ScoreDiff, BettypeID, BetID, CustID, Stake, Betteam, Odds, Hdp, InsertTime)
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
			,	tmpSt.ScoreDiff
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
            ,	tmpSt.Odds
            ,	tmpSt.HDP
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpMst ON  tmpMst.RuleGroupID = CONST_RULE_GROUPID_IRRIGATION
													AND tmpMst.SportType = tmpSt.SportType 
													AND (tmpMst.LeagueType = 2 OR (tmpMst.LeagueType = tmpSt.IsMajorLeague))
													AND tmpMst.BettypeID = tmpSt.BettypeID;     
		
        #=====Staging - Arbitrage - Soccer================================
        
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingArbitrageNonLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, ScoreDiff, BettypeID, BetID, CustID, Stake, Betteam, IsMajorLeague, Hdp1, Hdp2, HDP, InsertTime)
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
			,	tmpSt.ScoreDiff
			,	tmpSt.BettypeID
			,	tmpSt.BetID
			,	tmpSt.CustID
			,	tmpSt.Stake
			,	tmpSt.Betteam
            ,	tmpSt.IsMajorLeague
            ,	tmpSt.Hdp1
            ,	tmpSt.Hdp2
            ,	tmpSt.HDP
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_Staging AS tmpSt
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpMst ON  tmpMst.RuleGroupID = CONST_RULE_GROUPID_ARBITRAGE
													AND tmpMst.SportType = tmpSt.SportType 
													AND (tmpMst.LeagueType = 2 OR (tmpMst.LeagueType = tmpSt.IsMajorLeague))
													AND tmpMst.BettypeID = tmpSt.BettypeID;       

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