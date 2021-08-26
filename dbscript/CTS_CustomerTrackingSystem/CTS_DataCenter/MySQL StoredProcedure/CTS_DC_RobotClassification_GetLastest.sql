/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_RobotClassification_GetLastest`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotClassification_GetLastest`(
		IN ip_CustID 			BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
sp : BEGIN
	/*
		Created:	20210818@Harvey.Nguyen
		Task:		Get lastest robot classification
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210818@Harvey.Nguyen: Created [Redmine ID: #160382]
            
        Example:
			- CALL CTS_DataCenter.CTS_DC_RobotClassification_GetLastest(16905114);
	*/
	
    WITH lastestClassification
	AS (
		SELECT CustID
			,SportTypeID
			,BetTypeID
			,LiveIndicator
			,MAX(FromDate) AS 'ScannedDate'
		FROM CTS_DataCenter.RobotClassification
		WHERE CustID = ip_CustID
		GROUP BY CustID
			,SportTypeID
			,BetTypeID
			,LiveIndicator
		)
	SELECT lc.*, rc.RobotType
	FROM lastestClassification lc
	INNER JOIN RobotClassification rc ON lc.CustID = rc.CustID
		AND lc.SportTypeID = rc.SportTypeID
		AND lc.BetTypeID = rc.BetTypeID
		AND lc.LiveIndicator = rc.LiveIndicator
		AND lc.ScannedDate = rc.FromDate;

END$$

DELIMITER ;