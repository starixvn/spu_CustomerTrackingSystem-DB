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
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Insert trans ticket to Staging table
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 159195]
            -	20220110@Casey.Huynh: Enhance MM, Add SportType, Betteam, BetID [Redmine ID: 166986]
            -	20220815@Casey.Huynh: Scale Out DB [Redmine ID: #176472]
            -	202200929@Casey.Huynh: Seperate By Sport [Redmine ID: #178310]
            -	20221021@Casey.Huynh: Fixed Clean Data Staging [Redmine ID: #179427]
            -	20221027@Casey.Huynh: Seperate pool Staging [RedmineID: 179439]
            -	20221205@Casey.Huynh: Rename Table [Redmine ID: #179502]
		Param's Explanation (filtered by):
			CALL CTS_DC_MatchMonitor_RuleHedging_StagingClean(1,2);
		Example:
			
	*/
    DECLARE CONST_RULE_GROUPID INT DEFAULT 5;
    
	DECLARE	lv_MinTime 	DATETIME(3);
    DECLARE	lv_MaxTime 	DATETIME(3);  
	DECLARE	lv_LastTransID 		BIGINT;   
	DECLARE lv_Reason INT DEFAULT 0; #Group Betting
    DECLARE lv_LastSequenceID INT; #Group Betting
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitorRuleSetting;
	CREATE TEMPORARY TABLE Temp_MatchMonitorRuleSetting(
			SportType INT
		,	TimeStep INT
		
		,	PRIMARY KEY PK_Temp_MatchMonitorRuleSetting(SportType )
	);
    
    INSERT INTO Temp_MatchMonitorRuleSetting(SportType, TimeStep)
    SELECT	s.SportType
        ,	s.TimeStep
    FROM CTS_DataCenter.MatchMonitorRuleSetting AS s
    WHERE s.RuleGroupID = CONST_RULE_GROUPID;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LastGroup;
    CREATE TEMPORARY TABLE Temp_LastGroup
    (
			MatchID INT
        ,	ScoreDiff SMALLINT
        ,	BettypeID INT
        ,	BetID BIGINT
        ,	Betteam VARCHAR(10)
        ,	HDP	DECIMAL(8,2)
        ,   GroupID INT
        
        ,	PRIMARY KEY (MatchID,ScoreDiff,BettypeID, BetID, Betteam, GroupID)
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
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
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

    
END$$
DELIMITER ;
