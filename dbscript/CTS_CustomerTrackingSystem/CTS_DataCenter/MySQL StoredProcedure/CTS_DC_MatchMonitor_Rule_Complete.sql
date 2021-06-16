/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_Rule_Complete`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_Rule_Complete`(
)
  SQL SECURITY INVOKER
BEGIN
		/*Created:	20210526@Casey.Huynh
		Task :		Match Monitor Insert trans ticket to Staging table
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Casey.Huynh: Created [Redmine ID: 152883]
		
		Param's Explanation (filtered by):
		CALLCTS_DC_MatchMonitor_Rule_Complete();

		Example:
			
	*/
    DECLARE	lv_Last3mMinTime DATETIME(3);
    DECLARE	lv_Last3mMaxTime DATETIME(3);  
	DECLARE	lv_LastTransID BIGINT;   
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Last3mTransGroup;
    CREATE TEMPORARY TABLE Temp_Last3mTransGroup
    (
		OriginGroupID	INT
    );
    
    SELECT 	MAX(TransDate) , MAX(TransID)
    INTO 	lv_Last3mMaxTime, lv_LastTransID
    FROM	CTS_DataCenter.MatchMonitorStaging;    
    
    SELECT  MIN(TransDate) 
    INTO 	lv_Last3mMinTime
    FROM	CTS_DataCenter.MatchMonitorStaging
    WHERE   TransDate > TIMESTAMPADD(SECOND, -180, lv_Last3mMaxTime);  
    
    INSERT INTO Temp_Last3mTransGroup(OriginGroupID)
    SELECT 	DISTINCT OriginGroupID
    FROM 	CTS_DataCenter.MatchMonitorStaging
    WHERE	TransDate >= lv_Last3mMinTime;
    
    DELETE 	mms
    FROM	CTS_DataCenter.MatchMonitorStaging AS mms
		LEFT JOIN Temp_Last3mTransGroup AS tmpTg ON mms.OriginGroupID = tmpTg.OriginGroupID
	WHERE	mms.TransDate < lv_Last3mMinTime AND tmpTg.OriginGroupID IS NULL;    

	/* Update Parameter*/
    UPDATE 	CTS_DataCenter.SystemParameter
    SET 	ParameterValue = lv_LastTransID
    WHERE 	ParameterID = 20;
END$$
DELIMITER ;
