/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleArbitrage_StagingClean`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleArbitrage_StagingClean`(
		IN ip_LiveIndicator	BOOLEAN
	,	IN ip_MaxSequenceID	BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	202212216@Casey.Huynh
		Task :		Match Monitor Arbitrage Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	202212216@Casey.Huynh: Created [Redmine ID: 179502]
            -	20230109@Casey.Huynh: UpdateSoreDiff [Redmine ID: #182637]
            
		Param's Explanation (filtered by):
			CALL CTS_DC_MatchMonitor_RuleArbitrage_StagingClean(0,2);
		Example:			
	*/
    DECLARE CONS_LOG 			TINYINT DEFAULT 0; #0:LogOff, 1:LogOn
    DECLARE CONST_RULE_GROUPID	INT DEFAULT 5;
    
	DECLARE	lv_MinTime			DATETIME(3);
    DECLARE	lv_MaxTime			DATETIME(3);  
	DECLARE	lv_LastTransID 		BIGINT;   
	DECLARE lv_Reason			INT DEFAULT 0; #Group Betting
    DECLARE lv_LastSequenceID	INT; #Group Betting
	
    #==================LOG=======================================================
    DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_RuleArbitrage_StagingClean';
    IF CONS_LOG = 1 THEN     
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), CONCAT('@ip_LiveIndicator:=',ip_LiveIndicator,',@ip_MaxSequenceID:=',ip_MaxSequenceID);
    END IF;
    #==================LOG=======================================================
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitorRuleSetting;
	CREATE TEMPORARY TABLE Temp_MatchMonitorRuleSetting(
			SportType INT
		,	IsMajorLeague BOOLEAN
        ,	TimeStep INT
		
		,	PRIMARY KEY PK_Temp_MatchMonitorRuleSetting(SportType,IsMajorLeague )
	);
	
    INSERT INTO Temp_MatchMonitorRuleSetting(SportType, IsMajorLeague, TimeStep)
    SELECT	s.SportType
		,	s.LeagueType
        ,	s.TimeStep
    FROM CTS_DataCenter.MatchMonitorRuleSetting AS s
    WHERE s.RuleGroupID = CONST_RULE_GROUPID
		AND s.RuleStatus = 1;

    DROP TEMPORARY TABLE IF EXISTS Temp_LastGroup;
    CREATE TEMPORARY TABLE Temp_LastGroup
    (
			MatchID INT
        ,	ScoreDiff INT
        ,	BettypeID INT
        ,	BetID BIGINT
        ,	Betteam VARCHAR(10)
        ,	HDP	DECIMAL(8,2)
        ,   GroupID INT
        
        ,	PRIMARY KEY (MatchID,ScoreDiff,BettypeID, BetID, Betteam, HDP, GroupID)
    );

    #======Clean Staging=================================================
        
    IF (ip_LiveIndicator = 0) THEN        
		SELECT 	MAX(mms.TransDate) , MAX(mms.TransID)
		INTO 	lv_MaxTime, lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorStagingArbitrageNonLive AS mms
        WHERE	mms.SequenceID = ip_MaxSequenceID;      
		
		SELECT  MIN(mms.TransDate) 
		INTO 	lv_MinTime
		FROM	CTS_DataCenter.MatchMonitorStagingArbitrageNonLive AS mms
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType AND mms.IsMajorLeague = tmpRs.IsMajorLeague
		WHERE   mms.TransDate > TIMESTAMPADD(SECOND, -tmpRs.TimeStep, lv_MaxTime);  
		
		INSERT INTO Temp_LastGroup(MatchID, ScoreDiff, BettypeID, BetID, Betteam, HDP, GroupID)
		SELECT 	DISTINCT mms.MatchID,  mms.ScoreDiff, mms.BettypeID, mms.BetID, mms.Betteam, HDP, mms.GroupID
		FROM 	CTS_DataCenter.MatchMonitorStagingArbitrageNonLive mms
		WHERE	mms.TransDate >= lv_MinTime AND mms.GroupID <> 0;
	
		DELETE mms
		FROM CTS_DataCenter.MatchMonitorStagingArbitrageNonLive AS mms            
			LEFT JOIN Temp_LastGroup AS tmpTg ON mms.MatchID = tmpTg.MatchID AND mms.ScoreDiff = tmpTg.ScoreDiff AND mms.BettypeID = tmpTg.BettypeID AND mms.BetID = tmpTg.BetID AND mms.Betteam = tmpTg.Betteam  AND mms.HDP = tmpTg.HDP AND mms.GroupID = tmpTg.GroupID
		WHERE	mms.TransDate < lv_MinTime  AND tmpTg.GroupID IS NULL;
            
		IF lv_LastTransID > 0 THEN	
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = ip_MaxSequenceID
			WHERE 	sys.ParameterID = 128;
		END IF;
		
	END IF;
    
END$$
DELIMITER ;
