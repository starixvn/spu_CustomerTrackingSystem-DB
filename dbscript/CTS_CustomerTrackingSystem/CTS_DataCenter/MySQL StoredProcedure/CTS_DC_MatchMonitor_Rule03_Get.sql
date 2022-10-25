/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule03_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule03_Get`(
		IN	ip_LiveIndicator	BOOLEAN
	,	OUT	op_MaxSequenceID	BIGINT UNSIGNED
)
	SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	202200929@Casey.Huynh
		Task :		Match Monitor Rule for Soccer Hedging
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	202200929@Casey.Huynh: Created [Redmine ID: #178310]
            - 	202201021@Casey.Huynh: Group By Betteam [Redmine ID: #179439]
            
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_MatchMonitor_Rule03_Get_xtest(1,@MaxTrans);
	*/
	DECLARE lv_LastSequenceID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxSequenceID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_RuleGroupID TINYINT DEFAULT 3; #Rule 01
    DECLARE lv_NoOfRow 	INT DEFAULT 5000;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitorRuleSetting;
	CREATE TEMPORARY TABLE Temp_MatchMonitorRuleSetting(
			SportType INT
		,	TotalStake DECIMAL(20,4)
        ,	HighStake DECIMAL(20,4)
		
		,	PRIMARY KEY PK_Temp_MatchMonitorRuleSetting(SportType)
	);
    
    INSERT INTO Temp_MatchMonitorRuleSetting(SportType, TotalStake, HighStake)
    SELECT	s.SportType
        ,	s.TotalStake
        ,	s.HighStake
    FROM CTS_DataCenter.MatchMonitorRuleSetting AS s
    WHERE s.RuleGroupID = lv_RuleGroupID;
    
    SELECT s.ParameterValue
    INTO lv_NoOfRow
    FROM CTS_DataCenter.SystemParameter AS s
    WHERE s.ParameterID = 123;
    
	IF ip_LiveIndicator = 1 THEN    
		SELECT sys.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 120;
        
        SELECT MAX(tmp.SequenceID)
        INTO lv_MaxSequenceID
        FROM (SELECT mms.SequenceID FROM CTS_DataCenter.MatchMonitorStagingLive03 AS mms WHERE mms.SequenceID > lv_LastSequenceID ORDER BY mms.SequenceID LIMIT lv_NoOfRow) AS tmp;
        
        SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID,0) ;
                
        IF(lv_LastSequenceID < lv_MaxSequenceID) THEN          
			SELECT	mms.MatchID
				,	mms.TotalScore
				,	mms.BettypeID
                ,	mms.BetID
                ,	mms.Betteam
			FROM CTS_DataCenter.MatchMonitorStagingLive03 AS mms
				INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
            WHERE mms.SequenceID <= lv_MaxSequenceID AND mms.Stake >= tmpRs.HighStake
			GROUP BY mms.MatchID, mms.TotalScore, mms.BettypeID, mms.BetID
			HAVING COUNT(DISTINCT mms.CustID) > 1 AND SUM(mms.Stake) >= MIN(tmpRs.TotalStake);      
            
		END IF;
	ELSE
		SELECT sys.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 121;
        
        SELECT MAX(tmp.SequenceID)
        INTO lv_MaxSequenceID
        FROM (SELECT mms.SequenceID FROM CTS_DataCenter.MatchMonitorStagingNonLive03 AS mms WHERE mms.SequenceID > lv_LastSequenceID ORDER BY mms.SequenceID  LIMIT lv_NoOfRow) AS tmp;
		
		SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID, 0);        
        
        IF(lv_LastSequenceID < lv_MaxSequenceID) THEN            
			SELECT	mms.MatchID
				,	mms.TotalScore
				,	mms.BettypeID
                ,	mms.BetID
                ,	mms.Betteam
			FROM CTS_DataCenter.MatchMonitorStagingNonLive03 AS mms
				INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
            WHERE mms.SequenceID <= lv_MaxSequenceID AND mms.Stake >= tmpRs.HighStake
			GROUP BY mms.MatchID, mms.TotalScore, mms.BettypeID, mms.BetID
			HAVING COUNT(DISTINCT mms.CustID) > 1 AND SUM(mms.Stake) >= MIN(tmpRs.TotalStake);            
		END IF;        
	END IF;
 
END$$
DELIMITER ;
