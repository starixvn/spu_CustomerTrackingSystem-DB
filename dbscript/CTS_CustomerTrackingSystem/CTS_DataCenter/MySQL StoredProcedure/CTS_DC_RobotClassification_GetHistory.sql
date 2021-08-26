/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_RobotClassification_GetHistory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotClassification_GetHistory`(
		IN ip_CustID 			BIGINT UNSIGNED,
        IN ip_FromDate			DATETIME,
        IN ip_ToDate			DATETIME
)
    SQL SECURITY INVOKER
sp : BEGIN
	/*
		Created:	20210818@Harvey.Nguyen
		Task:		Get history's robot classification
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210818@Harvey.Nguyen: Created [Redmine ID: #160382]
            
        Example:
			- CALL CTS_DataCenter.CTS_DC_RobotClassification_GetHistory(16905114,'2021-05-30','2021-06-30');
	*/
	
    SELECT CustID
		, SportTypeID
		, BetTypeID
		, LiveIndicator
		, RobotType
		, FromDate AS 'ScannedDate'
	FROM CTS_DataCenter.RobotClassification
	WHERE CustID = ip_CustID
		AND FromDate BETWEEN ip_FromDate AND ip_ToDate
	ORDER BY FromDate DESC;


END$$

DELIMITER ;