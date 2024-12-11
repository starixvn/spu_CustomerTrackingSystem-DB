
DROP PROCEDURE IF EXISTS `SPU_AIML_RD_LP_GetRobotDetails`;

DELIMITER $$
CREATE DEFINER=`AIMLOwner`@`%` PROCEDURE `SPU_AIML_RD_LP_GetRobotDetails`(
			IN 	ip_CustID				BIGINT   
        ,	IN	ip_PeriodRangeType		SMALLINT
)
    SQL SECURITY INVOKER
BEGIN  
	/*  
		Created:	20241211@Casey.Huynh
		Task:		Get Bot Login Pattern Details
		DB:			SPU_AIML
        
		Revisions:
			- 20241211@Casey.Huynh: Created [Redmine ID: #214655]

		Param's Explanation (filtered by): 
        
        Example:
			CALL SPU_AIML.SPU_AIML_RD_LP_GetRobotDetails(@ip_CustID:=2211693, 100);
	*/   
    DECLARE CONST_PERIODRANGETYPE_OCRD INT DEFAULT 200;
    
    DECLARE	CONST_PERIODRANGETYPE_LP_LOGINTIMEPATTERN		INT DEFAULT 400;
    DECLARE	CONST_PERIODRANGETYPE_LP_MASSIVELOGINATTEMPT	INT DEFAULT 420;
    DECLARE	CONST_PERIODRANGETYPE_LP_IPDEVERSITY			INT DEFAULT 430;    
    DECLARE	CONST_PERIODRANGETYPE_LP_DEVICEDEVERSITY		INT DEFAULT 440;
    
	SELECT	bl.TransTime
		,	bl.DeviceID
        ,	bl.RobotTracking
        ,	bl.DeviceType
        ,	bl.BrowserName
        ,	bl.IP
        ,	bl.Domain
    FROM SPU_AIML.LIC_BDLB_SuspiciousTransInfo AS bl
    WHERE	bl.CustID = ip_CustID
		AND bl.BehaviorID = ip_PeriodRangeType;
    
END$$

DELIMITER ;
