/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule02_Process`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule02_Process`(
		IN ip_LiveIndicator		BOOLEAN
	,	IN ip_MaxTransID		BIGINT UNSIGNED
	,	IN ip_MatchID			INT UNSIGNED
    ,	IN ip_TotalScore		INT 
    ,	IN ip_BettypeID			INT UNSIGNED
    ,	IN ip_BetID				BIGINT
    ,	IN ip_Betteam			VARCHAR(50)
)
    SQL SECURITY INVOKER
sp: BEGIN
		/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220726@Casey.Huynh: Created [Redmine ID: #175700]
            
		Param's Explanation (filtered by):	

		Example:
			CALL CTS_DC_MatchMonitor_Rule02_Process(@ip_LiveIndicator:=1,@ip_MaxTransID:=0,@ip_MatchID:=1,@ip_TotalScore:=1,@ip_BettypeID:=1,@ip_BetID:=0,@ip_Betteam:='a');
	*/
    
    DECLARE	CONST_REASON					TINYINT DEFAULT 3; #0: Group Betting, 1: Headging, 2: Arbitrage, 3: FixedGame
    
    DECLARE lv_MaxTransID BIGINT UNSIGNED;
    DECLARE lv_MaxTransDate DATETIME(3);
	DECLARE lv_LastTransDate DATETIME(3);
    DECLARE lv_LastTransID BIGINT UNSIGNED;
    DECLARE	lv_Rule_TotalTicket			SMALLINT; 
    DECLARE	lv_Rule_HighStake			SMALLINT;
    DECLARE	lv_Rule_HighStakePercent	DECIMAL(1,1);    
	DECLARE	lv_Rule_Duration			SMALLINT; 
    DECLARE	lv_Rule_OddsSpread_Min		SMALLINT; 
    DECLARE	lv_Rule_OddsSpread_Max		SMALLINT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FixedTransRange;
    CREATE TEMPORARY TABLE Temp_FixedTransRange(
			MinTransID	BIGINT UNSIGNED
        ,	MaxTransID	BIGINT	UNSIGNED
        
        ,	PRIMARY KEY Temp_FixedTransRange(MinTransID,MaxTransID)
	);
	
    #===GET RULE FROM SystemParameter=====
    SELECT s.ParameterValue INTO lv_Rule_Duration FROM CTS_DataCenter.SystemParameter AS s WHERE s.ParameterID = 107;
    SELECT s.ParameterValue INTO lv_Rule_HighStake FROM CTS_DataCenter.SystemParameter AS s WHERE s.ParameterID = 108;
    SELECT s.ParameterValue INTO lv_Rule_TotalTicket FROM CTS_DataCenter.SystemParameter AS s WHERE s.ParameterID = 109;
    SELECT s.ParameterValue INTO lv_Rule_HighStakePercent FROM CTS_DataCenter.SystemParameter AS s WHERE s.ParameterID = 110;
    SELECT s.ParameterValue INTO lv_Rule_OddsSpread_Min FROM CTS_DataCenter.SystemParameter AS s WHERE s.ParameterID = 111;
    SELECT s.ParameterValue INTO lv_Rule_OddsSpread_Max FROM CTS_DataCenter.SystemParameter AS s WHERE s.ParameterID = 112;
    
    IF (ip_LiveIndicator = 1) THEN
		
		SELECT MAX(TransDate)
		INTO lv_MaxTransDate
		FROM CTS_DataCenter.MatchMonitorTransLive AS mmt
		WHERE mmt.TransID = ip_MaxTransID;   
        
        SELECT s.ParameterValue
        INTO lv_LastTransID
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 100;        
		
        INSERT INTO Temp_FixedTransRange (MinTransID, MaxTransID)
        SELECT TransID, MaxTransID1
		FROM (
				SELECT  
					TransDate, TransID, CustID, Stake, Odds
				,	MAX(TransID) OVER w1 MaxTransID1
				,	MAX(TransDate) OVER w1  AS LastTransDate1
				,	MIN(Odds) OVER w1 AS MinOdds1
				, 	MAX(Odds) OVER w1  AS MaxOdds1
				,	SUM(CASE WHEN Stake > lv_Rule_HighStake THEN 1 ELSE 0 END) OVER w1  AS TotalHighStake1
				,	COUNT(1) OVER w1  AS TotalTrans1
			   FROM CTS_DataCenter.MatchMonitorTransLive AS mmt
			   WHERE  mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam
					AND mmt.TransID > lv_LastTransID AND mmt.TransID <= ip_MaxTransID AND mmt.StatusRule02 = 0
			   WINDOW w1 AS (ORDER BY TransDate RANGE BETWEEN CURRENT ROW AND INTERVAL lv_Rule_Duration MINUTE  FOLLOWING)						
			) AS tmpTs
        WHERE tmpTs.TotalTrans1 > lv_Rule_TotalTicket
			AND (tmpTs.TotalHighStake1/tmpTs.TotalTrans1) > lv_Rule_HighStakePercent 
			AND (tmpTs.MaxOdds1 - tmpTs.MinOdds1)*100 BETWEEN lv_Rule_OddsSpread_Min AND lv_Rule_OddsSpread_Max;

        SELECT CONST_REASON AS Reason
			,	GROUP_CONCAT(DISTINCT TransID) AS TransIDList
            ,	GROUP_CONCAT(DISTINCT CustID) AS CustIDList
        FROM CTS_DataCenter.MatchMonitorTransLive AS mmt
		WHERE  mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam
				AND EXISTS (SELECT 1 FROM Temp_FixedTransRange AS tmp WHERE mmt.TransID BETWEEN tmp.MinTransID AND MaxTransID);
		
     ELSE 
		SELECT MAX(TransDate)
		INTO lv_MaxTransDate
		FROM CTS_DataCenter.MatchMonitorTransNonLive AS mmt
		WHERE mmt.TransID = ip_MaxTransID;   
        
        SELECT s.ParameterValue
        INTO lv_LastTransID
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 101;
	
        INSERT INTO Temp_FixedTransRange (MinTransID, MaxTransID)
        SELECT TransID, MaxTransID1
		FROM (
				SELECT  
					TransDate, TransID, CustID, Stake, Odds
				,	MAX(TransID) OVER w1 MaxTransID1
				,	MAX(TransDate) OVER w1  AS LastTransDate1
				,	MIN(Odds) OVER w1 AS MinOdds1
				, 	MAX(Odds) OVER w1  AS MaxOdds1
				,	SUM(CASE WHEN Stake > lv_Rule_HighStake THEN 1 ELSE 0 END) OVER w1  AS TotalHighStake1
				,	COUNT(1) OVER w1  AS TotalTrans1
			   FROM CTS_DataCenter.MatchMonitorTransNonLive AS mmt
			   WHERE  mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam
					AND mmt.TransID > lv_LastTransID AND mmt.TransID <= ip_MaxTransID AND mmt.StatusRule02 = 0
			   WINDOW w1 AS (ORDER BY TransDate RANGE BETWEEN CURRENT ROW AND INTERVAL lv_Rule_Duration MINUTE  FOLLOWING)						
			) AS tmpTs
        WHERE tmpTs.TotalTrans1 > lv_Rule_TotalTicket
			AND (tmpTs.TotalHighStake1/tmpTs.TotalTrans1) > lv_Rule_HighStakePercent 
			AND (tmpTs.MaxOdds1 - tmpTs.MinOdds1)*100 BETWEEN lv_Rule_OddsSpread_Min AND lv_Rule_OddsSpread_Max;

		SELECT CONST_REASON AS Reason
			,	GROUP_CONCAT(DISTINCT TransID) AS TransIDList
            ,	GROUP_CONCAT(DISTINCT CustID) AS CustIDList
        FROM CTS_DataCenter.MatchMonitorTransNonLive AS mmt
		WHERE  mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam
				AND EXISTS (SELECT 1 FROM Temp_FixedTransRange AS tmp WHERE mmt.TransID BETWEEN tmp.MinTransID AND MaxTransID);	
 
	END IF;
END$$
DELIMITER ;