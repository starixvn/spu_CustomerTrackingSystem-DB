/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleIrrigation_Process`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleIrrigation_Process`(
		IN ip_LiveIndicator		BOOLEAN	
	,	IN ip_MaxSequenceID		BIGINT UNSIGNED
    ,	IN ip_SportType			INT
	,	IN ip_MatchID			INT UNSIGNED
    ,	IN ip_TotalScore		INT 
    ,	IN ip_BettypeID			INT UNSIGNED
    ,	IN ip_BetID				BIGINT
    ,	IN ip_Betteam			VARCHAR(50)    
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20211122@Casey.Huynh
		Task :		Match Monitor Rule Irrigation Process
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20211122@Casey.Huynh: Created [Redmine ID: #179499]
            
		Param's Explanation (filtered by):	
			
		Example:
			CALL CTS_DC_MatchMonitor_RuleIrrigation_Process(@ip_LiveIndicator:=1,@ip_MaxSequenceID:=0,@ip_SportType:=1,@ip_MatchID:=1,@ip_TotalScore:=1,@ip_BettypeID:=1,@ip_BetID:=0,@ip_Betteam:='a');
	*/
    DECLARE CONST_RULE_GROUPID INT DEFAULT 4;
    
    DECLARE lv_Rule_TotalStake		DECIMAL(20,4);
    DECLARE lv_Rule_OddsSpread		DECIMAL(4,2);
    DECLARE lv_Rule_TimeStep		INT;
    
	DECLARE lv_LastSequenceID	BIGINT UNSIGNED;
	DECLARE lv_LastTransDate	DATETIME(3); 
    
    #===================LOG=======================================
	INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
    SELECT'CTS_DC_MatchMonitor_RuleIrrigation_Process', current_timestamp(), CONCAT('ip_LiveIndicator:',ip_LiveIndicator
    ,' ip_SportType:',ip_SportType,' ip_MatchID:',ip_MatchID,' ip_TotalScore:',ip_TotalScore,' ip_BettypeID:',ip_BettypeID,' ip_BetID:',ip_BetID,' ip_Betteam:',ip_Betteam);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MatchMonitorRuleSetting;   
    CREATE TEMPORARY TABLE Temp_MatchMonitorRuleSetting(
			SportType	INT NOT NULL
		,	TimeStep	SMALLINT
		,	TotalStake	DECIMAL(20,4) DEFAULT NULL        
		,	OddsSpread	DECIMAL(4,2) DEFAULT NULL
        
		,	PRIMARY KEY (SportType)
	) ENGINE=InnoDB;   
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Trans;   
    CREATE TEMPORARY TABLE Temp_Trans(    
			CustID				BIGINT UNSIGNED
		,	TransDateSecond		BIGINT 
        ,	OldGroupID			INT
        ,	Stake				DECIMAL(20,4)
        ,	Odds				DECIMAL(4,2)
        ,	SequenceID			BIGINT UNSIGNED
        ,	GroupID				INT
		,	PRIMARY KEY (CustID, TransDateSecond, SequenceID)
        ,	INDEX (SequenceID)   
	) ENGINE=InnoDB;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_OldCustGroup;   
    CREATE TEMPORARY TABLE Temp_OldCustGroup(    
			CustID				BIGINT UNSIGNED
		,	MaxTransDateSec		BIGINT
        ,	OldGroupID 			INT
        ,	TotalStake			DECIMAL(20,4)
		,	PRIMARY KEY (CustID)
	) ENGINE=InnoDB;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewCustGroup;   
    CREATE TEMPORARY TABLE Temp_CustGroup(    
			CustID			BIGINT UNSIGNED
		,	MinTransDateSecSec	BIGINT
        ,	TotalStake		DECIMAL(20,4)
		,	PRIMARY KEY (CustID)
	) ENGINE=InnoDB;
    
    INSERT INTO Temp_Trans(CustID, TransDateSecond, Stake, OldGroupID, Stake, Odds, SequenceID)
    SELECT	mst.CustID
		,	TO_SECONDS(mms.TransDate) AS TransDateSecond
        ,	mst.Stake
        ,	mst.OldGroupID
        ,	mst.Stake
        ,	mst.Odds
        ,	mst.SequenceID
	FROM CTS_DataCenter.MatchMonitorRuleSetting AS mst
    WHERE 	mms.SequenceID <= ip_MaxSequenceID AND mms.MatchID = ip_MatchID AND mms.TotalScore = ip_TotalScore 
			AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.Betteam = ip_Betteam;
    
    SELECT mst.TotalStake,	mst.OddsSpread, mst.TimeStep
    INTO lv_Rule_TotalStake, lv_Rule_OddsSpread, lv_Rule_TimeStep
	FROM CTS_DataCenter.MatchMonitorRuleSetting AS mst
    WHERE RuleGroupID = CONST_RULE_GROUPID AND mst.SportType = ip_SportType;
	
    #==============================================================
    SELECT ParameterValue
    INTO lv_LastSequenceID
    FROM CTS_DataCenter.SystemParameter AS s
    WHERE ParameterID = 125;
    
    INSERT INTO Temp_OldCustGroup(CustID, MaxTransDateSec, OldGroupID, TotalStake)
    SELECT	mms.CustID
		,	MAX(TransDateSecond) AS MaxTransDateSec
        ,	MAX(OldGroupID) AS OldGroupID
		,	SUM(Stake) AS TotalStake
    FROM Temp_Trans AS tmp
    WHERE mms.SequenceID <= lv_LastSequenceID 
    GROUP BY mms.CustID;      
    
    UPDATE Temp_Trans AS tmpTs
		INNER JOIN Temp_OldCustGroup AS tmpOg ON tmpTs.CustID = tmpOg.CustID
	SET tmpTs.GroupID = tmpOg.OldGroupID
		, tmpTs.OldGroupID = tmpOg.OldGroupID
	WHERE tmpTs.SequenceID > ip_LastSequenceID
		 AND tmpTs.MinTransDateSecond - tmpOg.MaxTransDateSec <= lv_Rule_TimeStep;
         
	INSERT INTO Temp_NewCustGroup(CustID, MinTransDateSec, TotalStake)
    SELECT 	tmpTs.CustID
		,	MIN(TransDateSecond) AS MinTransDateSec
		,	SUM(Stake) AS TotalStake
    FROM Temp_Trans AS tmpTs
    WHERE mms.SequenceID > lv_LastSequenceID AND mms.SequenceID <= ip_MaxSequenceID AND GroupID = 0
    GROUP BY mms.CustID;    
    
    UPDATE Temp_Trans AS tmpTs
	SET tmpTs.GroupID = 1
    WHERE tmpTs.OldGroupID = 0
		AND tmpTs.CustID IN (	SELECT DISTINCT tmpNg.CustID
								FROM Temp_NewCustGroup AS tmpNg
									INNER JOIN Temp_OldCustGroup AS tmpOg ON tmpNg.CustID = tmpOg.CustID
								WHERE tmpNg.MinTransDateSecond - tmpOg.MaxTransDateSec <= lv_Rule_TimeStep AND tmpNg.TotalStale + tmpOg.TotalStake >= lv_Rule_TotalStake); 
    
	#=====GET Previous Cust BY Step Time
    SELECT tmpRs.CustID
		, tmpRs.TransIDList
        , tmpRs.OldGroupID
    FROM (
			SELECT	mms.CustID
				,	GROUP_CONCAT(CASE WHEN GroupID = 0 THEN mms.TransID END) AS TransIDList
				,	MAX(mms.GroupID) AS OldGroupID
			FROM CTS_DataCenter.MatchMonitorStagingIrrigationNonLive AS mms
				INNER JOIN Temp_CustGroup AS tmpCg ON mms.CustID = tmpCg.CustID AND mms.TransDate BETWEEN tmpCg.MinTransDateSec AND MaxTransDate
			WHERE mms.SequenceID <= ip_MaxSequenceID AND mms.MatchID = ip_MatchID AND mms.TotalScore = ip_TotalScore AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.Betteam = ip_Betteam
			GROUP BY mms.CustID
			HAVING SUM(mms.Stake) >= lv_Rule_TotalStake AND (MAX(mms.Odds) - MIN(mms.Odds))*100 >= lv_Rule_OddsSpread) AS tmpRs
	WHERE tmpRs.TransIDList IS NOT NULL;    
    
END$$
DELIMITER ;
