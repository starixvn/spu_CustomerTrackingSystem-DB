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
			- 20230207@Long.Luu: Get robot classification [Redmine ID: #183281]
            - 20230517@Casey.Huynh:	New Category for Robot OCRD [Redmine ID: #186991]
            
		Explanation:
			- RobotType: 2-Bad | 1-Good | 0-Observed | -1-No classification | -2-Not Robot
            
        Example:
			- CALL CTS_DataCenter.CTS_DC_RobotClassification_GetRobotStatus(2550565);
	*/
    
    DECLARE CONST_ROBOTTYPE_BAD 			INT DEFAULT 2;
	DECLARE	CONST_ROBOTTYPE_GOOD 			INT DEFAULT 1;
    DECLARE CONST_ROBOTTYPE_NOTROBOT 		INT DEFAULT 0;
    
    DECLARE	CONST_CATEGORYID_ROBOTUSER 			INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_ROBOTUSER_LOSING	INT DEFAULT 164;
	DECLARE	CONST_CATEGORYID_ROBOTOCRD 			INT DEFAULT 165;
    DECLARE	CONST_CATEGORYID_ROBOTOCRD_LOSING	INT DEFAULT 166;    
    
    SET @IsRobot = 0;
    
    SELECT cls.CategoryID
	INTO @IsRobot
	FROM CTS_DataCenter.CTSCustomerClassification AS cls
	WHERE cls.CustID = ip_CustID
		AND CategoryID IN (CONST_CATEGORYID_ROBOTUSER, CONST_CATEGORYID_ROBOTUSER_LOSING,CONST_CATEGORYID_ROBOTOCRD,CONST_CATEGORYID_ROBOTOCRD_LOSING)
	LIMIT 1;
    
    SELECT 	ip_CustID
		, 	CASE 
				WHEN @IsRobot IN (CONST_CATEGORYID_ROBOTUSER,CONST_CATEGORYID_ROBOTOCRD) THEN CONST_ROBOTTYPE_BAD
                WHEN @IsRobot IN (CONST_CATEGORYID_ROBOTUSER_LOSING,CONST_CATEGORYID_ROBOTOCRD_LOSING) THEN CONST_ROBOTTYPE_GOOD
                ELSE CONST_ROBOTTYPE_NOTROBOT
			END AS 'RobotType';
    
END$$

DELIMITER ;