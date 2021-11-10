DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_RobotDetection_Get`$$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotDetection_Get`(
	IN 	ip_CustID	 			BIGINT UNSIGNED,
    
    OUT op_FirstRobotDate		DATETIME,
    OUT op_LastRobotDate		DATETIME
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20211109@Long.Luu
		Task:		Get Robot Detection [Redmine ID: #162341]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20211109@Long.Luu: Created [Redmine ID: #162341]
            
		Example:
			call CTS_DataCenter.CTS_DC_RobotDetection_Get (123);    
	*/    
    
    SELECT 	MIN(CreatedDate), MAX(LastModifiedDate)
    INTO op_FirstRobotDate, op_LastRobotDate
    FROM RobotDetection
    WHERE CustID = ip_CustID;
    
    SELECT 	CustID
		,	PeriodRangeType
		,	CASE 
				WHEN PeriodRangeType = 1 THEN 'Bet Tickets with Time Interval =< 1s'
				WHEN PeriodRangeType = 3 THEN 'Bet Tickets with 1s < Time Interval < 10s'
				WHEN PeriodRangeType = 5 THEN 'Bet Tickets with 10s =< Time Interval < 20s'
				WHEN PeriodRangeType = 10 THEN 'Bet Tickets with Time Interval >= 45s'
				WHEN PeriodRangeType = 20 THEN 'Unconsecutive Bet Tickets with Time Deviation < 2s'
				WHEN PeriodRangeType = 40 THEN 'Consecutive Bet Tickets with Time Deviation <2'
			END AS PeriodRangeName
    FROM RobotDetection
    WHERE CustID = ip_CustID;
    
END$$	
DELIMITER ;