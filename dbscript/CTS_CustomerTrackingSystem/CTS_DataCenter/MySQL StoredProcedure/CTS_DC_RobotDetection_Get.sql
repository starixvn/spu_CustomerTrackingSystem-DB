/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_RobotDetection_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_RobotDetection_Get`(
		IN 	ip_CustID	 			BIGINT UNSIGNED
    
    ,	OUT op_FirstRobotDate		TIMESTAMP(3)
    ,	OUT op_LastRobotDate		TIMESTAMP(3)    
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221027@Long.Luu
		Task:		Get SCE Robot Detection Detailed Info [Redmine ID: #179498]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20221027@Long.Luu: 		Created [Redmine ID: #179498]
			- 20221027@Long.Luu: 		Support SCE Robots [Redmine ID: #179498]
			- 20230315@Victoria.Le:		Add Robot Imperva [Redmine ID: #184773]
            
		Example:
			call CTS_DataCenter.CTS_DC_RobotDetection_Get (123,@a,@b);  select @a,@b;
	*/    
	
	SELECT 	MIN(CreatedDate), MAX(LastModifiedDate)
    INTO op_FirstRobotDate, op_LastRobotDate
    FROM RobotDetection
    WHERE CustID = ip_CustID;
    
    SELECT 	CustID
		,	PeriodRangeType
		,	CASE 
				WHEN PeriodRangeType = 1 THEN 'Tickets with Time Interval <= 1s'
				WHEN PeriodRangeType = 3 THEN 'Tickets with 1s < Time Interval < 10s'
				WHEN PeriodRangeType = 5 THEN 'Tickets with 10s <= Time Interval < 20s'
				WHEN PeriodRangeType = 10 THEN 'Tickets with Time Interval >= 45s'
				WHEN PeriodRangeType = 20 THEN 'Unconsecutive Tickets with Time Deviation < 2s'
				WHEN PeriodRangeType = 40 THEN 'Consecutive Tickets with Time Deviation < 2s'                
				WHEN PeriodRangeType = 100 THEN 'More than 5/30 Days with Consecutive Tickets > 24 hours'
				WHEN PeriodRangeType = 101 THEN 'Consecutive Tickets > 24 Hours and High Ugly Stake Tickets'
			END AS PeriodRangeName
    FROM RobotDetection
    WHERE CustID = ip_CustID;
	
	SELECT 	CustID
		,	CreateTime
		,	Platform
	FROM RobotImperva
	WHERE CustID = ip_CustID;
    
END$$	
DELIMITER ;