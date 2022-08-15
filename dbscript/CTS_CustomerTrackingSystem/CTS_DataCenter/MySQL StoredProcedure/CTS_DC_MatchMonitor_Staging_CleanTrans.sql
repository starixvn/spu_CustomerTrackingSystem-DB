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
		Task :		Match Monitor Rule
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220726@Casey.Huynh: Created [Redmine ID: #175700]
            
		Param's Explanation (filtered by):
			CALL CTS_DC_MatchMonitor_Staging_CleanTrans(1,2);
		Example:
			
	*/
	
    DECLARE	lv_LastTransID 		BIGINT;    
    	
    #======Clean Staging=================================================
    IF (ip_LiveIndicator = 1) THEN		
		
		SELECT  MAX(mmt.TransID)
		INTO 	lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorTransLive AS mmt
		WHERE	mmt.TransID < ip_MaxTransID AND StatusRule02 = 1; 		
        
        IF lv_LastTransID > 0 THEN	
			DELETE 	mmt
			FROM	CTS_DataCenter.MatchMonitorTransLive AS mmt
			WHERE	mmt.TransID <= lv_LastTransID;
            
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = lv_LastTransID
			WHERE 	sys.ParameterID = 100;
		END IF;
    END IF;    
    
	IF (ip_LiveIndicator = 0) THEN		
		
		SELECT  MAX(mmt.TransID)
		INTO 	lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorTransNonLive AS mmt
		WHERE	mmt.TransID < ip_MaxTransID AND StatusRule02 = 1; 		
        
        IF lv_LastTransID > 0 THEN	
			DELETE 	mmt
			FROM	CTS_DataCenter.MatchMonitorTransNonLive AS mmt
			WHERE	mmt.TransID <= lv_LastTransID;
            
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = lv_LastTransID
			WHERE 	sys.ParameterID = 101;
		END IF;
    END IF;    
    
    
END$$
DELIMITER ;
