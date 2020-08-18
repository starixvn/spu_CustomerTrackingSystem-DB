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
			- 20200818@Long.Luu: Get notification based on permission granted time range [Redmine ID: #138575]
        
		Param's Explanation (filtered by):
	*/
    
    DECLARE lv_UserCurrentFromNotificationID 	BIGINT;
    DECLARE lv_UserCurrentToNotificationID 		BIGINT;
    DECLARE lv_MaxNotificationID 				BIGINT;
    DECLARE lv_IsSeen 							BIT;    
    
	SET @ToScanDate						= CURRENT_DATE();
	SET @FromScanDate					= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -3 DAY));
    
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

	# Get available notification
    SELECT 	a.CTSCustID
        ,	a.UserName
        ,	a.NewAssCount AS NewAssocitionCount
        ,	a.CreatedTime AS CreatedDate
        ,	a.AccountNewAssID AS MaxNewAssociationID
        ,	CASE WHEN a.AccountNewAssID <= lv_UserCurrentFromNotificationID THEN 1 ELSE 0 END AS IsSeen
    FROM CTS_DataCenter.AssociatedAccountNewAssociation AS a
		INNER JOIN CTS_DataCenter.CTSUserPermission_History AS p ON a.CreatedTime >= p.GrantedFrom AND (a.CreatedTime <= p.GrantedTo OR p.GrantedTo IS NULL)
	WHERE a.CreatedDate > @FromScanDate AND a.CreatedDate <= @ToScanDate
		AND p.UserID = ip_UserID 
    ORDER BY CreatedDate DESC;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$
DELIMITER ;
