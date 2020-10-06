DELIMITER $$
USE `CTS_DataCenter`$$
DROP PROCEDURE IF EXISTS `CTS_DC_Notification_GetSettings`;

CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_Notification_GetSettings`(
		IN 	ip_UserID 			INT UNSIGNED
)
BEGIN
	/*
		Created:	2020106@Long.Luu
		Task:		Get Notification Settings (On/Off) [Redmine ID: #142414]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 2020106@Long.Luu: Created [Redmine ID: #142414]
        
		Param's Explanation (filtered by):
        
			call CTS_DC_Notification_GetNewAssociation(8,1);
	*/
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT DISTINCT p.FunctionID, p.FunctionName, p.IsTurnedOnNotification
    FROM CTS_DataCenter.CTSUserPermission AS p
    WHERE p.UserID = ip_UserID
		AND p.GrantedTo IS NULL;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;