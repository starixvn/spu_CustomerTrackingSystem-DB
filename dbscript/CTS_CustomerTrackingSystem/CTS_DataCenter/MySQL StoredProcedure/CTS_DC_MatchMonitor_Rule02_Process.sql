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
		/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220726@Casey.Huynh: Created [Redmine ID: #175700]
            
		Param's Explanation (filtered by):	

		Example:
			CALL CTS_DC_MatchMonitor_Rule02_Process(@ip_LiveIndicator:=1,@ip_MaxTransID:=0,@ip_MatchID:=1,@ip_TotalScore:=0,@ip_BettypeID:=1,@ip_BetID:=0,@ip_Betteam:='a');
	*/
    DECLARE	CONST_RULE_TOTALTRANS			SMALLINT DEFAULT 40; 
    DECLARE	CONST_RULE_HIGHSTAKE			SMALLINT DEFAULT 500;
    DECLARE	CONST_RULE_HIGHSTAKEPERCENT		DECIMAL(1,1) DEFAULT 0.5;    
	DECLARE	CONST_RULE_DURATION				SMALLINT DEFAULT 7; # 7 minutes
    DECLARE	CONST_RULE_ODDSPRESS_MIN		SMALLINT DEFAULT 10; 
    DECLARE	CONST_RULE_ODDSPRESS_MAX		SMALLINT DEFAULT 20;
    DECLARE	CONST_REASON					TINYINT DEFAULT 3; #0: Group Betting, 1: Headging, 2: Arbitrage, 3: FixedGame
    
    DECLARE lv_MaxTransID BIGINT UNSIGNED;
    DECLARE lv_MaxTransDate DATETIME(3);
	DECLARE lv_LastTransDate DATETIME(3);
	
    IF (ip_LiveIndicator = 1) THEN
		
		SELECT MAX(TransID), MAX(TransDate)
		INTO lv_MaxTransID, lv_MaxTransDate
		FROM CTS_DataCenter.MatchMonitorTransLive AS mmt
		WHERE mmt.TransID;   
		
		SELECT	CONST_REASON AS Reason
			,	GROUP_CONCAT(tmpRg.TransID) AS TransIDList
			,	GROUP_CONCAT(tmpRg.CustID) AS CustIDList
		FROM (
			SELECT	(CASE WHEN 	(tmpTs.TotalTrans1 >= CONST_RULE_TOTALTRANS
								AND (tmpTs.TotalHighStake1/tmpTs.TotalTrans1) >= CONST_RULE_HIGHSTAKEPERCENT 
								AND tmpTs.MaxOdds1 - tmpTs.MinOdds1 BETWEEN CONST_RULE_ODDSPRESS_MIN AND CONST_RULE_ODDSPRESS_MAX)
								OR (tmpTs.TotalTrans2 >= CONST_RULE_TOTALTRANS
								AND (tmpTs.TotalHighStake2/tmpTs.TotalTrans2) >= CONST_RULE_HIGHSTAKEPERCENT 
								AND tmpTs.MaxOdds2 - tmpTs.MinOdds2 BETWEEN CONST_RULE_ODDSPRESS_MIN AND CONST_RULE_ODDSPRESS_MAX)
								THEN 1 ELSE 0 END) AS IsFixedGame
				,	tmpTs.TransID
				,	tmpTs.CustID
			FROM (
					SELECT  
						TransDate, TransID, CustID, Stake, Odds
					,	MAX(TransID) OVER w1 MaxTransID1
					,	MAX(TransDate) OVER w1  AS LastTransDate1
					,	MIN(Odds) OVER w1 AS MinOdds1
					, 	MAX(Odds) OVER w1  AS MaxOdds1
					,	SUM(CASE WHEN Stake >= CONST_RULE_HIGHSTAKE THEN 1 ELSE 0 END) OVER w1  AS TotalHighStake1
					,	COUNT(1) OVER w1  AS TotalTrans1
					,	MIN(TransID) OVER w2 MinTransID2
					,	MIN(TransDate) OVER w2  AS FirstTransDate2
					,	MIN(Odds) OVER w2 AS MinOdds2
					, 	MAX(Odds) OVER w2  AS MaxOdds2
					,	SUM(CASE WHEN Stake >= CONST_RULE_HIGHSTAKE THEN 1 ELSE 0 END) OVER w2  AS TotalHighStake2
					,	COUNT(1) OVER w2  AS TotalTrans2
				   FROM CTS_DataCenter.MatchMonitorTransLive AS mmt
				   WHERE  mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam
						AND mmt.TransID > ip_MaxTransID AND mmt.TransID <= lv_MaxTransID AND mmt.StatusRule02 = 0
				   WINDOW w1 AS (ORDER BY TransDate RANGE BETWEEN CURRENT ROW AND INTERVAL CONST_RULE_DURATION MINUTE  FOLLOWING)
						, w2 AS (ORDER BY TransDate RANGE BETWEEN INTERVAL CONST_RULE_DURATION MINUTE  PRECEDING AND CURRENT ROW)
				) AS tmpTs
		) AS tmpRg
		WHERE tmpRg.IsFixedGame = 1;    
	 
		 SELECT mmt.TransID AS LastTransID
		 FROM CTS_DataCenter.MatchMonitorTransLive AS mmt
		 WHERE mmt.TransDate < TIMESTAMPADD(MINUTE,-CONST_RULE_DURATION, lv_MaxTransDate)
		 ORDER BY TransID DESC
		 LIMIT 1 ;
     ELSE 
		SELECT MAX(TransID), MAX(TransDate)
		INTO lv_MaxTransID, lv_MaxTransDate
		FROM CTS_DataCenter.MatchMonitorTransNonLive AS mmt
		WHERE mmt.TransID;   
		
		SELECT	CONST_REASON AS Reason
			,	GROUP_CONCAT(tmpRg.TransID) AS TransIDList
			,	GROUP_CONCAT(tmpRg.CustID) AS CustIDList
		FROM (
			SELECT	(CASE WHEN 	(tmpTs.TotalTrans1 >= CONST_RULE_TOTALTRANS
								AND (tmpTs.TotalHighStake1/tmpTs.TotalTrans1) >= CONST_RULE_HIGHSTAKEPERCENT 
								AND tmpTs.MaxOdds1 - tmpTs.MinOdds1 BETWEEN CONST_RULE_ODDSPRESS_MIN AND CONST_RULE_ODDSPRESS_MAX)
								OR (tmpTs.TotalTrans2 >= CONST_RULE_TOTALTRANS
								AND (tmpTs.TotalHighStake2/tmpTs.TotalTrans2) >= CONST_RULE_HIGHSTAKEPERCENT 
								AND tmpTs.MaxOdds2 - tmpTs.MinOdds2 BETWEEN CONST_RULE_ODDSPRESS_MIN AND CONST_RULE_ODDSPRESS_MAX)
								THEN 1 ELSE 0 END) AS IsFixedGame
				,	tmpTs.TransID
				,	tmpTs.CustID
			FROM (
					SELECT  
						TransDate, TransID, CustID, Stake, Odds
					,	MAX(TransID) OVER w1 MaxTransID1
					,	MAX(TransDate) OVER w1  AS LastTransDate1
					,	MIN(Odds) OVER w1 AS MinOdds1
					, 	MAX(Odds) OVER w1  AS MaxOdds1
					,	SUM(CASE WHEN Stake >= CONST_RULE_HIGHSTAKE THEN 1 ELSE 0 END) OVER w1  AS TotalHighStake1
					,	COUNT(1) OVER w1  AS TotalTrans1
					,	MIN(TransID) OVER w2 MinTransID2
					,	MIN(TransDate) OVER w2  AS FirstTransDate2
					,	MIN(Odds) OVER w2 AS MinOdds2
					, 	MAX(Odds) OVER w2  AS MaxOdds2
					,	SUM(CASE WHEN Stake >= CONST_RULE_HIGHSTAKE THEN 1 ELSE 0 END) OVER w2  AS TotalHighStake2
					,	COUNT(1) OVER w2  AS TotalTrans2
				   FROM CTS_DataCenter.MatchMonitorTransNonLive AS mmt
				   WHERE  mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam
						AND mmt.TransID > ip_MaxTransID AND mmt.TransID <= lv_MaxTransID AND mmt.StatusRule02 = 0
				   WINDOW w1 AS (ORDER BY TransDate RANGE BETWEEN CURRENT ROW AND INTERVAL CONST_RULE_DURATION MINUTE  FOLLOWING)
						, w2 AS (ORDER BY TransDate RANGE BETWEEN INTERVAL CONST_RULE_DURATION MINUTE  PRECEDING AND CURRENT ROW)
				) AS tmpTs
		) AS tmpRg
		WHERE tmpRg.IsFixedGame = 1;    

	END IF;
END$$
DELIMITER ;