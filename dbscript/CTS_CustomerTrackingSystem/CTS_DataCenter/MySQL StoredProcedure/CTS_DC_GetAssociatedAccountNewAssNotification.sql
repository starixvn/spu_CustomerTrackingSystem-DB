DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetAssociatedAccountNewAssNotification` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_GetAssociatedAccountNewAssNotification`(
	IN 	ip_UserID 		INT UNSIGNED
)
BEGIN
	/*
		Created:	20200706@Long.Luu
		Task:		Insert Associated Account Monitor [Redmine ID: #134652]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200706@Long.Luu: Created [Redmine ID: #134652]
        
		Param's Explanation (filtered by):
	*/
    
    DECLARE lv_UserLastNotificationID 	BIGINT;
    DECLARE lv_UserMaxNotificationID 	BIGINT;
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    IF EXISTS (SELECT 1 FROM CTS_DataCenter.CTSUserNotificationParameter WHERE UserID = ip_UserID) THEN
		BEGIN 
			SELECT u.AccountNewAssID
            INTO lv_UserLastNotificationID
			FROM CTS_DataCenter.CTSUserNotificationParameter AS u
			WHERE u.UserID = ip_UserID;
		END;
    ELSE
		BEGIN
			SET lv_UserLastNotificationID = 0;
			
			INSERT INTO CTS_DataCenter.CTSUserNotificationParameter(UserID, AccountNewAssID)
			VALUES(ip_UserID, lv_UserLastNotificationID);
		END;
    END IF;
    
    SELECT MAX(a.AccountNewAssID)
    INTO lv_UserMaxNotificationID
    FROM CTS_DataCenter.AssociatedAccountNewAssociation AS a;
    
    SELECT 	a.CTSCustID
        ,	a.UserName
        ,	SUM(a.NewAssCount) AS NewAssocitionCount
    FROM CTS_DataCenter.AssociatedAccountNewAssociation AS a
	WHERE a.AccountNewAssID > lv_UserLastNotificationID
    GROUP BY a.CTSCustID
        ,	a.UserName;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    UPDATE CTS_DataCenter.CTSUserNotificationParameter
    SET AccountNewAssID = lv_UserMaxNotificationID
    WHERE UserID = ip_UserID;
    
END$$
DELIMITER ;
