/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleIrrigation_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleIrrigation_Get`(
		IN	ip_LiveIndicator	BOOLEAN
	,	OUT	op_MaxSequenceID	BIGINT UNSIGNED
)
	SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20211122@Casey.Huynh
		Task :		Match Monitor Rule Irrigation Get
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20211122@Casey.Huynh: Created [Redmine ID: #179499]
            
		Param's Explanation (filtered by):	
			
		Example:
			CALL CTS_DC_MatchMonitor_RuleIrrigation_Get(@ip_LiveIndicator:=0,@op_MaxSequenceID); SELECT @ip_LiveIndicator,  @op_MaxSequenceID;
			
	*/ 
    DECLARE CONST_RULE_GROUPID INT DEFAULT 4;
    
    DECLARE	lv_Rule_Reason		TINYINT;
    DECLARE lv_Rule_MinTimeStep	SMALLINT;    
    
	DECLARE lv_BatchSize 		BIGINT UNSIGNED;
	DECLARE lv_LastSequenceID	BIGINT UNSIGNED;
    DECLARE lv_MaxTransDate		DATETIME(3);    
    
	SELECT MIN(mst.TimeStep)
	INTO lv_Rule_MinTimeStep
	FROM CTS_DataCenter.MatchMonitorRuleSetting AS mst
	WHERE mst.RuleGroupID = CONST_RULE_GROUPID;    
	
	#===================LOG=======================================
    INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
    SELECT'CTS_DC_MatchMonitor_RuleIrrigation_Get', current_timestamp(), CONCAT('ip_LiveIndicator:',ip_LiveIndicator,'op_MaxSequenceID:',op_MaxSequenceID);
    
	IF ip_LiveIndicator = 0 THEN		

        #===GET BATCH SIZE AND THE LAST SEQUENCEID =====
        SELECT s.ParameterValue
        INTO lv_BatchSize
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 124;
        
		SELECT s.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 125;

        SELECT TIMESTAMPADD(SECOND, lv_Rule_MinTimeStep, mms.TransDate)
        INTO lv_MaxTransDate
        FROM CTS_DataCenter.MatchMonitorStagingIrrigationNonLive AS mms
        WHERE mms.SequenceID > lv_LastSequenceID
        ORDER BY mms.SequenceID
        LIMIT 1;        
    
        SELECT MAX(temp.SequenceID)
        INTO op_MaxSequenceID
        FROM (	SELECT mms.SequenceID
				FROM CTS_DataCenter.MatchMonitorStagingIrrigationNonLive AS mms
				WHERE mms.SequenceID > lv_LastSequenceID AND mms.TransDate <= lv_MaxTransDate
				ORDER BY mms.SequenceID
				LIMIT lv_BatchSize) AS temp;
        
        SELECT DISTINCT	mmt.MatchID
				,	mmt.TotalScore
				,	mmt.BettypeID
                ,	mmt.BetID
                ,	mmt.Betteam
                ,	mmt.SportType
		FROM CTS_DataCenter.MatchMonitorStagingIrrigationNonLive AS mmt
		WHERE mmt.SequenceID > lv_LastSequenceID AND mmt.SequenceID <= op_MaxSequenceID;      
	END IF;
END$$
DELIMITER ;
