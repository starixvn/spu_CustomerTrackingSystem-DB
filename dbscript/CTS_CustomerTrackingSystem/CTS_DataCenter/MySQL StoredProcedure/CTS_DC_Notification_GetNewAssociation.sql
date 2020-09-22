USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_Notification_GetNewAssociation`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_Notification_GetNewAssociation`(
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
        
			call CTS_DC_Notification_GetNewAssociation(8,1);
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
    FROM CTS_DataCenter.AssociatedAccountNotification AS a;    

	SELECT u.FromNotificationID, u.ToNotificationID
	INTO lv_UserCurrentFromNotificationID, lv_UserCurrentToNotificationID
	FROM CTS_DataCenter.CTSUserNotificationParameter AS u
	WHERE u.UserID = ip_UserID AND u.FunctionID = 1;
            
    IF (ip_MaxNewAssID <> 0) THEN		
		UPDATE CTS_DataCenter.CTSUserNotificationParameter
		SET 	FromNotificationID = lv_UserCurrentToNotificationID
			,	ToNotificationID = lv_MaxNotificationID
		WHERE UserID = ip_UserID AND u.FunctionID = 1;        
	END IF;
    
    IF NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSUserNotificationParameter WHERE UserID = ip_UserID AND FunctionID = 1) THEN    
		BEGIN
			INSERT INTO CTS_DataCenter.CTSUserNotificationParameter(UserID, FunctionID, FromNotificationID, ToNotificationID)
			VALUES(ip_UserID, 1, (lv_MaxNotificationID + 1), lv_MaxNotificationID);
		END;
    END IF;

	# Get available notification
    SELECT 	a.CTSCustID
        ,	a.UserName
        ,	a.NewAssCount AS NewAssocitionCount
        ,	a.CreatedTime AS CreatedDate
        ,	a.AccountNewAssID AS MaxNewAssociationID
        ,	CASE WHEN a.AccountNewAssID <= lv_UserCurrentFromNotificationID THEN 1 ELSE 0 END AS IsSeen
    FROM CTS_DataCenter.AssociatedAccountNotification AS a
		INNER JOIN CTS_DataCenter.CTSUserPermission AS p ON a.CreatedTime >= p.GrantedFrom AND (a.CreatedTime <= p.GrantedTo OR p.GrantedTo IS NULL)
	WHERE a.CreatedDate > @FromScanDate AND a.CreatedDate <= @ToScanDate
		AND p.UserID = ip_UserID 
    ORDER BY CreatedDate DESC;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;