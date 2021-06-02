/*<info serverAlias="CjsMain-CTS_DataCenter" databaseType="2" executers="cjsWeb" isFunction="0" isNested="0"></info>*/
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
				{"TransID":111928688806,"TransDate":"2021-05-17 07:48:52.527","MatchID":43606436,"LiveIndicator":1,"LiveHomeScore":1,"LiveAwayScore":0,"Bettype":8,"CustID":38290463,"Stake":50}
			]');

		Example:
			
	*/
	DECLARE lv_TempGroupID TINYINT;
    
    SET lv_TempGroupID = 30;

	DROP TEMPORARY TABLE IF EXISTS Temp_TransStaging;
	CREATE TEMPORARY TABLE Temp_TransStaging(
			MatchID			INT UNSIGNED NOT NULL
		,	HomeID			INT
        ,	AwayID			INT
        ,	LeagueID		INT
        ,	EventDate		DATETIME
		,	LiveIndicator 	BIT(1) NOT NULL        
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

		,	PRIMARY KEY (MatchID, LiveIndicator, TotalScore, BettypeID, TransID)
		,	INDEX IX_MatchMonitorStaging_GroupID (GroupID)
		,	INDEX IX_MatchMonitorStaging_OriginGroupID (OriginGroupID)
	) ENGINE=MEMORY;  

	DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;
	CREATE TEMPORARY TABLE Temp_TransGroup(
			MatchID			INT UNSIGNED NOT NULL
		,	LiveIndicator 	BIT(1) NOT NULL
		,	TotalScore		SMALLINT UNSIGNED NOT NULL
		,	BettypeID		INT UNSIGNED NOT NULL	
		,	MinTransID		BIGINT UNSIGNED
		,	MinTransDate	DATETIME(3)
        ,	GroupOrder		INT
		,	PRIMARY KEY (MatchID, LiveIndicator, TotalScore, BettypeID)
	) ENGINE=MEMORY;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ParentGroup;
	CREATE TEMPORARY TABLE Temp_ParentGroup(
		TempGroupID INT
    ) ENGINE=MEMORY;
    
	INSERT IGNORE INTO Temp_TransStaging(TransID, TransDate, MatchID, HomeID, AwayID, LeagueID, EventDate, LiveIndicator, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, CustID, Stake)
	SELECT  js.TransID
		,	js.TransDate
		,	js.MatchID
        ,	js.HomeID
        ,	js.AwayID
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
							,	MatchID			INT	PATH "$.MatchID"
                            ,	HomeID			INT	PATH "$.HomeID" 
                            ,	AwayID			INT	PATH "$.AwayID" 
                            ,	LeagueID		INT	PATH "$.LeagueID"
                            ,	EventDate		DATETIME PATH "$.EventDate"
							,	LiveIndicator	INT	PATH "$.LiveIndicator" 
							,	LiveHomeScore	INT	PATH "$.LiveHomeScore" 
							,	LiveAwayScore	INT	PATH "$.LiveAwayScore" 
							,	BettypeID		INT	PATH "$.Bettype" 
							,	CustID			INT PATH "$.CustID"
							,	Stake			DOUBLE PATH "$.Stake" 
						)
				) AS js;
	
	INSERT IGNORE INTO Temp_TransStaging(MatchID, LiveIndicator, LiveHomeScore, LiveAwayScore, TotalScore, BettypeID, TransID, CustID, TransDate, Stake, GroupID, OriginGroupID)
	SELECT 		MatchID,  LiveIndicator, LiveHomeScore, LiveAwayScore, LiveHomeScore + LiveAwayScore, BettypeID, TransID, CustID, TransDate, Stake, GroupID, OriginGroupID
	FROM		MatchMonitorStaging;
	
    SET @GroupOrder = 0;
	INSERT INTO Temp_TransGroup(MatchID, LiveIndicator, TotalScore, BettypeID, MinTransID, MinTransDate, GroupOrder) 
	SELECT 		MatchID, LiveIndicator, TotalScore, BettypeID, MIN(TransID), MIN(TransDate), @GroupOrder:= @GroupOrder+1
	FROM		Temp_TransStaging
	GROUP BY 	MatchID, LiveIndicator, TotalScore, BettypeID;

	SET @TempGroupID=0;
	SET @PreTime=NULL;
	UPDATE  Temp_TransStaging AS tmpTs
		INNER JOIN 	Temp_TransGroup AS tmpTg ON  tmpTs.MatchID = tmpTg.MatchID AND  tmpTs.LiveIndicator = tmpTg.LiveIndicator AND  tmpTs.TotalScore=tmpTg.TotalScore AND tmpTs.BettypeID = tmpTg.BettypeID
	 SET	tmpTs.OriginGroupID	= MinTransID  
		,	tmpTs.PreTime		= IF(tmpTs.TransID = tmpTg.MinTransID, @PreTime:=tmpTg.MinTransDate, @PreTime) 	
		, 	tmpTs.TempGroupID	= IF(tmpTs.TransID = tmpTg.MinTransID,@TempGroupID:=@TempGroupID +1, IF(TIMESTAMPDIFF(MINUTE,@PreTime, @PreTime:=tmpTs.TransDate)> lv_TempGroupID , @TempGroupID:=@TempGroupID +1 , @TempGroupID));
	   
    INSERT INTO Temp_ParentGroup(TempGroupID)
    SELECT		TempGroupID
    FROM		Temp_TransStaging
    GROUP BY	TempGroupID
    HAVING		COUNT(1) > 1;
	
    INSERT IGNORE INTO CTS_DataCenter.MatchMonitorStaging(TransID, TransDate, MatchID, HomeID, AwayID, LeagueID, EventDate, LiveIndicator, LiveHomeScore, LiveAwayScore, BettypeID, CustID, Stake, OriginGroupID)
    SELECT 	TransID
		,	TransDate
		,	MatchID
		,	HomeID
        ,	AwayID
        , 	LeagueID
        ,	EventDate
		,	LiveIndicator
		,	LiveHomeScore
		,	LiveAwayScore
		,	BettypeID
		,	CustID
		,	Stake
        ,	tmpGp.TempGroupID
	FROM	Temp_TransStaging AS tmpTs
		LEFT JOIN Temp_ParentGroup AS tmpGp ON tmpTs.TempGroupID = tmpGp.TempGroupID;
    
    SELECT TempGroupID FROM Temp_ParentGroup;
END$$
DELIMITER ;
