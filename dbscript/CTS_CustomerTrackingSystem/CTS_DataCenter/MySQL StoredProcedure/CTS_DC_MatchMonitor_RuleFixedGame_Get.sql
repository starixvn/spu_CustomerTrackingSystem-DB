/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_RuleFixedGame_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_RuleFixedGame_Get`(
		IN	ip_LiveIndicator	BOOLEAN
	,	OUT	op_MaxSequenceID	BIGINT UNSIGNED
)
	SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220726@Casey.Huynh: Created [Redmine ID: #175700]
            - 20220815@Casey.Huynh: Scale Out DB [Redmine ID: #176472]
            - 20221205@Casey.Huynh: Rename Table and update rule [Redmine ID: #181205]
            
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_MatchMonitor_RuleFixedGame_Get(@ip_LiveIndicator:=1,@op_MaxSequenceID); SELECT @ip_LiveIndicator,  @op_MaxSequenceID;
			
	*/  
	DECLARE CONST_RULE_GROUPID_FIXEDGAME INT DEFAULT 2;
    DECLARE lv_LastSequenceID BIGINT UNSIGNED;   
    DECLARE lv_BatchSize INT UNSIGNED;
    
    #============DEBUG LOG========================
    DECLARE SPName VARCHAR(200) DEFAULT 'CTS_DC_MatchMonitor_RuleFixedGame_Get';
	INSERT INTO CTS_Log.CTSLog(LogName, InsertTime, OtherText)
    SELECT SPName, current_timestamp(),ip_LiveIndicator;   
    
	IF ip_LiveIndicator = 1 THEN
		
        SELECT s.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 100;
        
		SELECT s.ParameterValue
        INTO lv_BatchSize
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 126;        

        SELECT MAX(mms.SequenceID)
        INTO op_MaxSequenceID
        FROM CTS_DataCenter.MatchMonitorStagingFixedGameLive AS mms
        WHERE mms.SequenceID > lv_LastSequenceID
        LIMIT lv_BatchSize;
        
        SELECT DISTINCT mmt.MatchID
			,	mmt.ScoreDiff
			,	mmt.BettypeID
			,	mmt.BetID
			,	mmt.HDP
			,	mmt.Betteam			
		FROM CTS_DataCenter.MatchMonitorStagingFixedGameLive AS mmt
		WHERE mmt.SequenceID > lv_LastSequenceID AND mmt.SequenceID <= op_MaxSequenceID;          

	ELSE
		SELECT s.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 101;
        
		SELECT s.ParameterValue
        INTO lv_BatchSize
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 127;        
                  
        SELECT MAX(mms.SequenceID)
        INTO op_MaxSequenceID
        FROM CTS_DataCenter.MatchMonitorStagingFixedGameNonLive AS mms
        WHERE mms.SequenceID > lv_LastSequenceID
        LIMIT lv_BatchSize;
        
        SELECT DISTINCT mmt.MatchID
			,	mmt.ScoreDiff
			,	mmt.BettypeID
			,	mmt.BetID
			,	mmt.HDP
			,	mmt.Betteam			
		FROM CTS_DataCenter.MatchMonitorStagingFixedGameNonLive AS mmt
		WHERE mmt.SequenceID > lv_LastSequenceID AND mmt.SequenceID <= op_MaxSequenceID;  
        
	END IF;

END$$
DELIMITER ;
