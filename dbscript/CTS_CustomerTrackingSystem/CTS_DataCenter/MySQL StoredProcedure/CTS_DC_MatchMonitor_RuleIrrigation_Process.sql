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
			SequenceID			BIGINT UNSIGNED
		,	TransID				BIGINT UNSIGNED
		,	CustID				BIGINT UNSIGNED
		,	TransDateSec		BIGINT        
        ,	Stake				DECIMAL(20,4)
        ,	Odds				DECIMAL(4,2)
        ,	OldGroupID			INT         
        ,	GroupID				INT DEFAULT 0
		,	PRIMARY KEY (SequenceID)
		,	INDEX IX_Temp_Trans_Cust(CustID)
	) ENGINE=InnoDB;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_OldCustGroup;   
    CREATE TEMPORARY TABLE Temp_OldCustGroup(    
			CustID				BIGINT UNSIGNED
		,	MaxTransDateSec		BIGINT
        ,	OldGroupID 			INT
        ,	TotalStake			DECIMAL(20,4)
        ,	MinOdds				DECIMAL(4,2)
        ,	MaxOdds				DECIMAL(4,2)
		,	PRIMARY KEY (CustID)
	) ENGINE=InnoDB;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewCustGroup;   
    CREATE TEMPORARY TABLE Temp_NewCustGroup(    
			CustID			BIGINT UNSIGNED
		,	MinTransDateSec	BIGINT
        ,	TotalStake		DECIMAL(20,4)
        ,	MinOdds				DECIMAL(4,2)
        ,	MaxOdds				DECIMAL(4,2)
		,	PRIMARY KEY (CustID)
	) ENGINE=InnoDB;
    
    INSERT INTO Temp_Trans(SequenceID, TransID, CustID, TransDateSec, Stake, Odds,OldGroupID)
    SELECT	mms.SequenceID
        ,	mms.TransID
		,	mms.CustID
		,	TO_SECONDS(mms.TransDate) AS TransDateSec
        ,	mms.Stake        
        ,	mms.Odds
        ,	mms.GroupID AS OldGroupID        
	FROM CTS_DataCenter.MatchMonitorStagingIrrigationNonLive AS mms
    WHERE 	mms.SequenceID <= ip_MaxSequenceID AND mms.MatchID = ip_MatchID AND mms.TotalScore = ip_TotalScore 
			AND mms.BettypeID = ip_BettypeID AND mms.BetID = ip_BetID AND mms.Betteam = ip_Betteam;
    
    SELECT mst.TotalStake,	mst.OddsSpread, mst.TimeStep
    INTO lv_Rule_TotalStake, lv_Rule_OddsSpread, lv_Rule_TimeStep
	FROM CTS_DataCenter.MatchMonitorRuleSetting AS mst
    WHERE RuleGroupID = CONST_RULE_GROUPID AND mst.SportType = ip_SportType;
	
    #=================GET OLD GROUP=============================================
    SELECT ParameterValue
    INTO lv_LastSequenceID
    FROM CTS_DataCenter.SystemParameter AS s
    WHERE ParameterID = 125;
    
    INSERT INTO Temp_OldCustGroup(CustID, MaxTransDateSec, OldGroupID, TotalStake, MinOdds, MaxOdds)
    SELECT	tmpTs.CustID
		,	MAX(tmpTs.TransDateSec) AS MaxTransDateSec
        ,	MAX(tmpTs.OldGroupID) AS OldGroupID
		,	SUM(tmpTs.Stake) AS TotalStake
        ,	MIN(Odds) AS MinOdds
        ,	MAX(Odds) AS MaxOdds
    FROM Temp_Trans AS tmpTs
    WHERE tmpTs.SequenceID <= lv_LastSequenceID
    GROUP BY tmpTs.CustID;      
	
    UPDATE Temp_Trans AS tmpTs
		INNER JOIN Temp_OldCustGroup AS tmpOg ON tmpTs.CustID = tmpOg.CustID
	SET tmpTs.GroupID = tmpOg.OldGroupID
		, tmpTs.OldGroupID = tmpOg.OldGroupID
	WHERE tmpTs.SequenceID > lv_LastSequenceID
		 AND tmpTs.TransDateSec - tmpOg.MaxTransDateSec <= lv_Rule_TimeStep;
         
	#=================GET NEW GROUP=============================================
	INSERT INTO Temp_NewCustGroup(CustID, MinTransDateSec, TotalStake, MinOdds, MaxOdds)
    SELECT 	tmpTs.CustID
		,	MIN(tmpTs.TransDateSec) AS MinTransDateSec
		,	SUM(tmpTs.Stake) AS TotalStake
        ,	MIN(Odds) AS MinOdds
        ,	MAX(Odds) AS MaxOdds
    FROM Temp_Trans AS tmpTs
    WHERE tmpTs.SequenceID > lv_LastSequenceID AND tmpTs.SequenceID <= ip_MaxSequenceID AND tmpTs.GroupID = 0
    GROUP BY tmpTs.CustID;    

    UPDATE Temp_Trans AS tmpTs
	SET tmpTs.GroupID = 1
    WHERE tmpTs.OldGroupID = 0
		AND tmpTs.CustID IN (	SELECT DISTINCT tmpNg.CustID
								FROM Temp_NewCustGroup AS tmpNg
									INNER JOIN Temp_OldCustGroup AS tmpOg ON tmpNg.CustID = tmpOg.CustID
								WHERE	tmpNg.MinTransDateSec - tmpOg.MaxTransDateSec <= lv_Rule_TimeStep 
									AND tmpNg.TotalStake + tmpOg.TotalStake >= lv_Rule_TotalStake
                                     AND (GREATEST(tmpNg.MaxOdds,tmpOg.MaxOdds) - LEAST(tmpNg.MinOdds,tmpOg.MinOdds))*100 >= lv_Rule_OddsSpread); 

	#=====GET Previous Cust BY Step Time
    SELECT	tmpTs.CustID
		,	GROUP_CONCAT(tmpTs.TransID) AS TransIDList
		,	MAX(tmpTs.OldGroupID) AS OldGroupID
	FROM Temp_Trans AS tmpTs 
	WHERE tmpTs.GroupID > 0
	GROUP BY tmpTs.CustID;
    
END$$
DELIMITER ;
