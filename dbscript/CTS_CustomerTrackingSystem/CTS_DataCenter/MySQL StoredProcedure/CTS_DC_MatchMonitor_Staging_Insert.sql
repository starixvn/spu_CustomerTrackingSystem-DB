/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Staging_Insert`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Staging_Insert`(
		IN ip_IsLive 	BOOLEAN 
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
		CALL CTS_DataCenter.CTS_DC_MatchMonitor_Staging_Insert(
			'[
					{"TransID": 111928688807,"TransDate" : "2021-05-17 07:48:52.533","MatchID" : 43614953,"EventDate" : "2021-05-17 00:00:00","KickOffTime" : "2021-05-17 00:00:00","EventStatus" : "running","HomeID" : 953,"AwayID" : 113,"LeagueID" : 3,"Bettype" : 3,"LiveIndicator" : "1","CustID" : 12500792,"Stake" : 20,"LiveHomeScore" : 0,"LiveAwayScore" : 2}
			]');

		Example:
			
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_OringinGroupID;
	CREATE TEMPORARY TABLE Temp_OringinGroupID(
			MatchID			BIGINT UNSIGNED NOT NULL
		,	LiveIndicator 	BIT(1) NOT NULL
		,	TotalScore		SMALLINT UNSIGNED NOT NULL
		,	BettypeID		INT UNSIGNED NOT NULL
        ,	OringinGroupID	INT AUTO_INCREMENT
		,	PRIMARY KEY (MatchID, LiveIndicator, TotalScore, BettypeID)
        ,	UNIQUE KEY UK_Temp_TransGroup_OringinGroupID(OringinGroupID)
	);
    
    IF ip_IsLive = 1 THEN    
		UPDATE	CTS_DataCenter.MatchMonitorStagingLive
		SET		OriginGroupID = NULL;    
		
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingLive(TransID, TransDate, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveIndicator, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, CustID, Stake, InsertTime)
		SELECT  js.TransID
			,	js.TransDate
			,	js.MatchID
			,	js.HomeID
			,	js.AwayID
			,	js.EventStatus
			,	js.KickOffTime
			,	js.LeagueID
			,	js.EventDate
			,	js.LiveIndicator
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
								,	LiveIndicator	INT	PATH "$.LiveIndicator" 
								,	LiveHomeScore	INT	PATH "$.LiveHomeScore" 
								,	LiveAwayScore	INT	PATH "$.LiveAwayScore" 
								,	BettypeID		INT	PATH "$.Bettype" 
								,	CustID			INT PATH "$.CustID"
								,	Stake			DOUBLE PATH "$.Stake" 
							)
					) AS js;  
	
		INSERT INTO Temp_OringinGroupID(MatchID, LiveIndicator, TotalScore, BettypeID)
		SELECT	mms.MatchID
			,	mms.LiveIndicator
			,	mms.TotalScore
			,	mms.BettypeID
		FROM		CTS_DataCenter.MatchMonitorStagingLive AS mms
		GROUP BY	mms.MatchID, mms.LiveIndicator, mms.TotalScore, mms.BettypeID
		HAVING		COUNT(DISTINCT CustID) > 1 AND SUM(Stake) >=500;
		
		UPDATE  CTS_DataCenter.MatchMonitorStagingLive AS mms
			INNER JOIN Temp_OringinGroupID AS tmpGp ON mms.MatchID = tmpGp.MatchID AND mms.LiveIndicator = tmpGp.LiveIndicator
						AND mms.TotalScore = tmpGp.TotalScore AND mms.BettypeID = tmpGp.BettypeID
		SET mms.OriginGroupID = tmpGp.OringinGroupID;   
		
		SELECT 	DISTINCT OriginGroupID 
		FROM 	CTS_DataCenter.MatchMonitorStagingLive
		WHERE 	OriginGroupID IS NOT NULL AND GroupID IS NULL;    
	END IF;
    
    IF ip_IsLive = 0 THEN    
		UPDATE	CTS_DataCenter.MatchMonitorStagingNonLive
		SET		OriginGroupID = NULL;    
		
		INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStagingNonLive(TransID, TransDate, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveIndicator, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, CustID, Stake, InsertTime)
		SELECT  js.TransID
			,	js.TransDate
			,	js.MatchID
			,	js.HomeID
			,	js.AwayID
			,	js.EventStatus
			,	js.KickOffTime
			,	js.LeagueID
			,	js.EventDate
			,	js.LiveIndicator
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
								,	LiveIndicator	INT	PATH "$.LiveIndicator" 
								,	LiveHomeScore	INT	PATH "$.LiveHomeScore" 
								,	LiveAwayScore	INT	PATH "$.LiveAwayScore" 
								,	BettypeID		INT	PATH "$.Bettype" 
								,	CustID			INT PATH "$.CustID"
								,	Stake			DOUBLE PATH "$.Stake" 
							)
					) AS js;  
			 
		INSERT INTO Temp_OringinGroupID(MatchID, LiveIndicator, TotalScore, BettypeID)
		SELECT	mms.MatchID
			,	mms.LiveIndicator
			,	mms.TotalScore
			,	mms.BettypeID
		FROM		CTS_DataCenter.MatchMonitorStagingNonLive AS mms
		GROUP BY	mms.MatchID, mms.LiveIndicator, mms.TotalScore, mms.BettypeID
		HAVING		COUNT(DISTINCT CustID) > 1 AND SUM(Stake) >=500;
		
		UPDATE  CTS_DataCenter.MatchMonitorStagingNonLive AS mms
			INNER JOIN Temp_OringinGroupID AS tmpGp ON mms.MatchID = tmpGp.MatchID AND mms.LiveIndicator = tmpGp.LiveIndicator
						AND mms.TotalScore = tmpGp.TotalScore AND mms.BettypeID = tmpGp.BettypeID
		SET mms.OriginGroupID = tmpGp.OringinGroupID;   
		
		SELECT 	DISTINCT OriginGroupID 
		FROM 	CTS_DataCenter.MatchMonitorStagingNonLive
		WHERE 	OriginGroupID IS NOT NULL AND GroupID IS NULL;    
	END IF;
    
END$$
DELIMITER ;
