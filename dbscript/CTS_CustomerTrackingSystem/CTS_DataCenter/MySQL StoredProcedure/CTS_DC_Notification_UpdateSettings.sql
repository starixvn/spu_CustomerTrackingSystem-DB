DELIMITER $$
USE `CTS_DataCenter`$$
DROP PROCEDURE IF EXISTS `CTS_DC_Notification_UpdateSettings`;

CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_Notification_UpdateSettings`(
		IN 	ip_UserID 			INT UNSIGNED
    ,	IN 	ip_FunctionID 		SMALLINT UNSIGNED
    ,	IN 	ip_IsTurningOn		BIT
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
BEGIN
	/*
		Created:	2020106@Long.Luu
		Task:		Update Notification Settings (On/Off) [Redmine ID: #142414]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 2020106@Long.Luu: Created [Redmine ID: #142414]
        
		Param's Explanation (filtered by):
        
			call CTS_DC_Notification_GetNewAssociation(8,1);
	*/
    
    DECLARE lv_CurrentDateTime	 	DATETIME;  
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
      
	SET lv_CurrentDateTime			= CURRENT_TIME();    
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
            
    IF (ip_IsTurningOn = 0) THEN		
		UPDATE CTS_DataCenter.NotificationSettings
		SET 	GrantedTo = lv_CurrentDateTime
			,	LastModifiedDate = lv_CurrentDateTime
		WHERE UserID = ip_UserID 
			AND FunctionID = ip_FunctionID
            AND GrantedTo IS NULL;
		
        UPDATE CTS_DataCenter.CTSUserPermission
		SET IsTurnedOnNotification = 0
		WHERE UserID = ip_UserID 
			AND FunctionID = ip_FunctionID;
	ELSE
		INSERT INTO NotificationSettings(UserID, FunctionID, FunctionName, GrantedFrom, CreatedDate, LastModifiedDate)
		SELECT 	ip_UserID
			, 	ip_FunctionID
            , 	CASE WHEN ip_FunctionID = 1 THEN 'AssociatedAccountMonitor' ELSE 'ProbationManagement' END
            , 	lv_CurrentDateTime
            , 	lv_CurrentDateTime
            , 	lv_CurrentDateTime;

		UPDATE CTS_DataCenter.CTSUserPermission
		SET IsTurnedOnNotification = 1
		WHERE UserID = ip_UserID 
			AND FunctionID = ip_FunctionID;
	END IF;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;