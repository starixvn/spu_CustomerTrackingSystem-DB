
DROP PROCEDURE IF EXISTS `SPU_AIML_OCRD_GetMatchByCust`;

DELIMITER $$
CREATE DEFINER=`AIMLOwner`@`%` PROCEDURE `SPU_AIML_OCRD_GetMatchByCust`(
		IN 	ip_CustID	BIGINT    
)
    SQL SECURITY INVOKER
BEGIN  
	/*  
		Created:	20230404@Casey.Huynh
		Task:		GET OCRD Match of Customer
		DB:			CTS_DataCenter
        
		Revisions:
			- 20230404@Casey.Huynh: Created [Redmine ID: #185777]

		Param's Explanation (filtered by): 
        
        Example:
			CALL SPU_AIML_OCRD_GetMatchByCust(@ip_CustID:=2211693);
	*/   
    DECLARE CONST_PERIODRANGETYPE_OCRD INT DEFAULT 200;
    
    SELECT	rs.MatchID
		, 	LENGTH(TRIM(rs.SuspiciousTransList)) - LENGTH(REPLACE(TRIM(rs.SuspiciousTransList),',','')) + 1 AS TotalTickets
    FROM SPU_AIML.RD_RobotUsers AS rs
    WHERE rs.CustID = ip_CustID
		AND rs.PeriodRangeType = CONST_PERIODRANGETYPE_OCRD;
END$$

DELIMITER ;
