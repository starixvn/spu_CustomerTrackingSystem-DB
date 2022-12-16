/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleArbitrage_Process`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleArbitrage_Process`(
		IN ip_LiveIndicator		BOOLEAN
	,	IN ip_MaxSequenceID		BIGINT UNSIGNED
	,	IN ip_MatchID			INT UNSIGNED
    ,	IN ip_IsMajorLeague 	BOOLEAN
    ,	IN ip_ScoreDiff			INT 
    ,	IN ip_BettypeID			INT UNSIGNED
    ,	IN ip_BetID				BIGINT
    ,	IN ip_HDP				DECIMAL(8,4)
    
    
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule Process
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 152883]
			-	20210719@Casey.Huynh: Fix Issue Rule Trans.StepTime and AssGroup [Redmine ID: 158946]
            -	20210830@Casey.Huynh: Update Rule seperate Live and NonLive and move to Slave [Redmine ID: 159195]
			-	20211019@Aries.Nguyen: Use FEDERATED  table [Redmine ID: 163400]
			-	20211102@Aries.Nguyen: Fix FEDERATED connection fail[Redmine ID: 163400]
            -	20211111@Casey.Huynh: Fix Issue Trans of the same Cust not merge Group [Redmine ID: 164558]
            -	20220110@Casey.Huynh: Enhance MM, Add SportType, Betteam, BetID [Redmine ID: 166986]
            -	20220217@Casey.Huynh: Enhance MM, Update TO >= 1000 [Redmine ID: 168736]
            - 	20220422@Irena.Vo: Mapping Is Hedging Reason (MM) from table CustomerCategory [Redmine ID: #170468]
            -	20220815@Casey.Huynh: Scale Out DB [Redmine ID: #176472]
            - 	20220830@Casey.Huynh: New Category for Classify Group Betting [Redmine ID: #176976]
            -	202200929@Casey.Huynh: Seperate By Sport [Redmine ID: #178310]
            -	20221021@Casey.Huynh: Fixed Clean Data Staging [Redmine ID: #179427]
            -	20221027@Casey.Huynh: Seperate pool Staging [RedmineID: 179439]
            -	20221205@Casey.Huynh: Refine Arbitrage [Redmine ID: #179502]
		Param's Explanation (filtered by):	
		Example:
			- CALL CTS_DC_MatchMonitor_RuleArbitrage_Process(1,113171940189,22081995,1,1,0);
			
	*/
    DECLARE CONST_RULE_GROUPID INT DEFAULT 5;
    DECLARE CONS_SITE789 				INT DEFAULT  3;
    
    DECLARE lv_RuleTimeStep 			SMALLINT;
    DECLARE lv_RuleTotalStake 			DECIMAL(20,4);
    DECLARE lv_RuleReason 				TINYINT;
    DECLARE lv_RuleSportType 			INT;  
    DECLARE lv_CustIDList 				TEXT;
    DECLARE lv_LastSequenceID 			BIGINT UNSIGNED;  
    
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ResultGroup;
    CREATE TEMPORARY TABLE Temp_ResultGroup(
			GroupID					INT PRIMARY KEY
		,	Reason					TINYINT
        ,	TransIDList				LONGTEXT NOT NULL
        ,	CustIDList				LONGTEXT NOT NULL
        ,	OldGroupIDList			VARCHAR(500)
        
        ,	INDEX IX_Temp_ResultGroup(Reason)
    );	
	
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupHedging;
	CREATE TEMPORARY TABLE 	Temp_GroupHedging (
			GroupID	INT PRIMARY KEY
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
		FROM 	MatchMonitorRuleSetting AS st 
		WHERE 	st.RuleGroupID = CONST_RULE_GROUPID 
		AND st.SportType = lv_RuleSportType 
        AND (st.LeagueType = ip_IsMajorLeague OR st.LeagueType = 2);

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
                                                            AND cus.SiteID = CONS_SITE789
        WHERE mms.SequenceID <= ip_MaxSequenceID 
			AND mms.MatchID = ip_MatchID 
            AND mms.ScoreDiff = ip_ScoreDiff 
            AND mms.BettypeID = ip_BettypeID
            AND mms.BetID = ip_BetID 
            AND mms.HDP = ip_HDP;        
    END IF;

    #========Detect group by assocation and transdate====================
    CALL CTS_DC_MatchMonitor_DetectGroup(lv_RuleTimeStep);
	#===============================================================================
	
    INSERT INTO Temp_ResultGroup(GroupID, TransIDList, CustIDList, OldGroupIDList)
    SELECT  tmpSt.GroupID
        ,	GROUP_CONCAT(tmpSt.TransID) AS TransIDList
        ,	GROUP_CONCAT(DISTINCT tmpSt.CustID) AS CustIDList
        ,	GROUP_CONCAT(DISTINCT CASE WHEN tmpSt.OldGroupID > 0 THEN tmpSt.OldGroupID ELSE 0 END) AS OldGroupIDList
    FROM 	Temp_StagingTrans  AS tmpSt
	GROUP BY tmpSt.GroupID
    HAVING SUM(tmpSt.Stake) >= lv_RuleTotalStake 
		AND COUNT(DISTINCT tmpSt.CustID) > 1 AND COUNT(DISTINCT tmpSt.Betteam) > 1 AND tmpSt.GroupID > 0;
        
                        
	IF (ip_LiveIndicator = 0) THEN 
		UPDATE CTS_DataCenter.MatchMonitorStagingArbitrageNonLive AS mms
			INNER JOIN CTS_DataCenter.Temp_StagingTrans AS tmpSt ON mms.SequenceID = tmpSt.SequenceID
			LEFT JOIN Temp_ResultGroup AS tmpRg ON tmpSt.GroupID = tmpRg.GroupID
		SET mms.GroupID = -tmpSt.GroupID
		WHERE tmpRg.GroupID IS NULL;
	END IF;
    
	SELECT	tmpRg.GroupID
		,	tmpRg.Reason
        ,	tmpRg.TransIDList
        ,	tmpRg.CustIDList
        ,	tmpRg.OldGroupIDList
    FROM Temp_ResultGroup AS tmpRg;   
    
END$$
DELIMITER ;
