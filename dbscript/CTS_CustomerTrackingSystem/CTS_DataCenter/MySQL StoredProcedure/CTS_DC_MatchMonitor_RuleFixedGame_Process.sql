/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleFixedGame_Process`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleFixedGame_Process`(
		IN ip_LiveIndicator		BOOLEAN
	,	IN ip_MaxSequenceID		BIGINT UNSIGNED
	,	IN ip_MatchID			INT UNSIGNED
    ,	IN ip_ScoreDiff			INT 
    ,	IN ip_BettypeID			INT UNSIGNED    
    ,	IN ip_BetID				BIGINT
    ,	IN ip_HDP				DECIMAL (8,4)
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
            - 20220726@Casey.Huynh: Handle Duaration in 7 SECOND [Redmine ID: #177139]
            - 20220815@Casey.Huynh: Scale Out DB [Redmine ID: #176472]
            - 20221023@Casey.Huynh: Adjust Odds Range Rule, fix Data Type HighStake, Get Trans >= lv_FromTransDate for Non-Live [Redmine ID: #179065]
            - 20221205@Casey.Huynh: Rename Table [Redmine ID: #181205]
		Param's Explanation (filtered by):	

		Example:
			CALL CTS_DC_MatchMonitor_RuleFixedGame_Process(@ip_LiveIndicator:=0,@ip_MaxSequenceID:=@op_MaxSequenceID,@ip_MatchID:=110100,@ip_ScoreDiff:=-2,@ip_BettypeID:=1,@ip_BetID:=0, @HDP=-0.2500, @ip_Betteam:='h');
	*/
    
    DECLARE	CONST_RULE_GROUPID_FIXEDGAME TINYINT DEFAULT 2;

    DECLARE	lv_SportType					INT;
    DECLARE	lv_IsMajorLeague				BOOLEAN;
    DECLARE lv_MaxTransID 					BIGINT UNSIGNED;
    DECLARE lv_MaxTransDate 				DATETIME(3);
	DECLARE lv_LastTransDate 				DATETIME(3);
    DECLARE lv_FromTransDate 				DATETIME(3);
    DECLARE lv_LastSequenceID 				BIGINT UNSIGNED;
    
    DECLARE	lv_Rule_TotalTicket				SMALLINT; 
    DECLARE	lv_Rule_HighStake				SMALLINT;
    DECLARE	lv_Rule_HighStakeTicketPercent	DECIMAL(6,2);    
	DECLARE	lv_Rule_TimeStep				SMALLINT; 
    DECLARE	lv_Rule_OddsSpread				SMALLINT;
    DECLARE	lv_Rule_Reason					TINYINT;
	
    #============DEBUG LOG============================================================
    DECLARE SPName VARCHAR(200) DEFAULT 'CTS_DC_MatchMonitor_RuleFixedGame_Process';
	INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
    SELECT SPName, CURRENT_TIMESTAMP(),CONCAT('ip_LiveIndicator:',ip_LiveIndicator,',ip_MaxSequenceID:',ip_MaxSequenceID
		,',ip_MatchID:',ip_MatchID,',ip_ScoreDiff:',ip_ScoreDiff,',ip_BettypeID:',',ip_BetID:',ip_BetID,',ip_HDP:',ip_HDP,',ip_Betteam:',ip_Betteam); 
    #================================================================================
    
    DROP TEMPORARY TABLE IF EXISTS Temp_FixedTransRange;
    CREATE TEMPORARY TABLE Temp_FixedTransRange(
			MinTransID	BIGINT UNSIGNED
        ,	MaxTransID	BIGINT	UNSIGNED
        
        ,	PRIMARY KEY Temp_FixedTransRange(MinTransID,MaxTransID)
	);   
    
    #===GET RULE FROM SystemParameter=====
    
    IF (ip_LiveIndicator = 1) THEN
        
        SELECT s.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 100;        
        
		SELECT mms.SportType, mms.IsMajorLeague
		INTO lv_SportType, lv_IsMajorLeague
		FROM CTS_DataCenter.MatchMonitorStagingFixedGameLive AS mms
		WHERE mms.SequenceID > lv_LastSequenceID AND mms.MatchID = ip_MatchID
        LIMIT 1;   
        
		SELECT mst.TimeStep, mst.TotalTicket, mst.HighStake, mst.HighStakeTicketPercent, mst.OddsSpread, mst.Reason
        INTO lv_Rule_TimeStep, lv_Rule_TotalTicket, lv_Rule_HighStake, lv_Rule_HighStakeTicketPercent, lv_Rule_OddsSpread, lv_Rule_Reason  
        FROM CTS_DataCenter.MatchMonitorRuleSetting AS mst
        WHERE mst.SportType = lv_SportType AND  mst.LeagueType = lv_IsMajorLeague AND mst.RuleGroupID = CONST_RULE_GROUPID_FIXEDGAME AND mst.RuleStatus = 1;     
        
        SELECT TIMESTAMPADD(SECOND, lv_Rule_TimeStep, TransDate)
        INTO lv_FromTransDate
        FROM CTS_DataCenter.MatchMonitorStagingFixedGameLive AS mmt
		WHERE mmt.MatchID = ip_MatchID AND mmt.ScoreDiff = ip_ScoreDiff AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam AND mmt.Hdp = ip_HDP
		ORDER BY TransDate
        LIMIT 1;

        INSERT INTO Temp_FixedTransRange (MinTransID, MaxTransID)
        SELECT MinTransID1, TransID
		FROM (
				SELECT TransDate, TransID, CustID, Stake, Odds
					,	MIN(TransID) OVER w1 MinTransID1
					,	MIN(Odds) OVER w1 AS MinOdds1
					, 	MAX(Odds) OVER w1  AS MaxOdds1
					,	SUM(CASE WHEN Stake > lv_Rule_HighStake THEN 1 ELSE 0 END) OVER w1  AS TotalHighStake1
					,	COUNT(1) OVER w1  AS TotalTrans1
			   FROM CTS_DataCenter.MatchMonitorStagingFixedGameLive AS mmt
			   WHERE  mmt.MatchID = ip_MatchID AND mmt.ScoreDiff = ip_ScoreDiff AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam AND mmt.Hdp = ip_HDP
					AND mmt.SequenceID > lv_LastSequenceID AND mmt.SequenceID <= ip_MaxSequenceID
			   WINDOW w1 AS (ORDER BY TransDate DESC RANGE BETWEEN CURRENT ROW AND INTERVAL lv_Rule_TimeStep SECOND FOLLOWING)						
			) AS tmpTs
        WHERE tmpTs.TotalTrans1 > lv_Rule_TotalTicket
			AND (tmpTs.TotalHighStake1/tmpTs.TotalTrans1) > lv_Rule_HighStakeTicketPercent 
			AND (tmpTs.MaxOdds1 - tmpTs.MinOdds1)*100 >= lv_Rule_OddsSpread
            AND tmpTs.TransDate >= lv_FromTransDate;
            
		SELECT lv_Rule_Reason AS Reason
			,	GROUP_CONCAT(DISTINCT TransID) AS TransIDList
            ,	GROUP_CONCAT(DISTINCT CustID) AS CustIDList
        FROM CTS_DataCenter.MatchMonitorStagingFixedGameLive AS mmt
		WHERE  mmt.MatchID = ip_MatchID AND mmt.ScoreDiff = ip_ScoreDiff AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam AND mmt.Hdp = ip_HDP
				AND EXISTS (SELECT 1 FROM Temp_FixedTransRange AS tmp WHERE mmt.TransID BETWEEN tmp.MinTransID AND MaxTransID);	
 
	END IF;
 
    IF (ip_LiveIndicator = 0) THEN
        
        SELECT s.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 101;        
        
		SELECT mms.SportType, mms.IsMajorLeague
		INTO lv_SportType, lv_IsMajorLeague
		FROM CTS_DataCenter.MatchMonitorStagingFixedGameNonLive AS mms
		WHERE mms.SequenceID > lv_LastSequenceID AND mms.MatchID = ip_MatchID
        LIMIT 1;   
        
		SELECT mst.TimeStep, mst.TotalTicket, mst.HighStake, mst.HighStakeTicketPercent, mst.OddsSpread, mst.Reason
        INTO lv_Rule_TimeStep, lv_Rule_TotalTicket, lv_Rule_HighStake, lv_Rule_HighStakeTicketPercent, lv_Rule_OddsSpread, lv_Rule_Reason  
        FROM CTS_DataCenter.MatchMonitorRuleSetting AS mst
        WHERE mst.SportType = lv_SportType AND  mst.LeagueType = lv_IsMajorLeague AND mst.RuleGroupID = CONST_RULE_GROUPID_FIXEDGAME AND mst.RuleStatus = 1;    
        
        SELECT TIMESTAMPADD(SECOND, lv_Rule_TimeStep, TransDate)
        INTO lv_FromTransDate
        FROM CTS_DataCenter.MatchMonitorStagingFixedGameNonLive AS mmt
		WHERE mmt.MatchID = ip_MatchID AND mmt.ScoreDiff = ip_ScoreDiff AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam AND mmt.Hdp = ip_HDP
		ORDER BY TransDate
        LIMIT 1;

        INSERT INTO Temp_FixedTransRange (MinTransID, MaxTransID)
        SELECT MinTransID1, TransID
		FROM (
				SELECT TransDate, TransID, CustID, Stake, Odds
					,	MIN(TransID) OVER w1 MinTransID1
					,	MIN(Odds) OVER w1 AS MinOdds1
					, 	MAX(Odds) OVER w1  AS MaxOdds1
					,	SUM(CASE WHEN Stake > lv_Rule_HighStake THEN 1 ELSE 0 END) OVER w1  AS TotalHighStake1
					,	COUNT(1) OVER w1  AS TotalTrans1
			   FROM CTS_DataCenter.MatchMonitorStagingFixedGameNonLive AS mmt
			   WHERE  mmt.MatchID = ip_MatchID AND mmt.ScoreDiff = ip_ScoreDiff AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam AND mmt.Hdp = ip_HDP
					AND mmt.SequenceID > lv_LastSequenceID AND mmt.SequenceID <= ip_MaxSequenceID
			   WINDOW w1 AS (ORDER BY TransDate DESC RANGE BETWEEN CURRENT ROW AND INTERVAL lv_Rule_TimeStep SECOND FOLLOWING)						
			) AS tmpTs
        WHERE tmpTs.TotalTrans1 > lv_Rule_TotalTicket
			AND (tmpTs.TotalHighStake1/tmpTs.TotalTrans1) > lv_Rule_HighStakeTicketPercent 
			AND (tmpTs.MaxOdds1 - tmpTs.MinOdds1)*100 >= lv_Rule_OddsSpread
            AND tmpTs.TransDate >= lv_FromTransDate;
        
        SELECT lv_Rule_Reason AS Reason
			,	tmp.TransIDList
            ,	tmp.CustIDList
        FROM (
				SELECT  GROUP_CONCAT(DISTINCT TransID) AS TransIDList
					,	GROUP_CONCAT(DISTINCT CustID) AS CustIDList
				FROM CTS_DataCenter.MatchMonitorStagingFixedGameNonLive AS mmt
				WHERE  mmt.MatchID = ip_MatchID AND mmt.ScoreDiff = ip_ScoreDiff AND mmt.BettypeID = ip_BettypeID AND mmt.BetID = ip_BetID AND mmt.Betteam = ip_Betteam AND mmt.Hdp = ip_HDP
						AND EXISTS (SELECT 1 FROM Temp_FixedTransRange AS tmp WHERE mmt.TransID BETWEEN tmp.MinTransID AND MaxTransID)
				) AS tmp
		WHERE tmp.TransIDList IS NOT NULL;	
 
	END IF;
END$$
DELIMITER ;

