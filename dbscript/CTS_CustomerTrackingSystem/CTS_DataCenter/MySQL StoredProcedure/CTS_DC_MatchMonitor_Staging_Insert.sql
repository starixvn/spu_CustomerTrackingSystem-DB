/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Staging_Insert`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Staging_Insert`(
		IN ip_LiveIndicator	BOOLEAN 
    ,	IN ip_TransList JSON
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
		
		Param's Explanation (filtered by):
		CALL CTS_DataCenter.CTS_DC_MatchMonitor_Staging_Insert(1,
			'[
					{"TransID": 111928688807,"TransDate" : "2021-05-17 07:48:52.533","MatchID" : 43614953,"EventDate" : "2021-05-17 00:00:00","KickOffTime" : "2021-05-17 00:00:00","EventStatus" : "running","HomeID" : 953,"AwayID" : 113,"LeagueID" : 3,"Bettype" : 3,"LiveIndicator" : "1","CustID" : 12500792,"Stake" : 20,"LiveHomeScore" : 0,"LiveAwayScore" : 2}
			]');

		Example:
			
	*/
    
    IF ip_LiveIndicator = 1 THEN    
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingLive(TransID, TransDate, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, CustID, Stake, InsertTime)
		SELECT  js.TransID
			,	js.TransDate
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
			,	js.CustID
			,	js.Stake
			,	CURRENT_TIMESTAMP(3)
		FROM JSON_TABLE(ip_TransList,
						 "$[*]" COLUMNS(
									TransID			BIGINT UNSIGNED PATH "$.TransID" 
								,	TransDate		DATETIME(3) PATH "$.TransDate" 
								,	MatchID			BIGINT	UNSIGNED PATH "$.MatchID"
								,	HomeID			INT	PATH "$.HomeID" 
								,	AwayID			INT	PATH "$.AwayID" 
								,	EventStatus		VARCHAR(50)	PATH "$.EventStatus" 
								,	KickOffTime		DATETIME PATH "$.KickOffTime" 
								,	LeagueID		INT	PATH "$.LeagueID"
								,	EventDate		DATE PATH "$.EventDate"
								,	LiveHomeScore	INT	PATH "$.LiveHomeScore" 
								,	LiveAwayScore	INT	PATH "$.LiveAwayScore" 
								,	BettypeID		INT	PATH "$.BettypeID" 
								,	CustID			INT PATH "$.CustID"
								,	Stake			DOUBLE PATH "$.Stake" 
							)
					) AS js;  
		
		SELECT	mms.MatchID
			,	mms.TotalScore
			,	mms.BettypeID
		FROM		CTS_DataCenter.MatchMonitorStagingLive AS mms
        WHERE		mms.GroupID = 0
		GROUP BY	mms.MatchID, mms.TotalScore, mms.BettypeID
		HAVING		COUNT(DISTINCT mms.CustID) > 1 AND SUM(mms.Stake) >= 500;
        
	ELSE
    	INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingNonLive(TransID, TransDate, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, CustID, Stake, InsertTime)
		SELECT  js.TransID
			,	js.TransDate
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
			,	js.CustID
			,	js.Stake
			,	CURRENT_TIMESTAMP(3)
		FROM JSON_TABLE(ip_TransList,
						 "$[*]" COLUMNS(
									TransID			BIGINT UNSIGNED PATH "$.TransID" 
								,	TransDate		DATETIME(3) PATH "$.TransDate" 
								,	MatchID			BIGINT	UNSIGNED PATH "$.MatchID"
								,	HomeID			INT	PATH "$.HomeID" 
								,	AwayID			INT	PATH "$.AwayID" 
								,	EventStatus		VARCHAR(50)	PATH "$.EventStatus" 
								,	KickOffTime		DATETIME PATH "$.KickOffTime" 
								,	LeagueID		INT	PATH "$.LeagueID"
								,	EventDate		DATE PATH "$.EventDate"
								,	LiveHomeScore	INT	PATH "$.LiveHomeScore" 
								,	LiveAwayScore	INT	PATH "$.LiveAwayScore" 
								,	BettypeID		INT	PATH "$.BettypeID" 
								,	CustID			INT PATH "$.CustID"
								,	Stake			DOUBLE PATH "$.Stake" 
							)
					) AS js;  
		

		SELECT	mms.MatchID
			,	mms.TotalScore
			,	mms.BettypeID
		FROM		CTS_DataCenter.MatchMonitorStagingNonLive AS mms
        WHERE		mms.GroupID = 0
		GROUP BY	mms.MatchID, mms.TotalScore, mms.BettypeID
		HAVING		COUNT(DISTINCT mms.CustID) > 1 AND SUM(mms.Stake) >= 500;
        
	END IF;
    
END$$
DELIMITER ;
