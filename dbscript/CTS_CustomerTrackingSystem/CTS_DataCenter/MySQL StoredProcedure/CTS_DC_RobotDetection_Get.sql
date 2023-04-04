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
            - 20230404@Casey.Huynh:		Return RobotDetection.PeriodRangeName for PeriodRangeType = 200 [Redmine ID: #185777]
		Example:
			call CTS_DataCenter.CTS_DC_RobotDetection_Get (2211693,@a,@b);  select @a,@b;
	*/    
	
	SELECT 	MIN(rd.CreatedDate), MAX(rd.LastModifiedDate)
    INTO op_FirstRobotDate, op_LastRobotDate
    FROM CTS_DataCenter.RobotDetection AS rd
    WHERE rd.CustID = ip_CustID;
    
    SELECT 	rd.CustID
		,	rd.PeriodRangeType
		,	CASE 
				WHEN rd.PeriodRangeType = 1 THEN 'Tickets with Time Interval <= 1s'
				WHEN rd.PeriodRangeType = 3 THEN 'Tickets with 1s < Time Interval < 10s'
				WHEN rd.PeriodRangeType = 5 THEN 'Tickets with 10s <= Time Interval < 20s'
				WHEN rd.PeriodRangeType = 10 THEN 'Tickets with Time Interval >= 45s'
				WHEN rd.PeriodRangeType = 20 THEN 'Unconsecutive Tickets with Time Deviation < 2s'
				WHEN rd.PeriodRangeType = 40 THEN 'Consecutive Tickets with Time Deviation < 2s'                
				WHEN rd.PeriodRangeType = 100 THEN 'More than 5/30 Days with Consecutive Tickets > 24 hours'
				WHEN rd.PeriodRangeType = 101 THEN 'Consecutive Tickets > 24 Hours and High Ugly Stake Tickets'
                WHEN rd.PeriodRangeType = 200 THEN 'Consecutive Tickets per Match <= 2 mins and Stake per Ticket < 30 RM'
			END AS PeriodRangeName
    FROM CTS_DataCenter.RobotDetection AS rd
    WHERE rd.CustID = ip_CustID;
	
	SELECT 	ri.CustID
		,	ri.CreateTime
		,	ri.Platform
	FROM CTS_DataCenter.RobotImperva AS ri
	WHERE ri.CustID = ip_CustID;
    
END$$	
DELIMITER ;