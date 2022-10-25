/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule01_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule01_Get`(
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
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_MatchMonitor_Rule01_Get(1,@op_MaxSequenceID);
			
	*/
	DECLARE lv_LastSequenceID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxSequenceID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_RuleGroupID TINYINT DEFAULT 1; #Rule 01
    DECLARE lv_NoOfRow 	INT DEFAULT 5000;
    
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
    INTO lv_NoOfRow
    FROM CTS_DataCenter.SystemParameter AS s
    WHERE s.ParameterID = 122;
    
	IF ip_LiveIndicator = 1 THEN    
		SELECT sys.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 47;
        
        SELECT MAX(tmp.SequenceID)
        INTO lv_MaxSequenceID
        FROM (SELECT mms.SequenceID FROM CTS_DataCenter.MatchMonitorStagingLive AS mms WHERE mms.SequenceID > lv_LastSequenceID ORDER BY mms.SequenceID LIMIT lv_NoOfRow) AS tmp;
        
        SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID,0) ;
        
        IF(lv_LastSequenceID < lv_MaxSequenceID) THEN    
     		SELECT	mms.MatchID
				,	mms.TotalScore
				,	mms.BettypeID
                ,	mms.BetID
			FROM CTS_DataCenter.MatchMonitorStagingLive AS mms
				INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
            WHERE mms.SequenceID <= lv_MaxSequenceID
			GROUP BY mms.MatchID, mms.TotalScore, mms.BettypeID, mms.BetID
			HAVING COUNT(DISTINCT mms.CustID) > 1 AND SUM(mms.Stake) >= MIN(tmpRs.TotalStake);      
            
		END IF;
	ELSE
		SELECT sys.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 48;
        
        SELECT MAX(tmp.SequenceID)
        INTO lv_MaxSequenceID
        FROM (SELECT mms.SequenceID FROM CTS_DataCenter.MatchMonitorStagingNonLive AS mms WHERE mms.SequenceID > lv_LastSequenceID AND mms.GroupID >= 0 ORDER BY mms.SequenceID  LIMIT lv_NoOfRow) AS tmp;
		
		SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID, 0);        
        
        IF(lv_LastSequenceID < lv_MaxSequenceID) THEN            
			SELECT	mms.MatchID
				,	mms.TotalScore
				,	mms.BettypeID
                ,	mms.BetID
			FROM CTS_DataCenter.MatchMonitorStagingNonLive AS mms
				INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
            WHERE mms.SequenceID <= lv_MaxSequenceID
			GROUP BY mms.MatchID, mms.TotalScore, mms.BettypeID, mms.BetID
			HAVING COUNT(DISTINCT mms.CustID) > 1 AND SUM(mms.Stake) >= MIN(tmpRs.TotalStake);            
		END IF;        
	END IF;
 
END$$
DELIMITER ;
