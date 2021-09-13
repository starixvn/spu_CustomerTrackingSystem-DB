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
            
		Explanation:
			- RobotType: 2-Bad | 1-Good | 0-Observed | -1-No classification | -2-Not Robot
            
        Example:
			- CALL CTS_DataCenter.CTS_DC_RobotClassification_GetRobotStatus(3698310);
	*/
    
    DECLARE CONST_ROBOTTYPE_BAD 		INT DEFAULT 2;
	DECLARE	CONST_ROBOTTYPE_GOOD 		INT DEFAULT 1;
	DECLARE CONST_ROBOTTYPE_OBSERVED 	INT DEFAULT 0;
    DECLARE CONST_ROBOTTYPE_NOTYPE 		INT DEFAULT -1;
    DECLARE CONST_ROBOTTYPE_NOTROBOT 	INT DEFAULT -2;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LastestRobotClassification;  
	CREATE TEMPORARY TABLE Temp_LastestRobotClassification
    (
		CustID			BIGINT,
        RobotType		TINYINT,
        ScannedDate		DATETIME
    );
    
    IF EXISTS (	SELECT 1 FROM CTSCustomerClassification 
				WHERE CustID = ip_CustID AND SportGroupID = 0 AND CategoryID IN (61, 81, 161)) THEN
		INSERT INTO Temp_LastestRobotClassification
		WITH CTE_LastestClassification
		AS (
			SELECT 	CustID
				,	SportTypeID
				,	BetTypeID
				,	LiveIndicator
				,	MAX(FromDate) AS 'ScannedDate'
			FROM CTS_DataCenter.RobotClassification
			WHERE CustID = ip_CustID
			GROUP BY CustID
				,	SportTypeID
				,	BetTypeID
				,	LiveIndicator
			)
		SELECT 	lc.CustID
			, 	rc.RobotType
			, 	lc.ScannedDate
		FROM CTE_LastestClassification AS lc
			INNER JOIN RobotClassification AS rc ON lc.CustID = rc.CustID
				AND lc.SportTypeID = rc.SportTypeID
				AND lc.BetTypeID = rc.BetTypeID
				AND lc.LiveIndicator = rc.LiveIndicator
				AND lc.ScannedDate = rc.FromDate;
			
		IF EXISTS (SELECT 1 FROM Temp_LastestRobotClassification WHERE RobotType = 2) THEN
			SELECT ip_CustID AS 'CustID', CONST_ROBOTTYPE_BAD AS 'RobotType';
		ELSEIF EXISTS (SELECT 1 FROM Temp_LastestRobotClassification WHERE RobotType = 0) THEN
			SELECT ip_CustID AS 'CustID', CONST_ROBOTTYPE_OBSERVED AS 'RobotType';
		ELSEIF EXISTS (SELECT 1 FROM Temp_LastestRobotClassification WHERE RobotType = 1) THEN
			SELECT ip_CustID AS 'CustID', CONST_ROBOTTYPE_GOOD AS 'RobotType';
		ELSE
			SELECT ip_CustID AS 'CustID', CONST_ROBOTTYPE_NOTYPE AS 'RobotType';
		END IF;
	ELSE
		SELECT DISTINCT CustID, CONST_ROBOTTYPE_NOTROBOT AS 'RobotType'
		FROM CTSCustomerClassification
		WHERE CustID = ip_CustID
			AND SportGroupID = 0
			AND CategoryID IN (61, 81, 161);		
    END IF;   
    
END$$

DELIMITER ;