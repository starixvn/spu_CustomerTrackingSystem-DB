/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleIrrigation_StagingClean`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleIrrigation_StagingClean`(
		IN ip_LiveIndicator	BOOLEAN
	,	IN ip_MaxSequenceID	BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20211122@Casey.Huynh
		Task :		Match Monitor Rule Irrigation clean staging data
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20211122@Casey.Huynh: Created [Redmine ID: #179499]
            
		Param's Explanation (filtered by):	
			
		Example:
			CALL CTS_DC_MatchMonitor_RuleIrrigation_StagingClean(@ip_LiveIndicator:=1,@ip_MaxSequenceID:=0)
			
	*/
	DECLARE	CONST_GROUPID	TINYINT DEFAULT 4;
    DECLARE lv_LastMaxTime DATETIME(4);
    DECLARE lv_LastMinTime DATETIME(4);
    
    #===================LOG=======================================
    INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
    SELECT'CTS_DC_MatchMonitor_RuleIrrigation_StagingClean', current_timestamp(), CONCAT('ip_LiveIndicator:',ip_LiveIndicator,'op_MaxSequenceID:',ip_MaxSequenceID);
    
    
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
    WHERE s.RuleGroupID = CONST_GROUPID;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LastTransGroup;
    CREATE TEMPORARY TABLE Temp_LastTransGroup
    (
			MatchID INT
        ,	TotalScore SMALLINT
        ,	BettypeID INT
        ,	BetID BIGINT
        ,	Betteam VARCHAR(10)
        ,   GroupID INT
        
        ,	PRIMARY KEY (MatchID,TotalScore,BettypeID, BetID, Betteam, GroupID)
    );

    #======Clean Staging=================================================
    IF (ip_LiveIndicator = 0) THEN 		
		SELECT 	MAX(mms.TransDate) 
		INTO 	lv_LastMaxTime
		FROM	CTS_DataCenter.MatchMonitorStagingIrrigationNonLive AS mms
        WHERE	mms.SequenceID <= ip_MaxSequenceID;      
		
		SELECT  MIN(mms.TransDate) 
		INTO 	lv_LastMinTime
		FROM	CTS_DataCenter.MatchMonitorStagingIrrigationNonLive AS mms
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
		WHERE   mms.TransDate > TIMESTAMPADD(SECOND, -tmpRs.TimeStep, lv_LastMaxTime);  
		
		INSERT INTO Temp_LastTransGroup(MatchID, TotalScore, BettypeID, BetID, Betteam, GroupID)
		SELECT 	DISTINCT mms.MatchID,  mms.TotalScore, mms.BettypeID, mms.BetID, mms.Betteam, mms.GroupID
		FROM 	CTS_DataCenter.MatchMonitorStagingIrrigationNonLive mms
		WHERE	mms.TransDate >= lv_LastMinTime AND mms.GroupID <> 0; 
		
		DELETE mms
		FROM CTS_DataCenter.MatchMonitorStagingIrrigationNonLive AS mms            
			LEFT JOIN Temp_LastTransGroup AS tmpTg ON mms.MatchID = tmpTg.MatchID AND mms.TotalScore = tmpTg.TotalScore AND mms.BettypeID = tmpTg.BettypeID AND mms.BetID = tmpTg.BetID AND mms.Betteam = tmpTg.Betteam AND mms.GroupID = tmpTg.GroupID
		WHERE	mms.TransDate < lv_LastMinTime  AND tmpTg.GroupID IS NULL;

		IF ip_MaxSequenceID > 0 THEN	
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = ip_MaxSequenceID
			WHERE 	sys.ParameterID = 125;
		END IF;        
	END IF;
    
END$$
DELIMITER ;
