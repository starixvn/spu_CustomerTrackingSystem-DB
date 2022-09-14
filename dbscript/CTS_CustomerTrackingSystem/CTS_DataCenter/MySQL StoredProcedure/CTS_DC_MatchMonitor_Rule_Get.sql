/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule_Get`(
		IN	ip_LiveIndicator	BOOLEAN
	,	IN  ip_NoOfRow 			INT
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
			- 	20210924@Casey.Huynh: Created [Redmine ID: 159195]
            -	20220110@Casey.Huynh: Enhance MM(SportType, Betteam, BetID), Return BetID [Redmine ID: 166986]
            -	20220217@Casey.Huynh: Enhance MM, Update TO >= 1000 [Redmine ID: 168736]
            -	20220815@Casey.Huynh: Scale Out DB [Redmine ID: #176472]
            
		Param's Explanation (filtered by):	

		Example:
			CALL  CTS_DC_MatchMonitor_Rule_Get(1,500,@MaxTrans);
			
	*/
	DECLARE lv_LastSequenceID BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxSequenceID BIGINT UNSIGNED DEFAULT 0;
    
	IF ip_LiveIndicator = 1 THEN    
		SELECT sys.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 47;
        
        SELECT MAX(tmp.SequenceID)
        INTO lv_MaxSequenceID
        FROM (SELECT mms.SequenceID FROM CTS_DataCenter.MatchMonitorStagingLive AS mms WHERE mms.SequenceID > lv_LastSequenceID ORDER BY mms.SequenceID LIMIT ip_NoOfRow) AS tmp;
        
        SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID,0) ;
        
        IF(lv_LastSequenceID < lv_MaxSequenceID) THEN    
			SELECT	mms.MatchID
				,	mms.TotalScore
				,	mms.BettypeID
                ,	mms.BetID
			FROM CTS_DataCenter.MatchMonitorStagingLive AS mms
            WHERE mms.SequenceID <= lv_MaxSequenceID
			GROUP BY mms.MatchID, mms.TotalScore, mms.BettypeID, mms.BetID
			HAVING COUNT(DISTINCT mms.CustID) > 1 AND SUM(mms.Stake) >= 1000;      
            
		END IF;
	ELSE
		SELECT sys.ParameterValue
        INTO lv_LastSequenceID
        FROM CTS_DataCenter.SystemParameter AS sys
        WHERE ParameterID = 48;
        
        SELECT MAX(tmp.SequenceID)
        INTO lv_MaxSequenceID
        FROM (SELECT mms.SequenceID FROM CTS_DataCenter.MatchMonitorStagingNonLive AS mms WHERE mms.SequenceID > lv_LastSequenceID ORDER BY mms.SequenceID  LIMIT ip_NoOfRow) AS tmp;
		
		SET op_MaxSequenceID = IFNULL(lv_MaxSequenceID, 0);        
        
        IF(lv_LastSequenceID < lv_MaxSequenceID) THEN            
			SELECT	mms.MatchID
				,	mms.TotalScore
				,	mms.BettypeID
                ,	mms.BetID
			FROM CTS_DataCenter.MatchMonitorStagingNonLive AS mms
            WHERE mms.SequenceID <= lv_MaxSequenceID
			GROUP BY mms.MatchID, mms.TotalScore, mms.BettypeID, mms.BetID
			HAVING COUNT(DISTINCT mms.CustID) > 1 AND SUM(mms.Stake) >= 1000;            
		END IF;
        
	END IF;
 
END$$
DELIMITER ;
