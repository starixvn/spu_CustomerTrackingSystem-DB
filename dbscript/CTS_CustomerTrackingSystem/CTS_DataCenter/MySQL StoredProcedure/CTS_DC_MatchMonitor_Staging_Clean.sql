/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Staging_Clean`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Staging_Clean`(
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
            
		Param's Explanation (filtered by):
			CALL CTS_DC_MatchMonitor_Staging_Clean(1,2);
		Example:
			
	*/
	DECLARE	lv_Last3mMinTime 	DATETIME(3);
    DECLARE	lv_Last3mMaxTime 	DATETIME(3);  
	DECLARE	lv_LastTransID 		BIGINT;   
	DECLARE lv_Reason INT DEFAULT 0; #Group Betting
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitorRuleSetting;
	CREATE TEMPORARY TABLE Temp_MatchMonitorRuleSetting(
			SportType INT
		,	StepTime INT
		
		,	PRIMARY KEY PK_Temp_MatchMonitorRuleSetting(SportType )
	);
    
    INSERT INTO Temp_MatchMonitorRuleSetting(SportType, StepTime)
    SELECT	s.SportType
        ,	s.StepTime
    FROM CTS_DataCenter.MatchMonitorRuleSetting AS s
    WHERE s.Reason = lv_Reason;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Last3mTransGroup;
    CREATE TEMPORARY TABLE Temp_Last3mTransGroup
    (
			MatchID INT
        ,	TotalScore SMALLINT
        ,	BettypeID INT
        ,	BetID BIGINT
        ,   GroupID INT
        ,	Rule03_GroupID INT
        
        ,	PRIMARY KEY (MatchID,TotalScore,BettypeID, BetID, GroupID, Rule03_GroupID)
    );
	
    #======Clean Staging=================================================
    IF (ip_LiveIndicator = 1) THEN		
		SELECT 	MAX(mms.TransDate) , MAX(mms.TransID)
		INTO 	lv_Last3mMaxTime, lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorStagingLive AS mms
        WHERE	mms.SequenceID <= ip_MaxSequenceID;    
		
		SELECT  MIN(mms.TransDate) 
		INTO 	lv_Last3mMinTime
		FROM	CTS_DataCenter.MatchMonitorStagingLive AS mms
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
		WHERE   mms.TransDate > TIMESTAMPADD(SECOND, -tmpRs.StepTime, lv_Last3mMaxTime);  
			
		INSERT INTO Temp_Last3mTransGroup(MatchID, TotalScore, BettypeID, BetID, GroupID, Rule03_GroupID)
		SELECT 	DISTINCT mms.MatchID,  mms.TotalScore, mms.BettypeID, mms.BetID, mms.GroupID, mms.Rule03_GroupID
		FROM 	CTS_DataCenter.MatchMonitorStagingLive mms
		WHERE	mms.TransDate >= lv_Last3mMinTime AND (mms.GroupID > 0 OR Rule03_GroupID > 0);
		
		DELETE 	mms
		FROM	CTS_DataCenter.MatchMonitorStagingLive AS mms
			LEFT JOIN Temp_Last3mTransGroup AS tmpTg ON mms.MatchID = tmpTg.MatchID 
				AND mms.TotalScore = tmpTg.TotalScore AND mms.BettypeID = tmpTg.BettypeID AND mms.BetID = tmpTg.BetID  AND mms.GroupID = tmpTg.GroupID AND  mms.Rule03_GroupID = tmpTg.Rule03_GroupID
		WHERE	mms.TransDate < lv_Last3mMinTime  AND tmpTg.GroupID IS NULL AND tmpTg.GroupID IS NULL ;    
        
        /* Update Parameter*/
        IF lv_LastTransID > 0 THEN			
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = ip_MaxSequenceID
			WHERE 	sys.ParameterID = 47;
		END IF;
	END IF;
    
    IF (ip_LiveIndicator = 0) THEN		
		SELECT 	MAX(mms.TransDate) , MAX(mms.TransID)
		INTO 	lv_Last3mMaxTime, lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorStagingNonLive AS mms
        WHERE	mms.SequenceID <= ip_MaxSequenceID;    
		
		SELECT  MIN(mms.TransDate) 
		INTO 	lv_Last3mMinTime
		FROM	CTS_DataCenter.MatchMonitorStagingNonLive AS mms
			INNER JOIN Temp_MatchMonitorRuleSetting AS tmpRs ON mms.SportType = tmpRs.SportType
		WHERE   mms.TransDate > TIMESTAMPADD(SECOND, -tmpRs.StepTime, lv_Last3mMaxTime);   
			
		INSERT INTO Temp_Last3mTransGroup(MatchID, TotalScore, BettypeID, BetID, GroupID, Rule03_GroupID)
		SELECT 	DISTINCT mms.MatchID,  mms.TotalScore, mms.BettypeID, mms.BetID, mms.GroupID, mms.Rule03_GroupID
		FROM 	CTS_DataCenter.MatchMonitorStagingNonLive mms
		WHERE	mms.TransDate >= lv_Last3mMinTime AND (mms.GroupID > 0 OR Rule03_GroupID > 0);
		
		DELETE 	mms
		FROM	CTS_DataCenter.MatchMonitorStagingNonLive AS mms
			LEFT JOIN Temp_Last3mTransGroup AS tmpTg ON mms.MatchID = tmpTg.MatchID 
				AND mms.TotalScore = tmpTg.TotalScore AND mms.BettypeID = tmpTg.BettypeID AND mms.BetID = tmpTg.BetID  AND mms.GroupID = tmpTg.GroupID AND  mms.Rule03_GroupID = tmpTg.Rule03_GroupID
		WHERE	mms.TransDate < lv_Last3mMinTime  AND tmpTg.GroupID IS NULL AND tmpTg.GroupID IS NULL ;    
        
        /* Update Parameter*/
        IF lv_LastTransID > 0 THEN	
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = ip_MaxSequenceID
			WHERE 	sys.ParameterID = 48;
		END IF;
        
	END IF;
    
END$$
DELIMITER ;
