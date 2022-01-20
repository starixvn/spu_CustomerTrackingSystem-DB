/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule_Get`(
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
			- 	20210924@Casey.Huynh: Created [Redmine ID: 159195]
            -	20220110@Casey.Huynh: Enhance MM(SportType, Betteam, BetID), Return BetID [Redmine ID: 166986]
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_MatchMonitor_Rule_Get(1,500,@MaxTrans);
			
	*/
	DECLARE lv_LastTransID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxTransID BIGINT UNSIGNED DEFAULT 0;
    
	IF ip_LiveIndicator = 1 THEN    
		SELECT sys.ParameterValue
        INTO lv_LastTransID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 47;
        
        SELECT MAX(tmp.TransID)
        INTO lv_MaxTransID
        FROM (SELECT mms.TransID FROM CTS_DataCenter.MatchMonitorStagingLive AS mms WHERE mms.TransID > lv_LastTransID ORDER BY mms.TransID LIMIT ip_NoOfRow) AS tmp;
        
        SET op_MaxTransID = IFNULL(lv_MaxTransID,0) ;
        
        IF(lv_LastTransID < lv_MaxTransID) THEN    
			SELECT	mms.MatchID
				,	mms.TotalScore
				,	mms.BettypeID
                ,	mms.BetID
			FROM CTS_DataCenter.MatchMonitorStagingLive AS mms
            WHERE mms.TransID <= lv_MaxTransID
			GROUP BY mms.MatchID, mms.TotalScore, mms.BettypeID, mms.BetID
			HAVING COUNT(DISTINCT mms.CustID) > 1 AND SUM(mms.Stake) >= 500;      
            
		END IF;
	ELSE
		SELECT sys.ParameterValue
        INTO lv_LastTransID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 48;
        
        SELECT MAX(tmp.TransID)
        INTO lv_MaxTransID
        FROM (SELECT mms.TransID FROM CTS_DataCenter.MatchMonitorStagingNonLive AS mms WHERE mms.TransID > lv_LastTransID ORDER BY mms.TransID  LIMIT ip_NoOfRow) AS tmp;
		
		SET op_MaxTransID = IFNULL(lv_MaxTransID, 0);        
        
        IF(lv_LastTransID < lv_MaxTransID) THEN            
			SELECT	mms.MatchID
				,	mms.TotalScore
				,	mms.BettypeID
                ,	mms.BetID
			FROM CTS_DataCenter.MatchMonitorStagingNonLive AS mms
            WHERE mms.TransID <= lv_MaxTransID
			GROUP BY mms.MatchID, mms.TotalScore, mms.BettypeID, mms.BetID
			HAVING COUNT(DISTINCT mms.CustID) > 1 AND SUM(mms.Stake) >= 500;            
		END IF;
        
	END IF;
    
   # INSERT INTO CTS_DataCenter.MatchMonitor_Log(SPName,ip_LiveIndicator,ip_MaxTransID, InsertTime)
	#SELECT 'CTS_DC_MatchMonitor_Rule_Get',ip_LiveIndicator,op_MaxTransID,CURRENT_TIMESTAMP(3);
END$$
DELIMITER ;
