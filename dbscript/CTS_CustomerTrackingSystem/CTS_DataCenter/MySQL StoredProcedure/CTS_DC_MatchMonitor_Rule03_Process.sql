/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule03_Process`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule03_Process`(
		IN ip_LiveIndicator		BOOLEAN
	,	IN ip_MaxSequenceID		BIGINT UNSIGNED
	,	IN ip_MatchID			INT UNSIGNED
    ,	IN ip_TotalScore		INT 
    ,	IN ip_BettypeID			INT UNSIGNED
    ,	IN ip_BetID				BIGINT
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule Soccer - Hedging Process
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 152883]
            
		Param's Explanation (filtered by):	
		Example:
			- CALL CTS_DC_MatchMonitor_Rule03_Process(1,113171940189,22081995,1,1,0);
			
	*/
    DECLARE CONS_SITE789 				INT DEFAULT  3;
    
    DECLARE lv_TimeStep 				SMALLINT;
    DECLARE lv_RuleTotalStake 			DECIMAL(20,4);
    DECLARE lv_RuleHighStake 			DECIMAL(20,4);
	DECLARE lv_RuleGroupID 				SMALLINT DEFAULT 3;  
    DECLARE lv_Reason 					TINYINT DEFAULT 1;
    DECLARE lv_RuleSportType 			INT;  
    DECLARE lv_CustIDList 				TEXT;
    DECLARE lv_IsHedging 				BOOLEAN;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_StagingTrans;
    CREATE TEMPORARY TABLE Temp_StagingTrans(
			TransID			BIGINT UNSIGNED NOT NULL PRIMARY KEY
        ,	TransDate		DATETIME(3)  NOT NULL
        ,	TransDateSecond	BIGINT UNSIGNED
        ,	CustID			BIGINT NOT NULL
        ,	CTSCustID		BIGINT UNSIGNED
        , 	AgentCTSCustID	BIGINT UNSIGNED
        ,	OldGroupID		INT 
        ,	Stake			DECIMAL(20,4)
        ,	Betteam			VARCHAR(10)
        ,	GroupID			INT
        , 	Processed		BIT DEFAULT 0
        
        ,	INDEX IX_Temp_StagingTrans_CTSCustID(CTSCustID) 
        ,	INDEX IX_Temp_StagingTrans_AgentCTSCustID(AgentCTSCustID) 
        ,	INDEX IX_Temp_StagingTrans_Processed(Processed) 
    );	
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ResultGroup;
    CREATE TEMPORARY TABLE Temp_ResultGroup(
			GroupID					INT PRIMARY KEY
		,	Reason					TINYINT
        ,	TransIDList				LONGTEXT
        ,	CustIDList				LONGTEXT
        ,	OldGroupIDList			VARCHAR(500)
        
        ,	INDEX IX_Temp_ResultGroup(Reason)
    );	
	
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupHedging;
	CREATE TEMPORARY TABLE 	Temp_GroupHedging (
			GroupID	INT PRIMARY KEY
	);    
    
    #******************************* GET STAGING TRANS *******************************************
    IF (ip_LiveIndicator = 1) THEN
		SELECT mms.SportType 
        INTO lv_RuleSportType 
        FROM CTS_DataCenter.MatchMonitorStagingLive AS mms 
        WHERE mms.MatchID = ip_MatchID 
        LIMIT 1;
        
        SELECT 	st.TimeStep
		, 	st.TotalStake
        , 	st.HighStake
		INTO 	lv_TimeStep
			, 	lv_RuleTotalStake
			,	lv_RuleHighStake
		FROM MatchMonitorRuleSetting AS st 
		WHERE 	st.RuleGroupID = lv_RuleGroupID 
		AND st.SportType = lv_RuleSportType 
        AND st.Reason = lv_Reason;

		INSERT INTO Temp_StagingTrans(TransID, TransDate, TransDateSecond, CustID, CTSCustID, AgentCTSCustID, OldGroupID, Stake, Betteam)
        SELECT	mms.TransID
			,	mms.TransDate
            ,	TO_SECONDS(mms.TransDate) AS TransDateSecond
            ,	mms.CustID
            ,	cus.CTSCustID
            ,	agent.CTSCustID  AS AgentCTSCustID       
            ,	mms.Rule03GroupID
            ,	mms.Stake
            ,	mms.Betteam
		FROM CTS_DataCenter.MatchMonitorStagingLive AS mms			
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = mms.CustID AND cus.CustSubID = 0
            LEFT JOIN CTS_DataCenter.CTSCustomer AS agent ON agent.CustID = cus.Recommend 
															AND agent.CustSubID = 0 
                                                            AND cus.RoleID = 1
															AND agent.IsInternal = 0 												
                                                            AND cus.SiteID = CONS_SITE789
        WHERE mms.SequenceID <= ip_MaxSequenceID 
			AND mms.MatchID = ip_MatchID 
            AND mms.TotalScore = ip_TotalScore 
            AND mms.BettypeID = ip_BettypeID
            AND mms.BetID = ip_BetID 
            AND cus.IsLicensee = 0
            AND mms.Stake >= lv_RuleHighStake;
        
	ELSE 
		SELECT mms.SportType 
        INTO lv_RuleSportType 
        FROM CTS_DataCenter.MatchMonitorStagingNonLive AS mms 
        WHERE mms.MatchID = ip_MatchID 
        LIMIT 1;
        
        SELECT 	st.TimeStep
			, 	st.TotalStake
			, 	st.HighStake
		INTO 	lv_TimeStep
			, 	lv_RuleTotalStake
			,	lv_RuleHighStake
		FROM MatchMonitorRuleSetting AS st 
		WHERE 	st.RuleGroupID = lv_RuleGroupID 
			AND st.SportType = lv_RuleSportType 
			AND st.Reason = lv_Reason;
	  
		INSERT INTO Temp_StagingTrans(TransID, TransDate, TransDateSecond, CustID,  CTSCustID, AgentCTSCustID, OldGroupID, Stake, Betteam)
        SELECT	mms.TransID
			,	mms.TransDate
            ,	TO_SECONDS(mms.TransDate) AS TransDateSecond
            ,	mms.CustID
            ,	cus.CTSCustID
            ,	agent.CTSCustID  AS AgentCTSCustID 
            ,	mms.Rule03GroupID
            ,	mms.Stake
            ,	mms.Betteam
		FROM CTS_DataCenter.MatchMonitorStagingNonLive AS mms
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = mms.CustID AND cus.CustSubID = 0
            LEFT JOIN CTS_DataCenter.CTSCustomer AS agent ON agent.CustID = cus.Recommend 
															AND agent.CustSubID = 0 
                                                            AND cus.RoleID = 1
															AND agent.IsInternal = 0 												
                                                            AND cus.SiteID = CONS_SITE789
        WHERE  mms.SequenceID <= ip_MaxSequenceID 
			AND	mms.MatchID = ip_MatchID 
            AND mms.TotalScore = ip_TotalScore 
            AND mms.BettypeID = ip_BettypeID 
            AND mms.BetID = ip_BetID 
            AND cus.IsLicensee = 0
            AND mms.Stake >= lv_RuleHighStake;
        
    END IF;

    #========Detect group by assocation and transdate====================
    CALL CTS_DC_MatchMonitor_DetectGroup(lv_TimeStep);
	#===============================================================================

    INSERT INTO Temp_ResultGroup(GroupID, TransIDList, CustIDList, OldGroupIDList)
    SELECT  tmpSt.GroupID
        ,	GROUP_CONCAT(tmpSt.TransID) AS TransIDList
        ,	GROUP_CONCAT(DISTINCT tmpSt.CustID) AS CustIDList
        ,	GROUP_CONCAT(DISTINCT tmpSt.OldGroupID) AS OldGroupIDList
    FROM 	Temp_StagingTrans  AS tmpSt
	GROUP BY tmpSt.GroupID
    HAVING SUM(tmpSt.Stake) >= lv_RuleTotalStake 
		AND COUNT(DISTINCT tmpSt.CustID) > 1 AND tmpSt.GroupID IS NOT NULL;
        
    #=======CHECK Hedging GROUP: IF GroupCusts Is Hedging====================================		
	INSERT IGNORE INTO Temp_GroupHedging(GroupID)
	SELECT 	DISTINCT 
			tmpSt.GroupID 
	FROM Temp_StagingTrans AS tmpSt
	WHERE EXISTS (	SELECT 1 
					FROM CTS_DataCenter.CTSCustomerClassification AS cla 
						INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cla.CategoryID
					WHERE cla.CustID = tmpSt.CustID
						AND cla.SportGroupID = 0
						AND cc.IsHedgingReasonMM = 1);
	
	UPDATE Temp_ResultGroup AS tmpRg
		INNER JOIN Temp_GroupHedging AS tmpGh ON tmpRg.GroupID = tmpGh.GroupID
	SET tmpRg.Reason = 1;
		
   #=======CHECK Hedging GROUP: IF AssocitionCust of GroupCusts Is Hedging====================================
    labelGroup: LOOP
		SET lv_RuleGroupID = NULL;
        
		SELECT 	tmpRg.GroupID
			, 	tmpRg.CustIDList
        INTO 	lv_RuleGroupID
			, 	lv_CustIDList
        FROM Temp_ResultGroup AS tmpRg 
        WHERE tmpRg.Reason IS NULL 
        LIMIT 1;

		IF lv_RuleGroupID IS NULL THEN 
			LEAVE labelGroup;
		END IF;
         
        CALL CTS_DC_Association_IsAssociatedHedgingCustByCustIDList(lv_CustIDList, lv_IsHedging);
       
        IF lv_IsHedging = 1 THEN
			UPDATE Temp_ResultGroup AS tmpRg
            SET	tmpRg.Reason = 1
            WHERE tmpRg.GroupID = lv_RuleGroupID;
        ELSE    
			DELETE tmpRg
			FROM Temp_ResultGroup AS tmpRg
			WHERE tmpRg.GroupID = lv_RuleGroupID;
        END IF;

	END LOOP labelGroup;
    
	SELECT	tmpRg.GroupID
		,	tmpRg.Reason
        ,	tmpRg.TransIDList
        ,	tmpRg.CustIDList
        ,	tmpRg.OldGroupIDList
        ,	NULL AS HighStakeLicCustList
    FROM Temp_ResultGroup AS tmpRg;
    
END$$
DELIMITER ;
