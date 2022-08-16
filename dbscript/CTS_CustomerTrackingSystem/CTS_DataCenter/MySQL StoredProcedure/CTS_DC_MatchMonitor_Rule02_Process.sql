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
    DECLARE lv_LastTransID BIGINT UNSIGNED;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FixedTransRange;
    CREATE TEMPORARY TABLE Temp_FixedTransRange(
			MinTransID	BIGINT UNSIGNED
        ,	MaxTransID	BIGINT	UNSIGNED
	);

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
				,	SUM(CASE WHEN Stake > CONST_RULE_HIGHSTAKE THEN 1 ELSE 0 END) OVER w1  AS TotalHighStake1
				,	COUNT(1) OVER w1  AS TotalTrans1
			   FROM CTS_DataCenter.MatchMonitorTransLive AS mmt
			   WHERE  mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam
					AND mmt.TransID > lv_LastTransID AND mmt.TransID <= ip_MaxTransID AND mmt.StatusRule02 = 0
			   WINDOW w1 AS (ORDER BY TransDate RANGE BETWEEN CURRENT ROW AND INTERVAL CONST_RULE_DURATION MINUTE  FOLLOWING)						
			) AS tmpTs
        WHERE tmpTs.TotalTrans1 > CONST_RULE_TOTALTRANS
			AND (tmpTs.TotalHighStake1/tmpTs.TotalTrans1) > CONST_RULE_HIGHSTAKEPERCENT 
			AND tmpTs.MaxOdds1 - tmpTs.MinOdds1 BETWEEN CONST_RULE_ODDSPRESS_MIN AND CONST_RULE_ODDSPRESS_MAX;

        SELECT CONST_REASON AS Reason
			,	GROUP_CONCAT(DISTINCT TransID) AS TransList
            ,	GROUP_CONCAT(DISTINCT CustID) AS CustIDList
        FROM CTS_DataCenter.MatchMonitorTransLive AS mmt
		INNER JOIN 	Temp_FixedTransRange AS tmp ON mmt.TransID BETWEEN tmp.MinTransID AND MaxTransID
			   WHERE  mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam;
		
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
				,	SUM(CASE WHEN Stake >= CONST_RULE_HIGHSTAKE THEN 1 ELSE 0 END) OVER w1  AS TotalHighStake1
				,	COUNT(1) OVER w1  AS TotalTrans1
			   FROM CTS_DataCenter.MatchMonitorTransNonLive AS mmt
			   WHERE  mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam
					AND mmt.TransID > lv_LastTransID AND mmt.TransID <= ip_MaxTransID AND mmt.StatusRule02 = 0
			   WINDOW w1 AS (ORDER BY TransDate RANGE BETWEEN CURRENT ROW AND INTERVAL CONST_RULE_DURATION MINUTE  FOLLOWING)						
			) AS tmpTs
        WHERE tmpTs.TotalTrans1 >= CONST_RULE_TOTALTRANS
			AND (tmpTs.TotalHighStake1/tmpTs.TotalTrans1) >= CONST_RULE_HIGHSTAKEPERCENT 
			AND tmpTs.MaxOdds1 - tmpTs.MinOdds1 BETWEEN CONST_RULE_ODDSPRESS_MIN AND CONST_RULE_ODDSPRESS_MAX;

        SELECT CONST_REASON AS Reason
			,	GROUP_CONCAT(DISTINCT TransID) AS TransList
            ,	GROUP_CONCAT(DISTINCT CustID) AS CustIDList
        FROM CTS_DataCenter.MatchMonitorTransNonLive AS mmt
		INNER JOIN 	Temp_FixedTransRange AS tmp ON mmt.TransID BETWEEN tmp.MinTransID AND MaxTransID
			   WHERE  mmt.MatchID = ip_MatchID AND mmt.TotalScore = ip_TotalScore AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam; 		
 
	END IF;
END$$
DELIMITER ;