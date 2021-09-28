/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Staging_Clean`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Staging_Clean`(
		IN ip_LiveIndicator BOOLEAN
	,	IN ip_MaxTransID BIGINT UNSIGNED
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
            
		Param's Explanation (filtered by):

		Example:
			
	*/
	DECLARE	lv_Last3mMinTime 	DATETIME(3);
    DECLARE	lv_Last3mMaxTime 	DATETIME(3);  
	DECLARE	lv_LastTransID 		BIGINT;   
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Last3mTransGroup;
    CREATE TEMPORARY TABLE Temp_Last3mTransGroup
    (
			MatchID INT
        ,	TotalScore SMALLINT
        ,	BettypeID INT 
        ,   GroupID INT
        
        ,	PRIMARY KEY (MatchID,TotalScore,BettypeID,GroupID)
    );
	
    #======Clean Staging=================================================
    IF (ip_LiveIndicator = 1) THEN		
		SELECT 	MAX(mms.TransDate) , MAX(mms.TransID)
		INTO 	lv_Last3mMaxTime, lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorStagingLive AS mms
        WHERE	mms.TransID <= ip_MaxTransID;    
		
		SELECT  MIN(TransDate) 
		INTO 	lv_Last3mMinTime
		FROM	CTS_DataCenter.MatchMonitorStagingLive
		WHERE   TransDate > TIMESTAMPADD(SECOND, -180, lv_Last3mMaxTime);  
			
		INSERT INTO Temp_Last3mTransGroup(MatchID, TotalScore, BettypeID, GroupID)
		SELECT 	DISTINCT mms.MatchID,  mms.TotalScore, mms.BettypeID, mms.GroupID
		FROM 	CTS_DataCenter.MatchMonitorStagingLive mms
		WHERE	mms.TransDate >= lv_Last3mMinTime AND mms.GroupID IS NOT NULL;
		
		DELETE 	mms
		FROM	CTS_DataCenter.MatchMonitorStagingLive AS mms
			LEFT JOIN Temp_Last3mTransGroup AS tmpTg ON mms.MatchID = tmpTg.MatchID 
				AND mms.TotalScore = tmpTg.TotalScore AND mms.BettypeID = tmpTg.BettypeID  AND mms.GroupID = tmpTg.GroupID
		WHERE	mms.TransDate < lv_Last3mMinTime  AND tmpTg.GroupID IS NULL ;    
        
        /* Update Parameter*/
        IF lv_LastTransID > 0 THEN			
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = ip_MaxTransID
			WHERE 	sys.ParameterID = 42;
		END IF;
	END IF;
    
    IF (ip_LiveIndicator = 0) THEN		
		SELECT 	MAX(TransDate) , MAX(TransID)
		INTO 	lv_Last3mMaxTime, lv_LastTransID
		FROM	CTS_DataCenter.MatchMonitorStagingNonLive;    
		
		SELECT  MIN(TransDate) 
		INTO 	lv_Last3mMinTime
		FROM	CTS_DataCenter.MatchMonitorStagingNonLive
		WHERE   TransDate > TIMESTAMPADD(SECOND, -180, lv_Last3mMaxTime);  
			
		INSERT INTO Temp_Last3mTransGroup(MatchID, TotalScore, BettypeID, GroupID)
		SELECT 	DISTINCT mms.MatchID,  mms.TotalScore, mms.BettypeID, mms.GroupID
		FROM 	CTS_DataCenter.MatchMonitorStagingNonLive mms
		WHERE	mms.TransDate >= lv_Last3mMinTime AND mms.GroupID IS NOT NULL;
		
		DELETE 	mms
		FROM	CTS_DataCenter.MatchMonitorStagingNonLive AS mms
			LEFT JOIN Temp_Last3mTransGroup AS tmpTg ON mms.MatchID = tmpTg.MatchID 
				AND mms.TotalScore = tmpTg.TotalScore AND mms.BettypeID = tmpTg.BettypeID  AND mms.GroupID = tmpTg.GroupID
		WHERE	mms.TransDate < lv_Last3mMinTime  AND tmpTg.GroupID IS NULL ;    
        
        /* Update Parameter*/
        IF lv_LastTransID > 0 THEN	
			UPDATE 	CTS_DataCenter.SystemParameter AS sys
			SET 	sys.ParameterValue = ip_MaxTransID
			WHERE 	sys.ParameterID = 43;
		END IF;
        
	END IF;
    
END$$
DELIMITER ;
