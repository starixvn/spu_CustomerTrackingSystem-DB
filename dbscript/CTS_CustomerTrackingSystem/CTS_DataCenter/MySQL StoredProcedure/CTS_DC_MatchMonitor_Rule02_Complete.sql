/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule02_Complete`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule02_Complete`(
		IN ip_LiveIndicator BOOLEAN
	,	IN ip_MaxTransID 	BIGINT UNSIGNED
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
            
		Param's Explanation (filtered by):	

		Example:
			CALL CTS_DC_MatchMonitor_Rule02_Complete_xtest(@ip_LiveIndicator:=1,@ip_MaxTransID:=115841606929,@ip_MatchID:=1,@ip_TotalScore:=0,@ip_BettypeID:=1,@ip_BetID:=0,@ip_Betteam:='a'
				,@ip_TransGroup = '[{"Reason": 3 ,"TransIDList":"1001,1007,1008","CustIDList":"1,2"}]');
	*/ 
    DECLARE	lv_KickOffTime 			DATETIME;
    DECLARE	lv_EventStatus 			VARCHAR(50);
    DECLARE lv_HomeID 				INT UNSIGNED;
    DECLARE lv_AwayID 				INT UNSIGNED;
    DECLARE lv_LeagueID				INT UNSIGNED;
    DECLARE lv_LeagueName			VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    DECLARE	lv_Sporttype			INT;
    DECLARE	lv_MatchDetailsID		INT;
	DECLARE lv_EventDate 			DATE;
    DECLARE lv_LiveHomeScore		SMALLINT UNSIGNED;
    DECLARE lv_LiveAwayScore		SMALLINT UNSIGNED;
    DECLARE	CONST_GROUPID			TINYINT DEFAULT 0;
	DECLARE	CONST_REASON_FIXEDGAME	TINYINT DEFAULT 3; #0: Group Betting, 1: Headging, 2: Arbitrage, 3: FixedGame
  
    DROP TEMPORARY TABLE IF EXISTS Temp_TransGroup;
    CREATE TEMPORARY TABLE Temp_TransGroup
    (
			Reason 			TINYINT
        ,	TransIDList 	LONGTEXT
        ,	CustIDList		LONGTEXT 
    );
    
    INSERT IGNORE INTO CTS_DataCenter.Temp_TransGroup(Reason, TransIDList, CustIDList)
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

    #======Update MatchMonitorDetails====================================         
    
    IF (ip_LiveIndicator = 1) THEN
    
		SELECT mms.EventDate, mms.LiveHomeScore, mms.LiveAwayScore, mms.EventDate, mms.KickOffTime, mms.EventStatus, mms.HomeID, mms.AwayID, mms.LeagueID, mms.LeagueName, mms.Sporttype
		INTO lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, lv_LeagueName, lv_Sporttype
		FROM CTS_DataCenter.MatchMonitorTransLive AS mms
		WHERE mms.TransID <= ip_MaxTransID AND mms.MatchID = ip_MatchID AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.TotalScore = ip_TotalScore AND mms.Betteam = ip_Betteam
		LIMIT 1;
        
	END IF;

	IF (ip_LiveIndicator = 0) THEN
		SELECT mms.EventDate, mms.LiveHomeScore, mms.LiveAwayScore, mms.EventDate, mms.KickOffTime, mms.EventStatus, mms.HomeID, mms.AwayID, mms.LeagueID, mms.LeagueName, mms.Sporttype
		INTO lv_EventDate, lv_LiveHomeScore, lv_LiveAwayScore, lv_EventDate, lv_KickOffTime, lv_EventStatus, lv_HomeID, lv_AwayID, lv_LeagueID, lv_LeagueName, lv_Sporttype
		FROM CTS_DataCenter.MatchMonitorTransNonLive AS mms
		WHERE mms.TransID <= ip_MaxTransID AND mms.MatchID = ip_MatchID AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.Betteam = ip_Betteam
		LIMIT 1;	 
	END IF;	
    
    SELECT 	mmd.ID 
    INTO 	lv_MatchDetailsID
	FROM 	CTS_DataCenter.MatchMonitorDetails AS mmd
	WHERE 	mmd.LiveIndicator = ip_LiveIndicator AND mmd.MatchID = ip_MatchID AND mmd.BettypeID = ip_BettypeID
		AND mmd.BetID = ip_BetID AND mmd.TotalScore = ip_TotalScore AND mmd.Betteam = ip_Betteam AND mmd.Reason = CONST_REASON_FIXEDGAME;
    
    IF (lv_MatchDetailsID IS NOT NULL) THEN    
		UPDATE CTS_DataCenter.MatchMonitorDetails AS mmd
			INNER JOIN CTS_DataCenter.Temp_TransGroup AS tmpTg ON mmd.Reason = tmpTg.Reason
        SET 	mmd.ListCustID = CONCAT(mmd.ListCustID,',',tmpTg.CustIDList)
			,	mmd.ListTransID = CONCAT(mmd.ListTransID,',',tmpTg.TransIDList)
		WHERE mmd.ID = lv_MatchDetailsID;
        
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
    
    UPDATE CTS_DataCenter.MatchMonitorTransLive AS mmt
    SET mmt.StatusRule02 = 1
    WHERE mmt.TransID <= ip_MaxTransID;
    
END$$
DELIMITER ;