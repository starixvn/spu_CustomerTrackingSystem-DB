/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RobotClassification_Scan`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotClassification_Scan`(
	OUT op_LastID BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220210@Aries.Nguyen
		Task :		Re-arrange customer category/class for good/bad robot
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220210@Aries.Nguyen: Re-arrange customer category/class for good/bad robot [Redmine ID: #167726]
            
		Param's Explanation (filtered by):
		Example:
	*/
	DECLARE	CONST_CategoryID_Robot		INT DEFAULT 61;
	DECLARE	CONST_CategoryID_BadRobot 	INT DEFAULT 163;
	DECLARE	CONST_CategoryID_GoodRobot 	INT DEFAULT 164;
    
    DECLARE lv_BatchSize 		INT;
    DECLARE lv_LastID 			BIGINT UNSIGNED;

    SELECT ParameterValue
    INTO lv_LastID
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 69;
    
    SELECT ParameterValue
    INTO lv_BatchSize
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 70;
    
	SET @lv_ID = 0;
    
    SELECT  CustID
		,	ReasonID
	FROM (SELECT 	@lv_ID := rb.ID AS ID
				,	rb.CustID
				,	CASE WHEN rb.RobotType = 0  THEN CONST_CategoryID_Robot
						 WHEN rb.RobotType = 1  THEN CONST_CategoryID_GoodRobot
						 WHEN rb.RobotType = 2  THEN CONST_CategoryID_BadRobot
					END AS ReasonID
			FROM CTS_DataCenter.RobotClassification AS rb
			WHERE rb.ID > lv_LastID
			ORDER BY rb.ID ASC
			LIMIT lv_BatchSize) AS tbl;
	
    SET op_LastID =   @lv_ID;          
END$$
DELIMITER ;