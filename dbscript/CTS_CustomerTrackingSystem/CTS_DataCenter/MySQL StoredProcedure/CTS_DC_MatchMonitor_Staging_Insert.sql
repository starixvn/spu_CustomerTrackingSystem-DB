/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Staging_Insert`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Staging_Insert`(
	IN ip_TransList JSON
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
		
		Param's Explanation (filtered by):
		CALL CTS_DataCenter.CTS_DC_MatchMonitor_Staging_Insert(
			'[
					{"TransID": 111928688807,"TransDate" : "2021-05-17 07:48:52.533","MatchID" : 43614953,"EventDate" : "2021-05-17 00:00:00","KickOffTime" : "2021-05-17 00:00:00","EventStatus" : "running","HomeID" : 953,"AwayID" : 113,"LeagueID" : 3,"Bettype" : 3,"LiveIndicator" : "1","CustID" : 12500792,"Stake" : 20,"LiveHomeScore" : 0,"LiveAwayScore" : 2}
			]');

		Example:
			
	*/
	DECLARE lv_TimeStep TINYINT;
    
    SET lv_TimeStep = 30;	
	
    INSERT INTO MatchMonitorTrace_StagingTrace(TransJson, InsertTIme)
    VALUES(ip_TransList, current_timestamp(3));
    
	DROP TEMPORARY TABLE IF EXISTS Temp_TransStaging;
	CREATE TEMPORARY TABLE Temp_TransStaging(
			MatchID			BIGINT UNSIGNED NOT NULL
		,	HomeID			INT
        ,	AwayID			INT
        ,	EventStatus		VARCHAR(50)
        ,	KickOffTime		DATETIME
        ,	LeagueID		INT
        ,	EventDate		DATE
		,	LiveIndicator 	BIT NOT NULL        
        ,	LiveHomeScore	SMALLINT UNSIGNED NOT NULL
		,	LiveAwayScore	SMALLINT UNSIGNED NOT NULL
        ,	TotalScore		SMALLINT UNSIGNED NOT NULL
		,	BettypeID		INT UNSIGNED NOT NULL	
		,	TransID			BIGINT UNSIGNED NOT NULL
		,	CustID			BIGINT UNSIGNED DEFAULT NULL
		,	TransDate		DATETIME(3) DEFAULT NULL
		,	Stake			DOUBLE DEFAULT NULL
		,	GroupID			BIGINT UNSIGNED DEFAULT NULL
		,	OriginGroupID	BIGINT UNSIGNED DEFAULT NULL
        ,	PreTime			DATETIME(3)
        ,	TempGroupID		INT

		,	PRIMARY KEY (TransID)
		,	INDEX IX_MatchMonitorStaging_GroupID (GroupID)
		,	INDEX IX_MatchMonitorStaging_OriginGroupID (OriginGroupID)
        ,	INDEX IX_MatchMonitorStaging_Group(MatchID, LiveIndicator, TotalScore, BettypeID, TempGroupID)
	);  

	DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;
	CREATE TEMPORARY TABLE Temp_TransGroup(
			MatchID			BIGINT UNSIGNED NOT NULL
		,	LiveIndicator 	BIT(1) NOT NULL
		,	TotalScore		SMALLINT UNSIGNED NOT NULL
		,	BettypeID		INT UNSIGNED NOT NULL	
		,	MinTransID		BIGINT UNSIGNED
        ,	TempGroupID		INT DEFAULT 0
		,	MinTransDate	DATETIME(3)
        ,	MaxTransDate	DATETIME(3)
        ,	GroupOrder		INT
		,	PRIMARY KEY (MatchID, LiveIndicator, TotalScore, BettypeID, TempGroupID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ParentGroup;
	CREATE TEMPORARY TABLE Temp_ParentGroup(
		TempGroupID INT
    );
    
	INSERT IGNORE INTO Temp_TransStaging(TransID, TransDate, MatchID, HomeID, AwayID, EventStatus, KickOffTime, LeagueID, EventDate, LiveIndicator, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, CustID, Stake)
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
                
	UPDATE	MatchMonitorStaging
    SET		OriginGroupID = NULL;
		#,	GroupID = NULL;
    
	INSERT IGNORE INTO Temp_TransStaging(MatchID, LiveIndicator, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, TransID, CustID, TransDate, Stake, GroupID, OriginGroupID)
	SELECT 		MatchID,  LiveIndicator, LiveHomeScore, LiveAwayScore, LiveHomeScore + LiveAwayScore, BettypeID, TransID, CustID, TransDate, Stake, GroupID, OriginGroupID
	FROM		MatchMonitorStaging;    
    
    SET @GroupOrder = 0;  
	INSERT INTO Temp_TransGroup(MatchID, LiveIndicator, TotalScore, BettypeID, MinTransID, MinTransDate) 
	SELECT 		MatchID, LiveIndicator, TotalScore, BettypeID, MIN(TransID), MIN(TransDate)
	FROM		Temp_TransStaging AS tmpTs
	GROUP BY 	tmpTs.MatchID, tmpTs.LiveIndicator, tmpTs.TotalScore, tmpTs.BettypeID;

    SET @TempGroupID=0;
	SET @PreTime=NULL;
	UPDATE  Temp_TransStaging AS tmpTs
		INNER JOIN 	Temp_TransGroup AS tmpTg ON  tmpTs.MatchID = tmpTg.MatchID AND  tmpTs.LiveIndicator = tmpTg.LiveIndicator 
					AND  tmpTs.TotalScore=tmpTg.TotalScore AND tmpTs.BettypeID = tmpTg.BettypeID
	 SET	tmpTs.PreTime		= IF(tmpTs.TransID = tmpTg.MinTransID, @PreTime:=tmpTg.MinTransDate, @PreTime) 	
		, 	tmpTs.TempGroupID	= IF(tmpTs.TransID = tmpTg.MinTransID,@TempGroupID:=@TempGroupID +1, IF(TIMESTAMPDIFF(MINUTE,@PreTime, @PreTime:=tmpTs.TransDate)> lv_TimeStep , @TempGroupID:=@TempGroupID +1 , @TempGroupID))
	 ;  
	
    TRUNCATE TABLE Temp_TransGroup;
    INSERT INTO Temp_TransGroup(MatchID, LiveIndicator, TotalScore, BettypeID, TempGroupID, MinTransID, MinTransDate, GroupOrder) 
	SELECT 		MatchID, LiveIndicator, TotalScore, BettypeID, TempGroupID, MIN(TransID), MIN(TransDate), @GroupOrder:= @GroupOrder+1
	FROM		Temp_TransStaging AS tmpTs
	GROUP BY 	tmpTs.MatchID, tmpTs.LiveIndicator, tmpTs.TotalScore, tmpTs.BettypeID, tmpTs.TempGroupID
    HAVING COUNT(DISTINCT CustID)>1 AND SUM(Stake) >= 500;

    UPDATE  Temp_TransStaging AS tmpTs
    INNER JOIN Temp_TransGroup AS tmTg ON tmpTs.MatchID = tmTg.MatchID AND tmpTs.LiveIndicator AND tmTg.LiveIndicator
					AND tmpTs.TotalScore = tmTg.TotalScore AND tmpTs.BettypeID = tmTg.BettypeID AND tmpTs.TempGroupID = tmTg.TempGroupID
	SET tmpTs.OriginGroupID = tmTg.GroupOrder;
	     
    INSERT INTO Temp_ParentGroup(TempGroupID)
    SELECT		 tmpTs.TempGroupID
    FROM		Temp_TransStaging AS tmpTs
    GROUP BY	tmpTs.MatchID, tmpTs.LiveIndicator, tmpTs.TotalScore, tmpTs.BettypeID, tmpTs.TempGroupID
	HAVING		COUNT(1) > 1 AND SUM(Stake) >=500;
    
    UPDATE  CTS_DataCenter.MatchMonitorStaging AS mms
		INNER JOIN CTS_DataCenter.Temp_TransStaging AS tmpTs ON mms.TransID = tmpTs.TransID
		INNER JOIN Temp_ParentGroup AS tmpGp ON tmpTs.TempGroupID = tmpGp.TempGroupID
	SET mms.OriginGroupID = tmpGp.TempGroupID;    
    
    INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStaging(TransID, TransDate, MatchID, HomeID, AwayID, EventStatus, KickOffTime
			, LeagueID, EventDate, LiveIndicator, LiveHomeScore, TotalScore, LiveAwayScore, BettypeID, CustID, Stake, OriginGroupID, InsertTime)
    SELECT 	TransID
		,	TransDate
		,	MatchID
		,	HomeID
        ,	AwayID
        ,	EventStatus
        ,	KickOffTime
        , 	LeagueID
        ,	EventDate
		,	LiveIndicator
		,	LiveHomeScore
		,	LiveAwayScore
        ,	TotalScore
		,	BettypeID
		,	CustID
		,	Stake
        ,	tmpGp.TempGroupID
        ,	current_time(3)
	FROM	Temp_TransStaging AS tmpTs
		LEFT JOIN Temp_ParentGroup AS tmpGp ON tmpTs.TempGroupID = tmpGp.TempGroupID;
    
    SELECT DISTINCT OriginGroupID FROM CTS_DataCenter.MatchMonitorStaging WHERE OriginGroupID IS NOT NULL;    

END$$
DELIMITER ;
