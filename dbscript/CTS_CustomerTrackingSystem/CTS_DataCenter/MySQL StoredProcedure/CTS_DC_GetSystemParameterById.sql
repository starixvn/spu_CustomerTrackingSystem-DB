DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetSystemParameterByID` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_GetSystemParameterByID`(
	IN ip_ParamID 	SMALLINT UNSIGNED
)
BEGIN
	/*
		Created:	20200728@Long.Luu	
		Task :		Get System Parameter by ID
		DB:			CTS_DataCenter
		Original: SystemParameter
		Revisions:
			- 20200728@Long.Luu: Created [Redmine ID: #136652]
            
		Param's Explanation:
	*/ 
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT 	s.ParameterValue
		,	s.ParameterDataType
    FROM CTS_DataCenter.SystemParameter AS s
    WHERE s.ParameterID = ip_ParamID; 
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
    
END$$
DELIMITER ;
