/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleHedging_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleHedging_Get`(
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
            -	20221205@Casey.Huynh: Rename Table [Redmine ID: #179502]
            -	20221103@Casey.Huynh: Enhance Hedging Rule [Redmine ID: #192172]
            
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_MatchMonitor_RuleHedging_Get(@ip_LiveIndicator:=1,@op_MaxSequenceID);
	*/
    DECLARE CONS_LOG					TINYINT DEFAULT 0; #0:LogOff, 1:LogOn
	DECLARE CONS_SUBSCRIBERID_ALPHA		INT DEFAULT 168;
	DECLARE CONS_SUBSCRIBERID_MAXBET	INT DEFAULT 169;
    
	DECLARE lv_LastSequenceID	BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxSequenceID	BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxTransDate		DATETIME(3);
    DECLARE lv_Rule_RuleGroupID	TINYINT DEFAULT 3;
    DECLARE lv_Rule_MinTimeStep	SMALLINT;
    DECLARE lv_NoOfRow			INT DEFAULT 5000;
    
    #==================LOG=======================================================
    DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_RuleHedging_Get';
    IF CONS_LOG = 1 THEN     
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), CONCAT('@ip_LiveIndicator:=',ip_LiveIndicator);
    END IF;
    #==================LOG======================================================= 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitorRuleSetting;
	CREATE TEMPORARY TABLE Temp_MatchMonitorRuleSetting(
			SportType	INT
		,	TotalStake	DECIMAL(20,4)
        ,	HighStake	DECIMAL(20,4)
		
		,	PRIMARY KEY PK_Temp_MatchMonitorRuleSetting(SportType)
	);
    
    #===============================================================================================
	DROP TEMPORARY TABLE IF EXISTS Temp_OldGroup;
	CREATE TEMPORARY TABLE Temp_OldGroup(
			MatchID			INT NOT NULL		
		,	ScoreDiff		INT NOT NULL
		,	BettypeID		INT NOT NULL
		,	BetID			BIGINT NOT NULL
		,	Betteam			VARCHAR(10) NOT NULL
		,	GroupID			INT NOT NULL
        ,	MaxTransDate	DATETIME(4)
		
		,	PRIMARY KEY PK_Temp_OldGroup(MatchID,ScoreDiff,BettypeID,BetID,Betteam, GroupID)
	);
    
    #===============================================================================================
    INSERT INTO Temp_MatchMonitorRuleSetting(SportType, TotalStake, HighStake)
    SELECT	s.SportType
        ,	s.TotalStake
        ,	s.HighStake
    FROM CTS_DataCenter.MatchMonitorRuleSetting AS s
    WHERE s.RuleGroupID = lv_Rule_RuleGroupID AND s.RuleStatus=1;

	SELECT MIN(s.TimeStep)
    INTO lv_Rule_MinTimeStep
    FROM CTS_DataCenter.MatchMonitorRuleSetting AS s
    WHERE s.RuleGroupID = lv_Rule_RuleGroupID AND s.RuleStatus=1;
    
    SELECT s.ParameterValue
    INTO lv_NoOfRow
    FROM CTS_DataCenter.SystemParameter AS s
    WHERE s.ParameterID = 123;
    
	IF ip_LiveIndicator = 1 THEN #=============Live Trans==================
		
		SELECT sys.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 120;      
        
		INSERT INTO Temp_OldGroup(MatchID, ScoreDiff, BettypeID, BetID, Betteam, GroupID, MaxTransDate)
        SELECT	mms.MatchID
			,	mms.ScoreDiff
            ,	mms.BettypeID
            ,	mms.BetID
            ,	mms.Betteam
            ,	mms.GroupID
            ,	TIMESTAMPADD(SECOND, lv_Rule_MinTimeStep, MAX(TransDate)) AS MaxTransDate
        FROM CTS_DataCenter.MatchMonitorStagingHedgingLive AS mms
		WHERE mms.SequenceID <= lv_LastSequenceID
        GROUP BY MatchID, ScoreDiff, BettypeID, BetID, Betteam, GroupID;  
                            
        #==========Get Next Trans In TimeStep==================
        SELECT TIMESTAMPADD(SECOND, lv_Rule_MinTimeStep, mms.TransDate)
        INTO lv_MaxTransDate
        FROM CTS_DataCenter.MatchMonitorStagingHedgingLive AS mms
        WHERE mms.SequenceID = lv_LastSequenceID;        

        SELECT MAX(tmp.SequenceID)
        INTO lv_MaxSequenceID
        FROM (	SELECT mms.SequenceID
				FROM CTS_DataCenter.MatchMonitorStagingHedgingLive AS mms 
                WHERE mms.TransDate <= lv_MaxTransDate 
                ORDER BY mms.SequenceID 
                LIMIT lv_NoOfRow) AS tmp;
        
        SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID,0) ;
       
        IF(lv_LastSequenceID < lv_MaxSequenceID) THEN # If Has New Trans   
			
			SELECT	mms.MatchID
				,	mms.ScoreDiff
				,	mms.BettypeID
				,	mms.BetID
				,	mms.Betteam
                ,	MIN(mms.SportType) AS SportType
				,	IFNULL(tmpOg.GroupID,0) AS OldGroup
                ,	GROUP_CONCAT(CASE WHEN CustID IS NOT NULL THEN JSON_OBJECT(	'CTSCustID', mms.CTSCustID,
																				'CustID', mms.CustID
																				) ELSE NULL END) CustList
				
				,	CASE WHEN COUNT(DISTINCT CASE WHEN mms.SubscriberID IN (CONS_SUBSCRIBERID_ALPHA,CONS_SUBSCRIBERID_MAXBET) THEN mms.CustID ELSE NULL END) > 1 
												THEN GROUP_CONCAT(DISTINCT CASE WHEN mms.SubscriberID IN (CONS_SUBSCRIBERID_ALPHA,CONS_SUBSCRIBERID_MAXBET) THEN mms.CustID ELSE NULL END)
								ELSE NULL END AS DetectAgentAssCustIDList
				,	GROUP_CONCAT(mms.SequenceID) AS SequenceIDList
			FROM CTS_DataCenter.MatchMonitorStagingHedgingLive AS mms
				LEFT JOIN Temp_OldGroup AS tmpOg ON mms.MatchID = tmpOg.MatchID AND mms.ScoreDiff = tmpOg.ScoreDiff AND mms.BettypeID = tmpOg.BettypeID
													AND mms.BetID = tmpOg.BetID AND mms.Betteam = tmpOg.Betteam AND mms.TransDate <= tmpOg.MaxTransDate
													AND (mms.GroupID = tmpOg.GroupID OR mms.GroupID = 0)
			WHERE mms.SequenceID <= lv_MaxSequenceID 
			GROUP BY mms.MatchID, mms.ScoreDiff, mms.BettypeID, mms.BetID, mms.Betteam, IFNULL(tmpOg.GroupID,0)
			HAVING COUNT(DISTINCT mms.CustID) > 1
			ORDER BY mms.MatchID, mms.ScoreDiff, mms.BettypeID, mms.BetID, mms.Betteam, IFNULL(tmpOg.GroupID,0);
					
		END IF;
        
	ELSE #=============NON Live Trans==================
    
		SELECT sys.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 121;
        
        #========================================================
        INSERT INTO Temp_OldGroup(MatchID, ScoreDiff, BettypeID, BetID, Betteam, GroupID, MaxTransDate)
        SELECT	mms.MatchID
			,	mms.ScoreDiff
            ,	mms.BettypeID
            ,	mms.BetID
            ,	mms.Betteam
            ,	mms.GroupID
            ,	TIMESTAMPADD(SECOND, lv_Rule_MinTimeStep, MAX(TransDate)) AS MaxTransDate
        FROM CTS_DataCenter.MatchMonitorStagingHedgingNonLive AS mms
		WHERE mms.SequenceID <= lv_LastSequenceID
        GROUP BY MatchID, ScoreDiff, BettypeID, BetID, Betteam, GroupID;  
                            
        #==========Get Next Trans In TimeStep==================
        SELECT TIMESTAMPADD(SECOND, lv_Rule_MinTimeStep, mms.TransDate)
        INTO lv_MaxTransDate
        FROM CTS_DataCenter.MatchMonitorStagingHedgingNonLive AS mms
        WHERE mms.SequenceID = lv_LastSequenceID;        

        SELECT MAX(tmp.SequenceID)
        INTO lv_MaxSequenceID
        FROM (	SELECT mms.SequenceID
				FROM CTS_DataCenter.MatchMonitorStagingHedgingNonLive AS mms 
                WHERE mms.TransDate <= lv_MaxTransDate 
                ORDER BY mms.SequenceID 
                LIMIT lv_NoOfRow) AS tmp;
        
        SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID, 0) ;
       
        IF	(lv_LastSequenceID < lv_MaxSequenceID) THEN # If Has New Trans   
			
			SELECT	mms.MatchID
				,	mms.ScoreDiff
				,	mms.BettypeID
				,	mms.BetID
				,	mms.Betteam
                ,	MIN(mms.SportType) AS SportType
				,	IFNULL(tmpOg.GroupID,0) AS OldGroup
				#,	GROUP_CONCAT(DISTINCT mms.CustID) AS CustIDList
                
				,	JSON_OBJECT(
				  'CustID', mms.CustID,
				  'CTSCustID', mms.CTSCustID
				) AS CustList
				,	CASE WHEN COUNT(DISTINCT CASE WHEN mms.SubscriberID IN (CONS_SUBSCRIBERID_ALPHA,CONS_SUBSCRIBERID_MAXBET) THEN mms.CustID ELSE NULL END) > 1 
												THEN GROUP_CONCAT(DISTINCT CASE WHEN mms.SubscriberID IN (CONS_SUBSCRIBERID_ALPHA,CONS_SUBSCRIBERID_MAXBET) THEN mms.CustID ELSE NULL END)
								ELSE NULL END AS DetectAgentAssCustIDList
				,	GROUP_CONCAT(mms.SequenceID) AS SequenceIDList
			FROM  CTS_DataCenter.MatchMonitorStagingHedgingNonLive AS mms
				LEFT JOIN Temp_OldGroup AS tmpOg ON mms.MatchID = tmpOg.MatchID AND mms.ScoreDiff = tmpOg.ScoreDiff AND mms.BettypeID = tmpOg.BettypeID
													AND mms.BetID = tmpOg.BetID AND mms.Betteam = tmpOg.Betteam AND mms.TransDate <= tmpOg.MaxTransDate
													AND (mms.GroupID = tmpOg.GroupID OR mms.GroupID = 0)
			WHERE mms.SequenceID <= lv_MaxSequenceID 
			GROUP BY mms.MatchID, mms.ScoreDiff, mms.BettypeID, mms.BetID, mms.Betteam, tmpOg.GroupID
			HAVING COUNT(DISTINCT mms.CustID) > 1
			ORDER BY mms.MatchID, mms.ScoreDiff, mms.BettypeID, mms.BetID, mms.Betteam, tmpOg.GroupID;
					
		END IF;
        
	END IF;
 
END$$
DELIMITER ;

