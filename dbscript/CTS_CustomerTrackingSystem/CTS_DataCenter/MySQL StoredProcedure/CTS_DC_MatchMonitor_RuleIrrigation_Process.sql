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
	
    DROP TEMPORARY TABLE IF EXISTS Temp_OldCustGroup;   
    CREATE TEMPORARY TABLE Temp_OldCustGroup(
			CustID	BIGINT UNSIGNED
		,	PRIMARY KEY (CustID)
	) ENGINE=InnoDB;
    
    SELECT mst.TotalStake,	mst.OddsSpread
    INTO lv_Rule_TotalStake, lv_Rule_OddsSpread
	FROM CTS_DataCenter.MatchMonitorRuleSetting AS mst
    WHERE RuleGroupID = CONST_RULE_GROUPID AND mst.SportType = ip_SportType;

	#=====GET Previous Cust BY Step Time
    SELECT	mms.CustID
		,	GROUP_CONCAT(CASE WHEN GroupID = 0 THEN mms.TransID END) AS TransIDList
        ,	MAX(mms.GroupID) AS OldGroupID
    FROM CTS_DataCenter.MatchMonitorStagingIrrigationNonLive AS mms
    WHERE mms.SequenceID <= ip_MaxSequenceID
		AND mms.MatchID = ip_MatchID AND mms.TotalScore = ip_TotalScore AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.Betteam = ip_Betteam
	GROUP BY mms.CustID
    HAVING SUM(mms.Stake) >= lv_Rule_TotalStake AND (MAX(mms.Odds) - MIN(mms.Odds))*100 >= lv_Rule_OddsSpread;    
    
END$$
DELIMITER ;
