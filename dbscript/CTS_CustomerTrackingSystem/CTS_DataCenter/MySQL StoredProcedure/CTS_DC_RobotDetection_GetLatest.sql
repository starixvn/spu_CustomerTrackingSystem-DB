/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RobotDetection_GetLatest`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotDetection_GetLatest`(
		IN 	ip_LatestTimeAI					DATETIME
	,	IN	ip_LatestTimeImperva			DATETIME		
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220523@Long.Luu
		Task:		Get Latest Robot Info to push to CTS [Redmine ID: #172561]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20220523@Long.Luu: 		Created -  Robot Detection [Redmine ID: #172561]
			- 20230315@Victoria.Le:		Get Robot Imperva [Redmine ID: #184773]
            
		Example:
			call CTS_DataCenter.CTS_DC_RobotDetection_GetLatest ('2022-01-01 02:02:02.000','2022-01-01 02:02:02.000');
	*/    
    
    DECLARE CONST_BATCHSIZE 	INT UNSIGNED DEFAULT(5000);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_RobotImperva;    
	CREATE TEMPORARY TABLE Temp_RobotImperva(	  
			LogID		BIGINT
	);
	
	INSERT INTO Temp_RobotImperva (LogID)
	SELECT LogID
	FROM CTS_DataCenter.RobotImperva
	WHERE CreateTime >= ip_LatestTimeImperva
		AND IsScan = 0
	LIMIT CONST_BATCHSIZE;
    
    SELECT CustID, MAX(LastModifiedDate) AS LastModifiedDate
    FROM CTS_DataCenter.RobotDetection
    WHERE LastModifiedDate >= ip_LatestTimeAI
		AND IsDisabled = 0
	GROUP BY CustID
    LIMIT CONST_BATCHSIZE;

	SELECT r.LogID, r.CustID, r.CreateTime AS LastCreateTime
	FROM CTS_DataCenter.RobotImperva AS r
		INNER JOIN Temp_RobotImperva AS tmp ON tmp.LogID = r.LogID;

END$$	
DELIMITER ;