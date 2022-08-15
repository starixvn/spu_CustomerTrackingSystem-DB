/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Staging_CleanTrans`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Staging_CleanTrans`(
		IN ip_LiveIndicator	BOOLEAN
	,	IN ip_MaxTransID	BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Casey.Huynh
		Task :		Match Monitor Insert trans ticket to Staging table
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 159195]
            -	20220110@Casey.Huynh: Enhance MM, Add SportType, Betteam, BetID [Redmine ID: 166986]
            
		Param's Explanation (filtered by):
			CALL CTS_DC_MatchMonitor_Staging_CleanTrans_xtest(1,2);
		Example:
			
	*/
	DECLARE	lv_MaxTransID 		BIGINT;   
    DECLARE	lv_MaxTransDate 	DATETIME(3);   
    DECLARE	lv_LastTransID 		BIGINT;  
    DECLARE	lv_LastTransDate	DATETIME(3);
    DECLARE	CONST_RULE_DURATION	SMALLINT DEFAULT 7; # 7 minutes
    
    	
    #======Clean Staging=================================================
    IF (ip_LiveIndicator = 1) THEN		
		SELECT 	mmt.TransDate, mmt.TransID 
		INTO 	lv_MaxTransDate, lv_MaxTransID
		FROM	CTS_DataCenter.MatchMonitorTransLive AS mmt
        WHERE	mmt.TransID <= ip_MaxTransID
        ORDER BY TransID DESC
        LIMIT 	1;    
		
		SELECT  MIN(mmt.TransDate), MIN(mmt.TransID)
		INTO 	lv_LastTransDate, lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorTransLive AS mmt
		WHERE   mmt.TransDate > TIMESTAMPADD(MINUTE, -CONST_RULE_DURATION, lv_MaxTransDate);  
		
		DELETE 	mmt
		FROM	CTS_DataCenter.MatchMonitorTransLive AS mmt
		WHERE	mmt.TransID < lv_LastTransID AND StatusRule02 = 1;    
        
        /* Update Parameter*/
        IF lv_LastTransID > 0 THEN			
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = lv_LastTransID
			WHERE 	sys.ParameterID = 100;
		END IF;
	END IF;
    
    IF (ip_LiveIndicator = 0) THEN		
		SELECT 	mmt.TransDate, mmt.TransID 
		INTO 	lv_MaxTransDate, lv_MaxTransID
		FROM	CTS_DataCenter.MatchMonitorNonTransLive AS mmt
        WHERE	mmt.TransID <= ip_MaxTransID
        ORDER BY TransID DESC
        LIMIT 	1;    
		
		SELECT  MIN(mmt.TransDate), MIN(mmt.TransID)
		INTO 	lv_LastTransDate, lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorNonTransLive AS mmt
		WHERE   TransDate > TIMESTAMPADD(MINUTE, -CONST_RULE_DURATION, lv_MaxTransDate);  
		
		DELETE 	mmt
		FROM	CTS_DataCenter.MatchMonitorNonTransLive AS mmt
		WHERE	mmt.TransID < lv_LastTransID AND StatusRule02 = 1;    
        
        /* Update Parameter*/
        IF lv_LastTransID > 0 THEN			
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = lv_LastTransID
			WHERE 	sys.ParameterID = 101;
		END IF;
        
	END IF;
    
END$$
DELIMITER ;
