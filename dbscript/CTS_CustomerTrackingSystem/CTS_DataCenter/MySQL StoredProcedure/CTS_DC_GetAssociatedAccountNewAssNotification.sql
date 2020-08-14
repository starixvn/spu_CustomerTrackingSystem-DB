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
    
	SET @ToScanDate						= CURRENT_DATE();
	SET @FromScanDate					= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -3 DAY));

	DROP TEMPORARY TABLE IF EXISTS Temp_Union_CTSUserNotificationParameter;
    CREATE TEMPORARY TABLE Temp_Union_CTSUserNotificationParameter 
    (	
		`AccountNewAssID` BIGINT UNSIGNED,
		`GrantedFrom` DATETIME DEFAULT NULL,
		`GrantedTo` DATETIME DEFAULT NULL
    );
    
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

	INSERT INTO Temp_Union_CTSUserNotificationParameter(AccountNewAssID, GrantedFrom, GrantedTo)
		SELECT a.AccountNewAssID
			, a.GrantedFrom
			, a.GrantedTo
		FROM (
            SELECT ass.AccountNewAssID, his.GrantedFrom, his.GrantedTo
				FROM CTS_DataCenter.CTSUserPermission_History his
					INNER JOIN CTS_DataCenter.AssociatedAccountNewAssociation ass ON  his.GrantedFrom <= ass.CreatedTime AND his.GrantedTo >= ass.CreatedTime
				WHERE his.UserID = ip_UserID AND his.Type = "AssociatedAccountMonitor"
				Union
				SELECT ass.AccountNewAssID, his.GrantedFrom, his.GrantedTo
				FROM CTS_DataCenter.CTSUserPermission_History his
					INNER JOIN CTS_DataCenter.AssociatedAccountNewAssociation ass ON  his.GrantedFrom <= ass.CreatedTime AND his.GrantedTo is null
				WHERE his.UserID = ip_UserID AND his.Type = "AssociatedAccountMonitor"
            ) as a;
            
     SELECT ass.CTSCustID
        ,	ass.UserName
        ,	ass.NewAssCount AS NewAssocitionCount
        ,	ass.CreatedTime AS CreatedDate
        ,	ass.AccountNewAssID AS MaxNewAssociationID
        ,	CASE WHEN ass.AccountNewAssID <= lv_UserCurrentFromNotificationID THEN 1 ELSE 0 END AS IsSeen
     FROM Temp_Union_CTSUserNotificationParameter tmp 
     INNER JOIN CTS_DataCenter.AssociatedAccountNewAssociation ass ON tmp.AccountNewAssID = ass.AccountNewAssID
     WHERE ass.CreatedDate > @FromScanDate AND ass.CreatedDate <= @ToScanDate
     ORDER BY ass.CreatedDate DESC;
    
	/*
    SELECT 	a.CTSCustID
        ,	a.UserName
        ,	a.NewAssCount AS NewAssocitionCount
        ,	a.CreatedTime AS CreatedDate
        ,	a.AccountNewAssID AS MaxNewAssociationID
        ,	CASE WHEN a.AccountNewAssID <= lv_UserCurrentFromNotificationID THEN 1 ELSE 0 END AS IsSeen
    FROM CTS_DataCenter.AssociatedAccountNewAssociation AS a
	WHERE a.CreatedDate > @FromScanDate AND a.CreatedDate <= @ToScanDate
    ORDER BY CreatedDate DESC;  */   
    
    /*
    SELECT 	a.CTSCustID
        ,	a.UserName
        ,	SUM(a.NewAssCount) AS NewAssocitionCount
        ,	MAX(a.CreatedTime) AS CreatedDate
        ,	MAX(a.AccountNewAssID) AS MaxNewAssociationID
        ,	lv_IsSeen AS IsSeen
    FROM CTS_DataCenter.AssociatedAccountNewAssociation AS a
	WHERE a.AccountNewAssID > lv_UserCurrentFromNotificationID AND a.AccountNewAssID <= lv_UserCurrentToNotificationID
    GROUP BY a.CTSCustID
        ,	a.UserName;*/        
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$
DELIMITER ;
