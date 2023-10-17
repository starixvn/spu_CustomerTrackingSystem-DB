/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleGroupBetting_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleGroupBetting_Get`(
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
            -	20230221@Casey.Huynh: Update Rule, The same Choice [Redmine ID: #184041]
            -	20231016@Casey.Huynh:	Enhance Rule for BasketBall. Adjust Group Stake to 300, Add AssociationByIP, ShareMatch(3 Match(last 7 day) [Redmine ID: 195473]
            
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_MatchMonitor_RuleGroupBetting_Get(1,@op_MaxSequenceID);
			
	*/
    DECLARE CONS_LOG 					TINYINT DEFAULT 0; #0:LogOff, 1:LogOn
    
	DECLARE lv_LastSequenceID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxSequenceID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_RuleGroupID TINYINT DEFAULT 1; #Rule 01
    DECLARE lv_NoOfRow 	INT DEFAULT 5000;
    
    #==================LOG=======================================================
    DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_RuleGroupBetting_Get';
    IF CONS_LOG = 1 THEN     
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), CONCAT('@ip_LiveIndicator:=',ip_LiveIndicator);
    END IF;
    #==================LOG======================================================= 
    
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
    WHERE s.RuleGroupID = lv_RuleGroupID AND s.RuleStatus = 1;
    
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
        FROM (SELECT mms.SequenceID FROM CTS_DataCenter.MatchMonitorStagingGroupBettingLive AS mms WHERE mms.SequenceID > lv_LastSequenceID ORDER BY mms.SequenceID LIMIT lv_NoOfRow) AS tmp;
        
        SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID,0) ;
        
        IF(lv_LastSequenceID < lv_MaxSequenceID) THEN    
     		SELECT	mms.MatchID
				,	mms.ScoreDiff
				,	mms.BettypeID
                ,	mms.BetID
                ,	mms.Betteam
				,	GROUP_CONCAT(DISTINCT mms.CustID) AS CustIDList
			FROM CTS_DataCenter.MatchMonitorStagingGroupBettingLive AS mms
				INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
            WHERE mms.SequenceID <= lv_MaxSequenceID
			GROUP BY mms.MatchID, mms.ScoreDiff, mms.BettypeID, mms.BetID, mms.Betteam
			HAVING COUNT(DISTINCT mms.CustID) > 1;      
            
		END IF;
	ELSE
		SELECT sys.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 48;
        
        SELECT MAX(tmp.SequenceID)
        INTO lv_MaxSequenceID
        FROM (SELECT mms.SequenceID FROM CTS_DataCenter.MatchMonitorStagingGroupBettingNonLive AS mms WHERE mms.SequenceID > lv_LastSequenceID AND mms.GroupID >= 0 ORDER BY mms.SequenceID  LIMIT lv_NoOfRow) AS tmp;
		
		SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID, 0);        
        
        IF(lv_LastSequenceID < lv_MaxSequenceID) THEN            
			SELECT	mms.MatchID
				,	mms.ScoreDiff
				,	mms.BettypeID
                ,	mms.BetID
                ,	mms.Betteam
                ,	GROUP_CONCAT(DISTINCT mms.CustID) AS CustIDList
			FROM CTS_DataCenter.MatchMonitorStagingGroupBettingNonLive AS mms
				INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
            WHERE mms.SequenceID <= lv_MaxSequenceID
			GROUP BY mms.MatchID, mms.ScoreDiff, mms.BettypeID, mms.BetID, mms.Betteam
			HAVING COUNT(DISTINCT mms.CustID) > 1;            
		END IF;        
	END IF;
 
END$$
DELIMITER ;
