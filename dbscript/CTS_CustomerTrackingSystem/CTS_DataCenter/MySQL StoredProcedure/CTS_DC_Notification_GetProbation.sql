/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_Notification_GetProbation`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Notification_GetProbation`(IN ip_UserID int,IN ip_ReadNotificationID bigint)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200922@Harvey.Nguyen
		Task:		Get probation customer for notification [Redmine ID: #142094]
		DB:			CTS_DataCenter
		Original:

		Revisions:
            - [20201006@Long.Luu][142414]: Get notifications by notification settings
            - [20201111@Irena.Vo][145028]: Enhance logic for display 1 scan time/day
            
		Param's Explanation (filtered by):
        
        call CTS_DC_Notification_GetProbation(8,1);
	*/
    
    DECLARE lv_UserCurrentFromNotificationID 	BIGINT;
    DECLARE lv_UserCurrentToNotificationID 		BIGINT;
    DECLARE lv_MaxNotificationID 				BIGINT;
    
	SET @ToScanDate						= CURRENT_DATE();
	SET @FromScanDate					= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -3 DAY));
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT MAX(a.NotificationID)
    INTO lv_MaxNotificationID
    FROM CTS_DataCenter.ProbationAccountNotification AS a;    
    
	SELECT notiParam.FromNotificationID, notiParam.ToNotificationID
	INTO lv_UserCurrentFromNotificationID, lv_UserCurrentToNotificationID
	FROM CTS_DataCenter.CTSUserNotificationParameter AS notiParam
	WHERE notiParam.UserID = ip_UserID AND notiParam.FunctionID = 2;

    IF (ip_ReadNotificationID <> 0) THEN		
		SET 	lv_UserCurrentFromNotificationID = lv_UserCurrentToNotificationID
			,	lv_UserCurrentToNotificationID = ip_ReadNotificationID;

		UPDATE CTS_DataCenter.CTSUserNotificationParameter
		SET 	FromNotificationID = lv_UserCurrentFromNotificationID
			,	ToNotificationID = lv_UserCurrentToNotificationID
		WHERE UserID = ip_UserID AND FunctionID = 2;
	END IF;

    IF NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSUserNotificationParameter WHERE UserID = ip_UserID AND FunctionID = 2) THEN
		BEGIN
			INSERT INTO CTS_DataCenter.CTSUserNotificationParameter(UserID, FunctionID, FromNotificationID, ToNotificationID)
			VALUES(ip_UserID, 2,  (lv_MaxNotificationID + 1), lv_MaxNotificationID);
		END;
    END IF;
    
    # Get available notification
    SELECT 	SUM(a.TotalScanned) AS TotalScanned
		,	SUM(a.TotalFailed) AS TotalFailed
        ,	SUM(a.TotalGeneralFailed) AS TotalGeneralFailed
        ,	1 AS NotificationType
        ,	a.CreatedDate
        ,	MAX(a.NotificationID) AS MaxNotificationID
        ,	CASE WHEN MAX(a.NotificationID) <= lv_UserCurrentFromNotificationID THEN 1 ELSE 0 END AS IsSeen
    FROM CTS_DataCenter.ProbationAccountNotification AS a
		INNER JOIN CTS_DataCenter.CTSUserPermission AS p ON p.FunctionID = 2
			AND a.CreatedDate >= DATE(p.GrantedFrom) 
            AND (a.CreatedDate <= DATE(p.GrantedTo) OR p.GrantedTo IS NULL)
		INNER JOIN CTS_DataCenter.NotificationSettings AS s ON s.FunctionID = 2 AND p.UserID = s.UserID
			AND a.CreatedDate >= DATE(s.GrantedFrom) 
            AND (a.CreatedDate <= DATE(s.GrantedTo) OR s.GrantedTo IS NULL)
	WHERE a.CreatedDate > @FromScanDate AND a.CreatedDate <= @ToScanDate
		AND p.UserID = ip_UserID 
    ORDER BY CreatedDate DESC;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
END$$

DELIMITER ;