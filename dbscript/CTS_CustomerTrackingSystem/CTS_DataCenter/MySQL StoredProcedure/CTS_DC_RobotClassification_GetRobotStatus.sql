/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RobotClassification_GetRobotStatus`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotClassification_GetRobotStatus`(
		IN ip_CustID 			BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210818@Harvey.Nguyen
		Task:		Get lastest robot classification
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210818@Harvey.Nguyen: Created [Redmine ID: #160382]
			- 20210907@Long.Luu: Update Robot Users rules  [Redmine ID: #161232]            
			- 20220211@Long.Luu: Remove detailed robot classification  [Redmine ID: #167726]
			- 20220603@Long.Luu: Merge Robot AI & Robot TW [Redmine ID: #172561]
            
		Explanation:
			- RobotType: 2-Bad | 1-Good | 0-Observed | -1-No classification | -2-Not Robot
            
        Example:
			- CALL CTS_DataCenter.CTS_DC_RobotClassification_GetRobotStatus(3698310);
	*/
    
    DECLARE CONST_ROBOTTYPE_BAD 			INT DEFAULT 2;
	DECLARE	CONST_ROBOTTYPE_GOOD 			INT DEFAULT 1;
	DECLARE CONST_ROBOTTYPE_OBSERVED 		INT DEFAULT 0;
    DECLARE CONST_ROBOTTYPE_NOTYPE 			INT DEFAULT -1;
    DECLARE CONST_ROBOTTYPE_NOTROBOT 		INT DEFAULT -2;
        
    DECLARE	CONST_CATEGORYGROUP_ROBOT 		INT DEFAULT 61;
    DECLARE	CONST_CATEGORYGROUP_BADROBOT 	INT DEFAULT 163;
    DECLARE	CONST_CATEGORYGROUP_GOODROBOT	INT DEFAULT 164;
    
    SET @LatestRobotType = -1;
    SET @IsRobot = EXISTS(
							SELECT 1 
                            FROM CTSCustomerClassification 
                            WHERE CustID = ip_CustID
								AND CategoryID IN (CONST_CATEGORYGROUP_ROBOT, 81, 161, CONST_CATEGORYGROUP_BADROBOT, CONST_CATEGORYGROUP_GOODROBOT)
					);
                    
	SELECT RobotType
    INTO @LatestRobotType
    FROM RobotClassification
	WHERE CustID = ip_CustID
    ORDER BY FromDate DESC
    LIMIT 1;
    
    SELECT 	ip_CustID
		, 	CASE 
				WHEN @LatestRobotType IN (CONST_ROBOTTYPE_BAD,CONST_ROBOTTYPE_GOOD,CONST_ROBOTTYPE_OBSERVED) THEN @LatestRobotType
                WHEN @IsRobot = 1 THEN CONST_ROBOTTYPE_NOTYPE
                ELSE CONST_ROBOTTYPE_NOTROBOT
			END AS 'RobotType';
    
END$$

DELIMITER ;