/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule03_Process`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule03_Process`(
		IN ip_LiveIndicator		BOOLEAN
	,	IN ip_MaxSequenceID		BIGINT UNSIGNED
	,	IN ip_MatchID			INT UNSIGNED
    ,	IN ip_TotalScore		INT 
    ,	IN ip_BettypeID			INT UNSIGNED
    ,	IN ip_BetID				BIGINT
    ,	IN ip_Betteam			VARCHAR(10)
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
            -	20221021@Casey.Huynh: Fixed Clean Data Staging [Redmine ID: #179427]
            - 	202201021@Casey.Huynh: Group By Betteam [Redmine ID: #179439]
            
		Param's Explanation (filtered by):	
		Example:
			- CALL CTS_DC_MatchMonitor_Rule03_Process(1,113171940189,22081995,1,1,0,'a');
			
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
    DECLARE lv_LastSequenceID 			BIGINT UNSIGNED;  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_StagingTrans;
    CREATE TEMPORARY TABLE Temp_StagingTrans(
			SequenceID		BIGINT UNSIGNED NOT NULL
		,	TransID			BIGINT UNSIGNED NOT NULL PRIMARY KEY
        ,	TransDate		DATETIME(3)  NOT NULL
        ,	TransDateSecond	BIGINT UNSIGNED
        ,	CustID			BIGINT NOT NULL
        ,	CTSCustID		BIGINT UNSIGNED
        , 	AgentCTSCustID	BIGINT UNSIGNED
        ,	OldGroupID		INT 
        ,	Stake			DECIMAL(20,4)
        ,	Betteam			VARCHAR(10)
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
    IF (ip_LiveIndicator = 1) THEN
		SELECT ParameterValue
        INTO lv_LastSequenceID
		FROM CTS_DataCenter.SystemParameter AS sys
		WHERE ParameterID = 120;
    
		SELECT mms.SportType 
        INTO lv_RuleSportType 
        FROM CTS_DataCenter.MatchMonitorStagingLive03 AS mms 
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

		INSERT INTO Temp_StagingTrans(TransID, SequenceID, TransDate, TransDateSecond, CustID, CTSCustID, AgentCTSCustID, OldGroupID, Stake, Betteam, Processed )
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
		FROM CTS_DataCenter.MatchMonitorStagingLive03 AS mms			
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
            AND mms.Betteam = ip_Betteam
            AND cus.IsLicensee = 0
            AND mms.Stake >= lv_RuleHighStake;
        
	ELSE 
		SELECT ParameterValue
        INTO lv_LastSequenceID
		FROM CTS_DataCenter.SystemParameter AS sys
		WHERE ParameterID = 121;
        
		SELECT mms.SportType 
        INTO lv_RuleSportType 
        FROM CTS_DataCenter.MatchMonitorStagingNonLive03 AS mms 
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
	
		INSERT INTO Temp_StagingTrans(TransID, SequenceID, TransDate, TransDateSecond, CustID, CTSCustID, AgentCTSCustID, OldGroupID, Stake, Betteam, Processed )
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
		FROM CTS_DataCenter.MatchMonitorStagingNonLive03 AS mms
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
            AND mms.Betteam = ip_Betteam
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
        ,	GROUP_CONCAT(DISTINCT CASE WHEN tmpSt.OldGroupID > 0 THEN tmpSt.OldGroupID ELSE 0 END) AS OldGroupIDList
    FROM 	Temp_StagingTrans  AS tmpSt
	GROUP BY tmpSt.GroupID
    HAVING SUM(tmpSt.Stake) >= lv_RuleTotalStake 
		AND COUNT(DISTINCT tmpSt.CustID) > 1 AND tmpSt.GroupID > 0;
        
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
    
	IF (ip_LiveIndicator = 1) THEN 
		UPDATE CTS_DataCenter.MatchMonitorStagingLive03 AS mms
			INNER JOIN CTS_DataCenter.Temp_StagingTrans AS tmpSt ON mms.SequenceID = tmpSt.SequenceID
			LEFT JOIN Temp_ResultGroup AS tmpRg ON tmpSt.GroupID = tmpRg.GroupID
		SET mms.GroupID = -tmpSt.GroupID
		WHERE tmpRg.GroupID IS NULL;
	ELSE
		UPDATE CTS_DataCenter.MatchMonitorStagingNonLive03 AS mms
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
        ,	NULL AS HighStakeLicCustList
    FROM Temp_ResultGroup AS tmpRg;   
    
END$$
DELIMITER ;
