/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule02_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule02_Get`(
		IN	ip_LiveIndicator	BOOLEAN
	,	IN  ip_NoOfRow 			INT
	,	OUT	op_MaxTransID		BIGINT UNSIGNED
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
            
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_MatchMonitor_Rule02_Get(@ip_LiveIndicator:=1,@ip_NoOfRow:=500,@op_MaxTransID); SELECT @ip_LiveIndicator, @ip_NoOfRow, @op_MaxTransID;
			
	*/   
	DECLARE lv_LastTransID BIGINT UNSIGNED;
    
	IF ip_LiveIndicator = 1 THEN
		
        SELECT s.ParameterValue
        INTO lv_LastTransID
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 100;
        
        SELECT MAX(TransID)
        INTO op_MaxTransID
        FROM CTS_DataCenter.MatchMonitorTransLive AS mmt;
        
        SELECT DISTINCT mmt.MatchID
				,	mmt.TotalScore
				,	mmt.BettypeID
                ,	mmt.BetID
                ,	mmt.Betteam			
		FROM CTS_DataCenter.MatchMonitorTransLive AS mmt
		WHERE mmt.StatusRule02 = 0 AND mmt.IsMajorLeague = 0
			AND mmt.TransID > lv_LastTransID;       

	ELSE
		SELECT s.ParameterValue
        INTO lv_LastTransID
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 101;
        
		SELECT MAX(TransID)
        INTO op_MaxTransID
        FROM CTS_DataCenter.MatchMonitorTransNonLive AS mmt;
        
        SELECT DISTINCT mmt.MatchID
				,	mmt.TotalScore
				,	mmt.BettypeID
                ,	mmt.BetID
                ,	mmt.Betteam
		FROM CTS_DataCenter.MatchMonitorTransNonLive AS mmt
		WHERE mmt.StatusRule02 = 0 AND mmt.IsMajorLeague = 0
			AND mmt.TransID > lv_LastTransID;       
        
	END IF;

END$$
DELIMITER ;
