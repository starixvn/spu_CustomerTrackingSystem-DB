
DROP PROCEDURE IF EXISTS `SPU_AIML_OCRD_GetCustMatchDetails`;

DELIMITER $$
CREATE DEFINER=`AIMLOwner`@`%` PROCEDURE `SPU_AIML_OCRD_GetCustMatchDetails`(
		IN 	ip_CustID	BIGINT
	,	IN 	ip_MatchID	BIGINT
)
    SQL SECURITY INVOKER
sp:BEGIN  
	/*  
		Created:	20220404@Casey.Huynh
		Task:		GET OCRD Match of Customer
		DB:			CTS_DataCenter
        
		Revisions:
			- 20230313@Casey.Huynh: Created [Redmine ID: #184791]

		Param's Explanation (filtered by): 
        
        Example:
			CALL SPU_AIML_OCRD_GetCustMatchDetails(@ip_CustID:=933725,@ip_MatchID:=64841081);
	*/   
    DECLARE CONST_PERIODRANGETYPE_OCRD INT DEFAULT 200;
    
    SELECT	rs.MatchID
		, 	js.TransID
    FROM SPU_AIML.RD_RobotUsers AS rs
		JOIN JSON_TABLE(REPLACE(JSON_ARRAY(rs.SuspiciousTransList), ',', '","'), 
							'$[*]' COLUMNS (TransID BIGINT UNSIGNED PATH '$')
							) js
    WHERE rs.CustID = ip_CustID
		AND rs.MatchID = ip_MatchID
		AND rs.PeriodRangeType = CONST_PERIODRANGETYPE_OCRD;
END$$

DELIMITER ;
