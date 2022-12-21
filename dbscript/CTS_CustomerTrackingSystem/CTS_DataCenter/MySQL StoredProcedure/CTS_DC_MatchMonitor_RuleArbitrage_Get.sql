/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleArbitrage_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleArbitrage_Get`(
		IN	ip_LiveIndicator	BOOLEAN
	,	OUT	op_MaxSequenceID	BIGINT UNSIGNED
)
	SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210924@Casey.Huynh: Created [Redmine ID: 159195]
            -	20220110@Casey.Huynh: Enhance MM(SportType, Betteam, BetID), Return BetID [Redmine ID: 166986]
            -	20220217@Casey.Huynh: Enhance MM, Update TO >= 1000 [Redmine ID: 168736]
            -	20220815@Casey.Huynh: Scale Out DB [Redmine ID: #176472]
            -	202200929@Casey.Huynh: Seperate By Sport [Redmine ID: #178310]
            - 	202201021@Casey.Huynh: Group By Betteam [Redmine ID: #179439]
            -	20221205@Casey.Huynh: Rename Table [Redmine ID: #179502]
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_MatchMonitor_RuleArbitrage_Get(0,@op_MaxSequenceID);
			
	*/
	DECLARE lv_LastSequenceID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxSequenceID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_RuleGroupID TINYINT DEFAULT 1; #Rule 01
    DECLARE lv_BatchSize 	INT DEFAULT 5000;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitorRuleSetting;
	CREATE TEMPORARY TABLE Temp_MatchMonitorRuleSetting(
			SportType INT
		,	TotalStake DECIMAL(20,4)
		
		,	PRIMARY KEY PK_Temp_MatchMonitorRuleSetting(SportType )
	);
    
    INSERT INTO Temp_MatchMonitorRuleSetting(SportType, TotalStake)
    SELECT	s.SportType
        ,	s.TotalStake
    FROM CTS_DataCenter.MatchMonitorRuleSetting AS s
    WHERE s.RuleGroupID = lv_RuleGroupID;
    
    SELECT s.ParameterValue
    INTO lv_BatchSize
    FROM CTS_DataCenter.SystemParameter AS s
    WHERE s.ParameterID = 129;
    
	IF ip_LiveIndicator = 0 THEN    
		
		SELECT sys.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 128;
        
        SELECT MAX(tmp.SequenceID)
        INTO lv_MaxSequenceID
        FROM (SELECT mms.SequenceID FROM CTS_DataCenter.MatchMonitorStagingArbitrageNonLive AS mms WHERE mms.SequenceID > lv_LastSequenceID AND mms.GroupID >= 0 ORDER BY mms.SequenceID  LIMIT lv_BatchSize) AS tmp;
		
		SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID, 0);        
        
        IF(lv_LastSequenceID < lv_MaxSequenceID) THEN            
			SELECT	mms.MatchID
				,	mms.IsMajorLeague
				,	mms.ScoreDiff
				,	mms.BettypeID
                ,	mms.BetID
                ,	mms.HDP
			FROM CTS_DataCenter.MatchMonitorStagingArbitrageNonLive AS mms
				INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
            WHERE mms.SequenceID <= lv_MaxSequenceID
			GROUP BY mms.MatchID, mms.ScoreDiff, mms.IsMajorLeague, mms.BettypeID, mms.BetID, mms.HDP
			HAVING COUNT(DISTINCT mms.CustID) > 1 
					AND COUNT(DISTINCT mms.Betteam) = 2;            
		END IF;        
	END IF;
 
END$$
DELIMITER ;
