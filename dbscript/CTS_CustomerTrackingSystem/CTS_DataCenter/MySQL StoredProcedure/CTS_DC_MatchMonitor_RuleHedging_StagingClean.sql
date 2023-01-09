/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleHedging_StagingClean`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleHedging_StagingClean`(
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
            -	20230109@Casey.Huynh: UpdateSoreDiff [Redmine ID: #182637]
		Param's Explanation (filtered by):
			CALL CTS_DC_MatchMonitor_RuleHedging_StagingClean(@ip_LiveIndicator:=1,@ip_MaxSequenceID:=2);
		Example:
			
	*/
    DECLARE CONS_LOG 			TINYINT DEFAULT 0; #0:LogOff, 1:LogOn
    DECLARE CONST_RULE_GROUPID  TINYINT DEFAULT 3; # Hedging
    
	DECLARE	lv_Last3mMinTime 	DATETIME(3);
    DECLARE	lv_Last3mMaxTime 	DATETIME(3);  
	DECLARE	lv_LastTransID 		BIGINT; 
	
    
    #==================LOG=======================================================
    DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_RuleHedging_StagingClean';
    IF CONS_LOG = 1 THEN     
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), CONCAT('@ip_LiveIndicator:=',ip_LiveIndicator,',@ip_MaxSequenceID:=',ip_MaxSequenceID);
    END IF;
    #==================LOG=======================================================   
    
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
    WHERE s.RuleGroupID = CONST_RULE_GROUPID AND s.RuleStatus = 1;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Last3mTransGroup;
    CREATE TEMPORARY TABLE Temp_Last3mTransGroup
    (
			MatchID INT
        ,	ScoreDiff INT
        ,	BettypeID INT
        ,	BetID BIGINT
        ,	Betteam VARCHAR(10)
        ,   GroupID INT
        
        ,	PRIMARY KEY (MatchID,ScoreDiff,BettypeID, BetID, Betteam, GroupID)
    );

    #======Clean Staging=================================================
    IF (ip_LiveIndicator = 1) THEN 		
		SELECT 	MAX(mms.TransDate) , MAX(mms.TransID)
		INTO 	lv_Last3mMaxTime, lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorStagingHedgingLive AS mms
        WHERE	mms.SequenceID <= ip_MaxSequenceID;      
		
		SELECT  MIN(mms.TransDate) 
		INTO 	lv_Last3mMinTime
		FROM	CTS_DataCenter.MatchMonitorStagingHedgingLive AS mms
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
		WHERE   mms.TransDate > TIMESTAMPADD(SECOND, -tmpRs.TimeStep, lv_Last3mMaxTime);  
		
		INSERT INTO Temp_Last3mTransGroup(MatchID, ScoreDiff, BettypeID, BetID, Betteam, GroupID)
		SELECT 	DISTINCT mms.MatchID,  mms.ScoreDiff, mms.BettypeID, mms.BetID, mms.Betteam, mms.GroupID
		FROM 	CTS_DataCenter.MatchMonitorStagingHedgingLive mms
		WHERE	mms.TransDate >= lv_Last3mMinTime AND mms.GroupID <> 0; 
		
		DELETE mms
		FROM CTS_DataCenter.MatchMonitorStagingHedgingLive AS mms            
			LEFT JOIN Temp_Last3mTransGroup AS tmpTg ON mms.MatchID = tmpTg.MatchID AND mms.ScoreDiff = tmpTg.ScoreDiff AND mms.BettypeID = tmpTg.BettypeID AND mms.BetID = tmpTg.BetID AND mms.Betteam = tmpTg.Betteam AND mms.GroupID = tmpTg.GroupID
		WHERE	mms.TransDate < lv_Last3mMinTime  AND tmpTg.GroupID IS NULL;
		
		IF lv_LastTransID > 0 THEN	
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = ip_MaxSequenceID
			WHERE 	sys.ParameterID = 120;
		END IF;        
	END IF;
    
    IF (ip_LiveIndicator = 0) THEN        
		SELECT 	MAX(mms.TransDate) , MAX(mms.TransID)
		INTO 	lv_Last3mMaxTime, lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorStagingHedgingNonLive AS mms
        WHERE	mms.SequenceID <= ip_MaxSequenceID;      
		
		SELECT  MIN(mms.TransDate) 
		INTO 	lv_Last3mMinTime
		FROM	CTS_DataCenter.MatchMonitorStagingHedgingNonLive AS mms
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
		WHERE   mms.TransDate > TIMESTAMPADD(SECOND, -tmpRs.TimeStep, lv_Last3mMaxTime);  
		
		INSERT INTO Temp_Last3mTransGroup(MatchID, ScoreDiff, BettypeID, BetID, Betteam, GroupID)
		SELECT 	DISTINCT mms.MatchID,  mms.ScoreDiff, mms.BettypeID, mms.BetID, mms.Betteam, mms.GroupID
		FROM 	CTS_DataCenter.MatchMonitorStagingHedgingNonLive mms
		WHERE	mms.TransDate >= lv_Last3mMinTime AND mms.GroupID <> 0;
		
		DELETE mms
		FROM CTS_DataCenter.MatchMonitorStagingHedgingNonLive AS mms            
			LEFT JOIN Temp_Last3mTransGroup AS tmpTg ON mms.MatchID = tmpTg.MatchID AND mms.ScoreDiff = tmpTg.ScoreDiff AND mms.BettypeID = tmpTg.BettypeID AND mms.BetID = tmpTg.BetID AND mms.Betteam = tmpTg.Betteam  AND mms.GroupID = tmpTg.GroupID
		WHERE	mms.TransDate < lv_Last3mMinTime  AND tmpTg.GroupID IS NULL;
            
		IF lv_LastTransID > 0 THEN	
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = ip_MaxSequenceID
			WHERE 	sys.ParameterID = 121;
		END IF;
		
	END IF;
    
END$$
DELIMITER ;
