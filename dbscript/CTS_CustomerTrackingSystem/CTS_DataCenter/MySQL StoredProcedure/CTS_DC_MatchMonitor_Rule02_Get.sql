/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule02_Get_xtest`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule02_Get_xtest`(
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
			CALL  CTS_DC_MatchMonitor_Rule02_Get_xtest(1,500,@MaxTrans);
			
	*/   
	
	IF ip_LiveIndicator = 1 THEN
       
        SELECT DISTINCT mmt.MatchID
				,	mmt.TotalScore
				,	mmt.BettypeID
                ,	mmt.BetID
                ,	mmt.Betteam
		FROM CTS_DataCenter.MatchMonitorTransLive AS mmt
		WHERE mmt.StatusRule02 = 0 AND mmt.IsMajorLeague = 0;

	ELSE
    
        SELECT DISTINCT mmt.MatchID
				,	mmt.TotalScore
				,	mmt.BettypeID
                ,	mmt.BetID
                ,	mmt.Betteam
		FROM CTS_DataCenter.MatchMonitorTransNonLive AS mmt
		WHERE mmt.StatusRule02 = 0 AND mmt.IsMajorLeague = 0;       
        
	END IF;
    
END$$
DELIMITER ;
