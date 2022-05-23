/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RobotDetection_GetLatest`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotDetection_GetLatest`(
		IN ip_LatestScannedTime		DATETIME
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220523@Long.Luu
		Task:		Get Latest Robot Detection Info to push to CTS [Redmine ID: #172561]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20220523@Long.Luu: Created [Redmine ID: #172561]
            
		Example:
			call CTS_DataCenter.CTS_DC_RobotDetection_GetLatest ('2022-01-01 02:02:02.000');
	*/    
    
    DECLARE CONST_BATCHSIZE 	INT UNSIGNED DEFAULT(5000);
    
    SELECT CustID, MAX(LastModifiedDate) AS LastModifiedDate
    FROM RobotDetection
    WHERE LastModifiedDate >= ip_LatestScannedTime
		AND IsDisabled = 0
	GROUP BY CustID
    LIMIT CONST_BATCHSIZE;
    
END$$	
DELIMITER ;