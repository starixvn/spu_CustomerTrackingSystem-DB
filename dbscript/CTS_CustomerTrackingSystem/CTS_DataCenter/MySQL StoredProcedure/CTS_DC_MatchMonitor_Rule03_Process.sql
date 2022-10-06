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
    DECLARE lv_TimeStep SMALLINT;
    DECLARE lv_RuleTotalStake SMALLINT;
	DECLARE lv_RuleGroupID SMALLINT DEFAULT 3;  
    DECLARE lv_Reason TINYINT DEFAULT 1;
    DECLARE lv_RuleSportType INT ;  
    DECLARE lv_CustIDList TEXT;
    DECLARE lv_IsHedging BOOLEAN;
    
    #=================================================================================    
    DROP TEMPORARY TABLE IF EXISTS Temp_StagingTrans;
    CREATE TEMPORARY TABLE Temp_StagingTrans(
			TransID			BIGINT UNSIGNED NOT NULL
        ,	TransDate		DATETIME(3)  NOT NULL
        ,	TransDateSecond	BIGINT UNSIGNED
        ,	CustID			BIGINT  NOT NULL
        ,	CTSCustID		BIGINT UNSIGNED
        ,	SiteID			INT
        , 	Recommend		INT
        ,	OldGroupID		INT 
        ,	Stake			DECIMAL(20,4)
        ,	Betteam			VARCHAR(10)
        ,	GroupID			INT
        
        ,	PRIMARY KEY PK_Temp_StagingTrans(TransID)
        ,	INDEX IX_Temp_StagingTrans(CustID)
        ,	INDEX IX_Temp_StagingTrans(CTSCustID) 
        
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
    
    #******** GET STAGING TRANS ******************************************************************
    #*********************************************************************************************   
    
    IF (ip_LiveIndicator = 1)
    THEN
		SELECT mms.SportType INTO lv_RuleSportType FROM CTS_DataCenter.MatchMonitorStagingLive AS mms WHERE mms.MatchID = ip_MatchID LIMIT 1;

		INSERT INTO Temp_StagingTrans(TransID, TransDate, TransDateSecond, CustID, CTSCustID, SiteID, Recommend, OldGroupID, Stake, Betteam)
        SELECT	mms.TransID
			,	mms.TransDate
            ,	TO_SECONDS(mms.TransDate) AS TransDateSecond
            ,	mms.CustID
            ,	cus.CTSCustID
            ,	cus.SiteID
            ,	cus.Recommend            
            ,	mms.Rule03GroupID
            ,	mms.Stake
            ,	mms.Betteam
		FROM CTS_DataCenter.MatchMonitorStagingLive AS mms			
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = mms.CustID AND cus.CustSubID = 0
        WHERE mms.SequenceID <= ip_MaxSequenceID AND mms.MatchID = ip_MatchID AND mms.TotalScore = ip_TotalScore AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND cus.IsLicensee = 0;
        
	ELSE 
		SELECT mms.SportType INTO lv_RuleSportType FROM CTS_DataCenter.MatchMonitorStagingNonLive AS mms WHERE mms.MatchID = ip_MatchID LIMIT 1;
	  
		INSERT INTO Temp_StagingTrans(TransID, TransDate, TransDateSecond, CustID, SiteID, Recommend, CTSCustID, OldGroupID, Stake, Betteam)
        SELECT	mms.TransID
			,	mms.TransDate
            ,	TO_SECONDS(mms.TransDate) AS TransDateSecond
            ,	mms.CustID
            ,	cus.CTSCustID
            ,	cus.SiteID
            ,	cus.Recommend
            ,	mms.Rule03GroupID
            ,	mms.Stake
            ,	mms.Betteam
		FROM CTS_DataCenter.MatchMonitorStagingNonLive AS mms
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = mms.CustID AND cus.CustSubID = 0
        WHERE  mms.SequenceID <= ip_MaxSequenceID AND	mms.MatchID = ip_MatchID AND mms.TotalScore = ip_TotalScore AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND cus.IsLicensee = 0;
        
    END IF;
	
    SELECT st.TimeStep, st.TotalStake
    INTO lv_TimeStep, lv_RuleTotalStake
    FROM MatchMonitorRuleSetting AS st 
    WHERE st.RuleGroupID = lv_RuleGroupID AND st.SportType = lv_RuleSportType AND  st.Reason = lv_Reason;
    
    #========Association Group Level 2 by lv_TimeStep second====================
    # CALL CTS_DC_TransAssociation_Test(lv_TimeStep);
    UPDATE Temp_StagingTrans
    SET GroupID = 1;  
    SELECT * FROM Temp_StagingTrans;
    SELECT  tmpSt.GroupID, SUM(tmpSt.Stake) AS SUMStake, COUNT(DISTINCT tmpSt.CustID) AS COUNT_CustID
        ,	GROUP_CONCAT(tmpSt.TransID) AS TransIDList
        ,	GROUP_CONCAT(DISTINCT tmpSt.CustID) AS CustIDList
        ,	GROUP_CONCAT(DISTINCT tmpSt.OldGroupID) AS OldGroupIDList
    FROM 	Temp_StagingTrans  AS tmpSt
	GROUP BY tmpSt.GroupID;
	#===============================================================================

    INSERT INTO Temp_ResultGroup(GroupID, TransIDList, CustIDList, OldGroupIDList)
    SELECT  tmpSt.GroupID
        ,	GROUP_CONCAT(tmpSt.TransID) AS TransIDList
        ,	GROUP_CONCAT(DISTINCT tmpSt.CustID) AS CustIDList
        ,	GROUP_CONCAT(DISTINCT tmpSt.OldGroupID) AS OldGroupIDList
    FROM 	Temp_StagingTrans  AS tmpSt
	GROUP BY tmpSt.GroupID
    HAVING SUM(tmpSt.Stake) >= lv_RuleTotalStake AND COUNT(DISTINCT tmpSt.CustID) > 1;
        
    #=======CHECK Hedging GROUP: IF GroupCusts Is Hedging====================================		
	INSERT IGNORE INTO Temp_GroupHedging(GroupID)
	SELECT DISTINCT tmpSt.GroupID 
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
        
		SELECT tmpRg.GroupID, tmpRg.CustIDList
        INTO lv_RuleGroupID, lv_CustIDList
        FROM Temp_ResultGroup AS tmpRg WHERE tmpRg.Reason IS NULL LIMIT 1;

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
