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
            
		Param's Explanation (filtered by):		

		Example:
			CALL CTS_DataCenter.CTS_DC_MatchMonitor_Staging_Insert(1,'[{"SequenceID": 1, "TransID": 100,"TransDate" : "2021-05-17 07:48:52.533","MatchID" : 43614953,"EventDate" : "2021-05-17 00:00:00","KickOffTime" : "2021-05-17 00:00:00","EventStatus" : "running","HomeID" : 953,"AwayID" : 113,"LeagueID" : 3,"Bettype" : 3, "BetID" : 0,  "LiveIndicator" : "1","CustID" : 12500792,"Stake" : 20,"Betteam" : "a","LiveHomeScore" : 0,"LiveAwayScore" : 2}]');;
            
	*/    
    
    DECLARE lv_LastSequenceID BIGINT UNSIGNED DEFAULT 0;
    
    IF ip_LiveIndicator = 1 THEN    
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, InsertTime)
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
			,	CURRENT_TIMESTAMP(3)
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
								,	Stake			DOUBLE PATH "$.Stake" 
                                ,	Betteam			VARCHAR(10)	PATH "$.Betteam" 
							)
					) AS js;  
		
        INSERT IGNORE INTO CTS_DataCenter.MatchMonitorTransLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, Odds, IsMajorLeague, InsertTime)
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
			,	CURRENT_TIMESTAMP(3)
		FROM JSON_TABLE(ip_TransList,
						 "$[*]" COLUMNS(
									SequenceID		BIGINT PATH "$.SequenceID"
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
								,	Stake			DOUBLE PATH "$.Stake" 
                                ,	Betteam			VARCHAR(10)	PATH "$.Betteam" 
                                ,	Odds			DECIMAL(10,4) PATH "$.Odds" 
                                ,	IsMajorLeague	BOOLEAN	PATH "$.IsMajorLeague" 
							)
					) AS js
			WHERE js.IsMajorLeague = 0;
        
		#=====UPDATE SYSTEM PARAMETER===============================
		SELECT MAX(mms.SequenceID)
		INTO lv_LastSequenceID
		FROM CTS_DataCenter.MatchMonitorStagingLive AS mms;  
            
            
         IF lv_LastSequenceID > 0 THEN	   
			UPDATE CTS_DataCenter.SystemParameter AS sys
			SET sys.ParameterValue = lv_LastSequenceID
			WHERE sys.ParameterID = 20;
		END IF;        
	ELSE
    	INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingNonLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, InsertTime)
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
			,	js.LiveHomeScore
			,	js.LiveAwayScore
			,	js.LiveHomeScore + js.LiveAwayScore AS TotalScore
			,	js.BettypeID
            ,	js.BetID
			,	js.CustID
			,	js.Stake
            ,	js.Betteam
			,	CURRENT_TIMESTAMP(3)
		FROM JSON_TABLE(ip_TransList,
						 "$[*]" COLUMNS(                         
									SequenceID		BIGINT PATH "$.SequenceID"
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
								,	Stake			DOUBLE PATH "$.Stake"
                                ,	Betteam			BOOLEAN	PATH "$.Betteam" 
							)
					) AS js;
		
                    
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorTransNonLive(SequenceID, TransID, TransDate, LeagueName, SportType, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, BetID, CustID, Stake, Betteam, Odds, IsMajorLeague, InsertTime)
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
			,	CURRENT_TIMESTAMP(3)
		FROM JSON_TABLE(ip_TransList,
						 "$[*]" COLUMNS(
									SequenceID		BIGINT PATH "$.SequenceID"
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
								,	Stake			DOUBLE PATH "$.Stake" 
                                ,	Betteam			VARCHAR(10)	PATH "$.Betteam" 
                                ,	Odds			DECIMAL(10,4)	PATH "$.Odds" 
                                ,	IsMajorLeague	TINYINT(1)	PATH "$.IsMajorLeague" 
							)
					) AS js
			WHERE js.IsMajorLeague = 0;
                    
		#=====UPDATE SYSTEM PARAMETER===============================
		SELECT 	MAX(mms.SequenceID)
		INTO 	lv_LastSequenceID
		FROM	CTS_DataCenter.MatchMonitorStagingNonLive AS mms;  
            
        IF lv_LastSequenceID > 0 THEN	   
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = lv_LastSequenceID
			WHERE 	sys.ParameterID = 29;
		END IF; 
        
	END IF;
    
END$$
DELIMITER ;
