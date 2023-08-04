/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleArbitrage_Process`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleArbitrage_Process`(
		IN ip_LiveIndicator		BOOLEAN
	,	IN ip_MaxSequenceID		BIGINT UNSIGNED
	,	IN ip_MatchID			INT 
    ,	IN ip_IsMajorLeague 	BOOLEAN
    ,	IN ip_ScoreDiff			INT 
    ,	IN ip_BettypeID			INT
    ,	IN ip_BetID				BIGINT
    ,	IN ip_HDP				DECIMAL(8,4)   

		
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	202212216@Casey.Huynh
		Task :		Match Monitor Arbitrage Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	202212216@Casey.Huynh: 	Created [Redmine ID: 179502]
			- 	20230109@Casey.Huynh: 	SumStake by CustID [Redmine ID: 182639]
			- 	20230111@Casey.Huynh: 	SumStake by CustID not group by Betteam [Redmine ID: 182639]
			-	20230310@Victoria.Le:	Credit Scale Out - Split 789y Site [Redmine ID: #183140]
			-	20230612@Casey.Huynh: 	LogInfo [Redmine ID: #185793]
            
		Param's Explanation (filtered by):
			CALL CTS_DC_MatchMonitor_RuleArbitrage_Process(@ip_LiveIndicator:=0,@ip_MaxSequenceID:=@op_MaxSequenceID,@ip_MatchID:=110100,@ip_IsMajorLeague:=0,@ip_ScoreDiff:=-2,@ip_BettypeID:=1,@ip_BetID:=0, @ip_HDP:=-0.2500);
	
		Example:		
	*/
	DECLARE CONS_LOG 					TINYINT DEFAULT 	0; #0:LogOff, 1:LogOn
	DECLARE CONST_RULE_GROUPID 			INT 	DEFAULT 	5;
	DECLARE CONS_SUBSCRIBERID_ALPHA		INT 	DEFAULT  	168;
	DECLARE CONS_SUBSCRIBERID_MAXBET	INT 	DEFAULT  	169;
    
    
    DECLARE lv_RuleTimeStep 			SMALLINT;
    DECLARE lv_RuleTotalStake 			DECIMAL(20,4);
    DECLARE lv_RuleReason 				INT;
    DECLARE lv_RuleSportType 			INT;  
    DECLARE lv_CustIDList 				TEXT;
    DECLARE lv_LastSequenceID 			BIGINT UNSIGNED;  
    
    #==================LOG=======================================================
    DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_RuleArbitrage_Process';
    IF CONS_LOG = 1 THEN     
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), CONCAT('@ip_LiveIndicator:=',ip_LiveIndicator,',@ip_MaxSequenceID:=',ip_MaxSequenceID,',@ip_MatchID:=',ip_MatchID
		,',@ip_IsMajorLeague:=',ip_IsMajorLeague,',@ip_ScoreDiff:=',ip_ScoreDiff,',@ip_BettypeID:=',ip_BettypeID,',@ip_BetID:=',ip_BetID,',@ip_HDP:=',ip_HDP);
    END IF;
    #==================LOG=======================================================   
    
    DROP TEMPORARY TABLE IF EXISTS Temp_StagingTrans;
    CREATE TEMPORARY TABLE Temp_StagingTrans(
			SequenceID		BIGINT UNSIGNED NOT NULL
		,	TransID			BIGINT UNSIGNED NOT NULL PRIMARY KEY
        ,	TransDate		DATETIME(3)  NOT NULL
        ,	TransDateSecond	BIGINT 
        ,	CustID			BIGINT NOT NULL
        ,	CTSCustID		BIGINT 
        , 	AgentCTSCustID	BIGINT 
        ,	OldGroupID		INT 
        ,	Stake			DECIMAL(20,4)
        ,	Betteam			VARCHAR(10)
        ,	HDP				DECIMAL(8,4)
        ,	GroupID			INT DEFAULT 0
        , 	Processed		TINYINT
        
        ,	INDEX IX_Temp_StagingTrans_CTSCustID(CTSCustID) 
        ,	INDEX IX_Temp_StagingTrans_AgentCTSCustID(AgentCTSCustID) 
        ,	INDEX IX_Temp_StagingTrans_Processed(Processed) 
        ,	INDEX IX_Temp_StagingTrans_SequenceID(SequenceID) 
    );	
        
	DROP TEMPORARY TABLE IF EXISTS Temp_RemoveCust;
    CREATE TEMPORARY TABLE Temp_RemoveCust(
			CTSCustID BIGINT UNSIGNED PRIMARY KEY
    );	
	
    DROP TEMPORARY TABLE IF EXISTS Temp_InvalidStakeCust;
    CREATE TEMPORARY TABLE Temp_InvalidStakeCust(
			GroupID INT
		,	CTSCustID BIGINT UNSIGNED 		
        
        ,	PRIMARY KEY (GroupID, CTSCustID)
    );	
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RemoveGroup;
    CREATE TEMPORARY TABLE Temp_RemoveGroup(
			GroupID INT PRIMARY KEY
    );	
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ResultGroup;
    CREATE TEMPORARY TABLE Temp_ResultGroup(
			GroupID					INT PRIMARY KEY
		,	Reason					INT
        ,	TransIDList				LONGTEXT NOT NULL
        ,	CustIDList				LONGTEXT NOT NULL
        ,	OldGroupIDList			VARCHAR(500)
    );	
	
    #******************************* GET STAGING TRANS *******************************************
    IF (ip_LiveIndicator = 0) THEN

		SELECT ParameterValue
        INTO lv_LastSequenceID
		FROM CTS_DataCenter.SystemParameter AS sys
		WHERE ParameterID = 128;
    
		SELECT mms.SportType 
        INTO lv_RuleSportType 
        FROM CTS_DataCenter.MatchMonitorStagingArbitrageNonLive AS mms 
        WHERE mms.MatchID = ip_MatchID 
        LIMIT 1;

        SELECT 	st.TimeStep
			, 	st.TotalStake
			, 	st.Reason
		INTO 	lv_RuleTimeStep
			, 	lv_RuleTotalStake
			,	lv_RuleReason
		FROM 	CTS_DataCenter.MatchMonitorRuleSetting AS st 
		WHERE 	st.RuleGroupID = CONST_RULE_GROUPID 
			AND st.SportType = lv_RuleSportType 
			AND (st.LeagueType = ip_IsMajorLeague OR st.LeagueType = 2)
            AND st.RuleStatus = 1;

		INSERT INTO Temp_StagingTrans(TransID, SequenceID, TransDate, TransDateSecond, CustID, CTSCustID, AgentCTSCustID, OldGroupID, Stake, Betteam, Processed)
        SELECT	mms.TransID
			,	mms.SequenceID
			,	mms.TransDate
            ,	TO_SECONDS(mms.TransDate) AS TransDateSecond
            ,	mms.CustID
            ,	cus.CTSCustID
            ,	agent.CTSCustID  AS AgentCTSCustID       
            ,	mms.GroupID
            ,	mms.Stake
            ,	mms.Betteam
            ,	(CASE WHEN mms.SequenceID > lv_LastSequenceID THEN 0 ELSE 1 END) AS Processed
		FROM CTS_DataCenter.MatchMonitorStagingArbitrageNonLive AS mms			
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = mms.CustID AND cus.CustSubID = 0
            LEFT JOIN CTS_DataCenter.CTSCustomer AS agent ON agent.CustID = cus.Recommend 
															AND agent.CustSubID = 0 
                                                            AND cus.RoleID = 1
															AND agent.IsInternal = 0 												
                                                            AND cus.SubscriberID IN (CONS_SUBSCRIBERID_ALPHA,CONS_SUBSCRIBERID_MAXBET)
        WHERE	mms.SequenceID <= ip_MaxSequenceID 
			AND mms.MatchID = ip_MatchID 
            AND mms.ScoreDiff = ip_ScoreDiff 
            AND mms.BettypeID = ip_BettypeID
            AND mms.BetID = ip_BetID 
            AND mms.HDP = ip_HDP;       
    END IF;
    
    #=========REMOVE IF Cust's Total Stake < lv_RuleTotalStake
	INSERT INTO Temp_RemoveCust(CTSCustID)
    SELECT tmpSp.CTSCustID
    FROM Temp_StagingTrans AS tmpSp
    GROUP BY tmpSp.CTSCustID
    HAVING SUM(tmpSp.Stake) < lv_RuleTotalStake;

    #=====================================================================
	WHILE EXISTS (SELECT 1 FROM Temp_StagingTrans) DO        
        
        TRUNCATE TABLE Temp_RemoveGroup;
		TRUNCATE TABLE Temp_InvalidStakeCust;

		#========Detect group by assocation and transdate====================
		CALL CTS_DataCenter.CTS_DC_MatchMonitor_DetectGroup(lv_RuleTimeStep, 0);

		#=========REMOVE TRANS IF NO GROUP (GROUP = 0)
        DELETE tmpSt
		FROM Temp_StagingTrans AS tmpSt
		WHERE GroupID = 0;
        
        #=========RESET GROUPID = 0 IF EXISTS INVALID TOTAL STAKE
		INSERT INTO Temp_InvalidStakeCust(GroupID, CTSCustID)
		SELECT	tmpSt.GroupID
			,	tmpSt.CTSCustID
		FROM Temp_StagingTrans AS tmpSt
		GROUP BY tmpSt.CTSCustID, tmpSt.GroupID
		HAVING SUM(tmpSt.Stake) < lv_RuleTotalStake;
        
		DELETE tmpSt
		FROM Temp_StagingTrans AS tmpSt
		INNER JOIN Temp_InvalidStakeCust AS tmpRg ON tmpRg.GroupID = tmpSt.GroupID AND tmpRg.CTSCustID = tmpSt.CTSCustID;
        
        #======SET GROUPID = 0 TO RESCAN====================================================================
        UPDATE Temp_StagingTrans AS tmpSt
        SET GroupID = 0
        WHERE tmpSt.GroupID IN (SELECT DISTINCT tmpRg.GroupID FROM Temp_InvalidStakeCust AS tmpRg);
        
        #=======REMOVE GROUP IF INVALID BETTEAM AND TOTAL CUSTs < 2============================================       
        INSERT INTO Temp_RemoveGroup(GroupID)
        SELECT	tmpSt.GroupID 
        FROM Temp_StagingTrans AS tmpSt
        GROUP BY GroupID
        HAVING MIN(tmpSt.Betteam) = MAX(tmpSt.Betteam) OR COUNT(CTSCustID) = 1;
        
        DELETE tmpSt
		FROM Temp_StagingTrans AS tmpSt
		INNER JOIN Temp_RemoveGroup AS tmpRv ON tmpRv.GroupID = tmpSt.GroupID;		
		
        #==========INSERT VALID GROUP TO RESULT====================================================================
        
		INSERT INTO Temp_ResultGroup(GroupID, TransIDList, CustIDList, OldGroupIDList)
		SELECT  tmpSt.GroupID
			,	GROUP_CONCAT(tmpSt.TransID) AS TransIDList
			,	GROUP_CONCAT(DISTINCT tmpSt.CustID) AS CustIDList
			,	GROUP_CONCAT(DISTINCT CASE WHEN tmpSt.OldGroupID > 0 THEN tmpSt.OldGroupID ELSE 0 END) AS OldGroupIDList
		FROM Temp_StagingTrans  AS tmpSt
        WHERE tmpSt.GroupID > 0
        GROUP BY tmpSt.GroupID; 
        
        DELETE tmpSt
        FROM Temp_StagingTrans AS tmpSt
        WHERE tmpSt.GroupID > 0;
		
    END WHILE;               
    
	SELECT	tmpRg.GroupID
		,	lv_RuleReason AS Reason
        ,	tmpRg.TransIDList
        ,	tmpRg.CustIDList
        ,	tmpRg.OldGroupIDList
    FROM Temp_ResultGroup AS tmpRg;   
    
END$$
DELIMITER ;
