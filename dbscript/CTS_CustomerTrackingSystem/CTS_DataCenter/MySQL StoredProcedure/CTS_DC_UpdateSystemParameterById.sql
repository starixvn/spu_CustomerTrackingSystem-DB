DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_UpdateSystemParameterById` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_UpdateSystemParameterById`(	
		IN ip_ParamID			SMALLINT UNSIGNED
    ,   IN ip_ParamValue		VARCHAR(50)
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
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
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    SET SQL_SAFE_UPDATES = 0;
    
    UPDATE CTS_DataCenter.SystemParameter AS s
	SET s.ParameterValue = ip_ParamValue
    WHERE s.ParameterID = ip_ParamID;
    
END$$
DELIMITER ;
