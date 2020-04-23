DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetAllSportGroups`$$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_GetAllSportGroups`()
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Get all sport groups
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
            
		Param's Explanation:
	*/ 
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT SportGroupID, SportGroupName
    FROM CTS_DataCenter.SportGroup 
    WHERE IsActive = 1
    ORDER BY DisplayOrder ASC; 
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  
END$$
DELIMITER ;
