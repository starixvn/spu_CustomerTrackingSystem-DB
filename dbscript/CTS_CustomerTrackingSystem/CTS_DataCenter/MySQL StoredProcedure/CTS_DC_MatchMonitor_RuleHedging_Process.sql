/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleHedging_Process`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleHedging_Process`(
		IN ip_LiveIndicator		BOOLEAN
	,	IN ip_MatchID			INT UNSIGNED
    ,	IN ip_ScoreDiff			INT 
    ,	IN ip_BettypeID			INT UNSIGNED
    ,	IN ip_BetID				BIGINT
    ,	IN ip_Betteam			VARCHAR(10)
    ,	IN ip_SportType			INT
    ,	IN ip_SequenceIDList	TEXT		# SequenceID List from SP CTS_DC_MatchMonitor_RuleHedging_Get
    ,	IN ip_CustGroup			JSON 		# Group Return from DC_Association_DetectGroup    
)
      
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule Soccer - Hedging Process
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: 	Created [Redmine ID: 152883]
			-	20221021@Casey.Huynh: 	Fixed Clean Data Staging [Redmine ID: #179427]
			- 	202201021@Casey.Huynh: 	Group By Betteam [Redmine ID: #179439]
			-   20221107@Aries.Nguyen: 	Tuning performance of Hedging Detection  [Redmine ID: #180185]
			-	20221205@Casey.Huynh: 	Rename Table [Redmine ID: #179502]
			-	20230310@Victoria.Le:	Credit Scale Out - Split 789y Site [Redmine ID: #183140]
            -	20230612@Casey.Huynh: 	LogInfo [Redmine ID: #185793]
            -	20240109@Casey.Huynh:	Enhance Hedging Rule [Redmine ID: #192172]
            -	20240509@Casey.Huynh: 	HF Hedging StepTime [Redmine ID: #204228]
			
		Param's Explanation (filtered by):	
		Example:
			- CALL CTS_DC_MatchMonitor_RuleHedging_Process(@ip_LiveIndicator:=1,@ip_MaxSequenceID:=113171940189,@ip_MatchID:=22081995,@ip_ScoreDiff:=1,@ip_BettypeID:=1,@ip_BetID:=0,@ip_Betteam:='a');
			
	*/
	DECLARE CONST_LOG 					TINYINT DEFAULT 0;
	DECLARE CONST_SUBSCRIBERID_ALPHA	INT DEFAULT 168;
	DECLARE CONST_SUBSCRIBERID_MAXBET	INT DEFAULT 169;
    DECLARE CONST_MMRULEGROUP_HEDGING	INT DEFAULT 3;
    DECLARE CONST_MMREASON_HEDGING		INT DEFAULT 1;

	DECLARE lv_RuleTimeStep 				SMALLINT;
	DECLARE lv_RuleTotalStake 			DECIMAL(20,4);
	DECLARE lv_CustIDList 				TEXT;
	DECLARE lv_IsHedging 				BOOLEAN;
	DECLARE lv_GroupID 					INT; 

    #==================LOG=======================================================
    DECLARE lv_SPName VARCHAR(100) DEFAULT 'CTS_DC_MatchMonitor_RuleHedging_Process';
    IF CONST_LOG = 1 THEN     
		INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
		SELECT lv_SPName, CURRENT_TIMESTAMP(), CONCAT('@ip_LiveIndicator:=',ip_LiveIndicator,',@ip_MatchID:=',ip_MatchID
		,',@ip_ScoreDiff:=',ip_ScoreDiff,',@ip_BettypeID:=',ip_BettypeID,',@ip_BetID:=',ip_Betteam,',@ip_HDP:=',ip_Betteam);
    END IF;
    
    #==================LOG=======================================================   
	DROP TEMPORARY TABLE IF EXISTS Temp_ResultGroup;
    CREATE TEMPORARY TABLE Temp_ResultGroup(
			GroupID			INT PRIMARY KEY	
		,	IsHedging		BOOLEAN
        ,	TotalStake		DECIMAL(20,4)
		,	OldGroupIDList	VARCHAR(500)
        ,	CustIDList		TEXT NOT NULL
        ,	TransIDList		TEXT NOT NULL        
        ,	SequenceIDList	TEXT NOT NULL 
        ,	INDEX IX_Temp_ResultGroup(GroupID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 		Temp_Cust (
		 	CustID 	BIGINT UNSIGNED PRIMARY KEY
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Group;
	CREATE TEMPORARY TABLE Temp_Group(
			GroupID INT
		,	StepTimeGroup	BIGINT
		,	TransIDList		LONGTEXT
		,	CustIDList		LONGTEXT
		,	CTSCustIDList	LONGTEXT
        ,	IsHedging		BOOLEAN
		,	AgentDetect_CTSCustIDList LONGTEXT
		,	SequenceIDList LONGTEXT);
    #=======================================================================
	SELECT 	st.TotalStake, st.TimeStep
	INTO 	lv_RuleTotalStake, lv_RuleTimeStep
	FROM CTS_DataCenter.MatchMonitorRuleSetting AS st 
	WHERE 	st.RuleGroupID = CONST_MMRULEGROUP_HEDGING 
			AND st.SportType = ip_SportType 
			AND st.Reason = CONST_MMREASON_HEDGING AND st.RuleStatus = 1
	LIMIT 1;

    DROP TEMPORARY TABLE IF EXISTS Temp_CustGroup;
    CREATE TEMPORARY TABLE Temp_CustGroup(
			CustID		BIGINT
        ,	GroupID		INT
	);
    
    INSERT INTO Temp_CustGroup(CustID, GroupID)
    SELECT  js.CustID
		,	js.GroupID
	FROM JSON_TABLE(ip_CustGroup,
					 "$[*]" COLUMNS(
								CustID		BIGINT UNSIGNED PATH "$.CustID" 	
							,	GroupID		INT PATH "$.GroupID"
						)
					) AS js;  
    
	DROP TEMPORARY TABLE IF EXISTS Temp_SequenceID;
    CREATE TEMPORARY TABLE Temp_SequenceID (
			SequenceID	BIGINT UNSIGNED PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_SequenceID (SequenceID) VALUES ('", REPLACE(ip_SequenceIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    IF (ip_LiveIndicator = 1) THEN
    
        SET  @sqlString = CONCAT('
        INSERT INTO Temp_Group(GroupID, StepTimeGroup, IsHedging, TransIDList, CustIDList, CTSCustIDList, AgentDetect_CTSCustIDList, SequenceIDList)        
        SELECT	MIN(tmp.GroupID) AS GroupID
			,	tmp.StepTimeGroup
            ,	MAX(tmp.IsHedging) AS IsHedging
            ,	GROUP_CONCAT(tmp.TransID) AS TransIDList
            ,	GROUP_CONCAT(DISTINCT tmp.CustID) AS CustIDList
            ,	GROUP_CONCAT(DISTINCT tmp.CTSCustID) AS CTSCustIDList
			,	CASE WHEN COUNT(DISTINCT CASE WHEN tmp.SubscriberID IN (',CONST_SUBSCRIBERID_ALPHA,' , ',CONST_SUBSCRIBERID_MAXBET, ') THEN tmp.CTSCustID ELSE NULL END) > 1 
												THEN GROUP_CONCAT(DISTINCT CASE WHEN tmp.SubscriberID IN (',CONST_SUBSCRIBERID_ALPHA,' , ',CONST_SUBSCRIBERID_MAXBET,') THEN tmp.CTSCustID ELSE NULL END)
								ELSE NULL END AS AgentDetect_CTSCustIDList
			,	GROUP_CONCAT(tmp.SequenceID)
        FROM	(
					SELECT 	tmpCg.GroupID
						,	LAST_VALUE(mms.TransDateToSecond)OVER W AS StepTimeGroup
                        ,	mms.IsHedging
						,	mms.TransID
						,	mms.CustID
						, 	mms.CTSCustID
						,	mms.SubscriberID
                        ,	mms.TransDateToSecond
						,	mms.SequenceID
						, 	mms.Stake
					FROM CTS_DataCenter.MatchMonitorStagingHedgingLive AS mms
						INNER JOIN Temp_SequenceID AS tmpSq ON mms.SequenceID = tmpSq.SequenceID
						INNER JOIN Temp_CustGroup AS tmpCg ON mms.CustID = tmpCg.CustID
						WINDOW w AS (PARTITION BY GroupID ORDER BY TransDateToSecond ASC RANGE BETWEEN CURRENT ROW AND ',lv_RuleTimeStep,' FOLLOWING)
				) AS tmp
        GROUP BY tmp.StepTimeGroup
        HAVING	SUM(tmp.Stake) >= ',lv_RuleTotalStake,'	
				AND COUNT(DISTINCT tmp.CustID) > 1');
                
        PREPARE stmt1 FROM @sqlString;

		EXECUTE stmt1;
        
		INSERT INTO Temp_ResultGroup(GroupID, OldGroupIDList, IsHedging, TotalStake, CustIDList, TransIDList, SequenceIDList)
		SELECT  tmpCg.GroupID
			,	GROUP_CONCAT(DISTINCT CASE WHEN mms.GroupID > 0 THEN mms.GroupID ELSE 0 END) AS OldGroupIDList
			,	MAX(mms.IsHedging) AS IsHedging
			,	SUM(mms.Stake) AS TotalStake
			,	GROUP_CONCAT(DISTINCT mms.CustID) AS CustIDList
			,	GROUP_CONCAT(mms.TransID) AS TransIDList
			,	GROUP_CONCAT(mms.SequenceID) AS SequenceIDList
		FROM CTS_DataCenter.MatchMonitorStagingHedgingLive AS mms
			INNER JOIN Temp_SequenceID AS tmpSq ON mms.SequenceID = tmpSq.SequenceID
			INNER JOIN Temp_CustGroup AS tmpCg ON mms.CustID = tmpCg.CustID
		GROUP BY tmpCg.GroupID;
        
	ELSE #(ip_LiveIndicator = 0)
		INSERT INTO Temp_ResultGroup(GroupID, OldGroupIDList, IsHedging, TotalStake, CustIDList, TransIDList, SequenceIDList)
		SELECT  tmpCg.GroupID
			,	GROUP_CONCAT(DISTINCT CASE WHEN mms.GroupID > 0 THEN mms.GroupID ELSE 0 END) AS OldGroupIDList
			,	MAX(mms.IsHedging) AS IsHedging
			,	SUM(mms.Stake) AS TotalStake
			,	GROUP_CONCAT(DISTINCT mms.CustID) AS CustIDList
			,	GROUP_CONCAT(mms.TransID) AS TransIDList
			,	GROUP_CONCAT(mms.SequenceID) AS SequenceIDList
		FROM CTS_DataCenter.MatchMonitorStagingHedgingNonLive AS mms
			INNER JOIN Temp_SequenceID AS tmpSq ON mms.SequenceID = tmpSq.SequenceID
			INNER JOIN Temp_CustGroup AS tmpCg ON mms.CustID = tmpCg.CustID
		GROUP BY tmpCg.GroupID;
    END IF;
    #===============CHECK Is Hedging Group====================
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Completed;
	CREATE TEMPORARY TABLE Temp_Completed(GroupID INT PRIMARY KEY, IsHedging BOOLEAN);
	
	INSERT INTO Temp_Completed(GroupID, IsHedging)
	SELECT tmpGp.GroupID
		, MAX(tmpGp.IsHedging) AS IsHedging
	FROM Temp_Group AS tmpGp
	GROUP BY tmpGp.GroupID
	HAVING COUNT(DISTINCT tmpGp.StepTimeGroup) = 1;
    
    SET lv_GroupID = 0;
    SET lv_GroupID = (	SELECT tmp.GroupID
						FROM Temp_Completed AS tmp
						WHERE tmp.IsHedging = 0 AND tmp.GroupID > lv_GroupID 
						ORDER BY tmp.GroupID
						LIMIT 1);    

    WHILE lv_GroupID IS NOT NULL DO    
    
		TRUNCATE TABLE Temp_Cust;
        
        SET lv_IsHedging = 0;
        
		SELECT tmpRg.CustIDList
		INTO lv_CustIDList
		FROM Temp_Group AS tmpRg
		WHERE tmpRg.GroupID = lv_GroupID;
		
        SET @sql = CONCAT("INSERT IGNORE INTO Temp_Cust(CustID) VALUES ('", REPLACE(lv_CustIDList, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;

		SELECT 1 
		INTO lv_IsHedging
		FROM Temp_Cust AS tmpCus 
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cla ON cla.CustID = tmpCus.CustID
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cla.CategoryID
		WHERE cla.SportGroupID = 0
		AND cc.IsHedgingReasonMM = 1
		LIMIT 1;
                            
        IF lv_IsHedging <> 1 THEN
			CALL CTS_DataCenter.CTS_DC_Association_IsAssociatedHedgingCustByCustIDList(lv_CustIDList, lv_IsHedging);
        END IF;
        
        IF lv_IsHedging = 1 THEN    
			UPDATE Temp_Group AS tmpRg
			SET tmpRg.IsHedging = 1
            WHERE tmpRg.GroupID = lv_GroupID;            
        END IF;
        
		SET lv_GroupID = (	SELECT tmp.GroupID
							FROM Temp_Completed AS tmp
							WHERE tmp.IsHedging = 0 AND tmp.GroupID > lv_GroupID 
							ORDER BY tmp.GroupID
							LIMIT 1);   
    END WHILE;
    
	SELECT	tmpRg.GroupID
		,	tmpRg.IsHedging
		,	tmpRg.OldGroupIDList		
        ,	tmpRg.CustIDList
        ,	tmpRg.TransIDList        
    FROM Temp_Group AS tmpRg
		INNER JOIN Temp_Completed AS tmpCp ON tmpRg.GroupID = tmpRg.GroupID
    WHERE tmpRg.IsHedging = 1;

    SELECT	CTSCustIDList
		,	AgentDetect_CTSCustIDList
        ,	SequenceIDList
    FROM Temp_Group AS tmpRg
		LEFT JOIN Temp_Completed AS tmpCp ON tmpRg.GroupID = tmpRg.GroupID
	WHERE tmpCp.GroupID IS NULL;
    
END$$
DELIMITER ;
