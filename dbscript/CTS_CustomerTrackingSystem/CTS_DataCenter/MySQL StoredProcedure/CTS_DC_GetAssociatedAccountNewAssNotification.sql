DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetAssociatedAccountNewAssNotification` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_GetAssociatedAccountNewAssNotification`(
		IN 	ip_UserID 			INT UNSIGNED
    ,	IN 	ip_MaxNewAssID 		BIGINT
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
    
    DECLARE lv_UserCurrentFromNotificationID 	BIGINT;
    DECLARE lv_UserCurrentToNotificationID 		BIGINT;
    DECLARE lv_MaxNotificationID 				BIGINT;
    DECLARE lv_IsSeen 							BIT;
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT MAX(a.AccountNewAssID)
    INTO lv_MaxNotificationID
    FROM CTS_DataCenter.AssociatedAccountNewAssociation AS a;    
    
	SELECT u.FromNewAssID, u.ToNewAssID
	INTO lv_UserCurrentFromNotificationID, lv_UserCurrentToNotificationID
	FROM CTS_DataCenter.CTSUserNotificationParameter AS u
	WHERE u.UserID = ip_UserID;
            
    IF (ip_MaxNewAssID <> 0) THEN		
		SET 	lv_UserCurrentFromNotificationID = lv_UserCurrentToNotificationID
			,	lv_UserCurrentToNotificationID = lv_MaxNotificationID
			,	lv_IsSeen = 1;
                        
		UPDATE CTS_DataCenter.CTSUserNotificationParameter
		SET 	FromNewAssID = lv_UserCurrentFromNotificationID
			,	ToNewAssID = lv_UserCurrentToNotificationID
		WHERE UserID = ip_UserID;        
	END IF;
    
    IF EXISTS (SELECT 1 FROM CTS_DataCenter.CTSUserNotificationParameter WHERE UserID = ip_UserID) THEN
		BEGIN             
            IF (lv_MaxNotificationID = lv_UserCurrentToNotificationID) THEN
				BEGIN
					SET 	lv_IsSeen = 1;
				END;
			ELSE
				BEGIN
					SET 	lv_UserCurrentFromNotificationID = lv_UserCurrentToNotificationID
						,	lv_UserCurrentToNotificationID = lv_MaxNotificationID
						,	lv_IsSeen = 0;
				END;
			END IF;
		END;
    ELSE
		BEGIN
			SET 	lv_UserCurrentFromNotificationID = (lv_MaxNotificationID + 1)
				,	lv_UserCurrentToNotificationID = lv_MaxNotificationID
                ,	lv_IsSeen = 0;
			
			INSERT INTO CTS_DataCenter.CTSUserNotificationParameter(UserID,FromNewAssID,ToNewAssID)
			VALUES(ip_UserID, lv_UserCurrentFromNotificationID, lv_UserCurrentToNotificationID);
		END;
    END IF;
    
    SELECT 	a.CTSCustID
        ,	a.UserName
        ,	SUM(a.NewAssCount) AS NewAssocitionCount
        ,	MAX(a.CreatedTime) AS CreatedDate
        ,	MAX(a.AccountNewAssID) AS MaxNewAssociationID
        ,	lv_IsSeen AS IsSeen
    FROM CTS_DataCenter.AssociatedAccountNewAssociation AS a
	WHERE a.AccountNewAssID > lv_UserCurrentFromNotificationID AND a.AccountNewAssID <= lv_UserCurrentToNotificationID
    GROUP BY a.CTSCustID
        ,	a.UserName;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$
DELIMITER ;
