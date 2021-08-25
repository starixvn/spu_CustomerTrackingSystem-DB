/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_RobotClassification_GetRobotStatus`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotClassification_GetRobotStatus`(
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
		Explanation:
			- RobotType: 2-Bad | 1-Good | 0:Observed | -1:No data
        Example:
			- CALL CTS_DataCenter.CTS_DC_RobotClassification_GetRobotStatus(135125302);
	*/
    
    DROP TEMPORARY TABLE IF EXISTS tmpLastestRobotClassification;  
	CREATE TEMPORARY TABLE tmpLastestRobotClassification
    (
		CustID		BIGINT,
        RobotType	TINYINT,
        ScannedDate	DATETIME
    );
    
    INSERT INTO tmpLastestRobotClassification
    SELECT CustID
		,RobotType
        ,MAX(FromDate) AS 'ScannedDate'
	FROM CTS_DataCenter.RobotClassification
	WHERE CustID = ip_CustID
	GROUP BY CustID
		,SportTypeID
		,BetTypeID
		,LiveIndicator
        ,RobotType;
        
	IF EXISTS(SELECT 1 FROM tmpLastestRobotClassification WHERE RobotType = 2) THEN
		SELECT CustID, RobotType
        FROM tmpLastestRobotClassification 
        WHERE RobotType = 2
        LIMIT 1;
	ELSEIF EXISTS(SELECT 1 FROM tmpLastestRobotClassification WHERE RobotType = 0) THEN
		SELECT CustID, RobotType
        FROM tmpLastestRobotClassification 
        WHERE RobotType = 2
        LIMIT 1;
	ELSEIF EXISTS(SELECT 1 FROM tmpLastestRobotClassification WHERE RobotType = 1) THEN
		SELECT CustID, RobotType
        FROM tmpLastestRobotClassification 
        WHERE RobotType = 1
        LIMIT 1;
	ELSE
		SELECT ip_CustID AS 'CustID'
			, -1 AS 'RobotType';
	END IF;
END$$

DELIMITER ;