/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_ArchiveData_MBLastAccessedDate_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_ArchiveData_MBLastAccessedDate_Update`(
  IN ip_BatchSize INT
)
    SQL SECURITY INVOKER
BEGIN
    /*
      Created: 20241204@Jonathan.Doan
      Task : Update LastAccessedDate
      DB: DCS_DataCenter
      Original:

      Revisions:
        - 20241204@Jonathan.Doan: Created [Redmine ID: #213401]
        - 20250514@Jonathan.Doan: Update field value LastLoginTime [Redmine ID: #221973]
      Param's Explanation (filtered by):
    Example:
      CALL DCS_DC_ArchiveData_MBLastAccessedDate_Update(100);
    */
    
    DECLARE CONST_SYSTEMSETTING_MAXMBTRANSACTION07ID  	INT DEFAULT 30;
    
    DECLARE lv_MaxID				BIGINT UNSIGNED;
    DECLARE lv_CurrentDatetime 		DATETIME DEFAULT NOW();
    
    SELECT VValue
    INTO lv_MaxID
    FROM DCS_DataCenter.SystemSetting
    WHERE ID = CONST_SYSTEMSETTING_MAXMBTRANSACTION07ID;
    
    
    /*******INIT TEMPORARY TABLE************/
	DROP TEMPORARY TABLE IF EXISTS Temp_MBTransaction07;
	CREATE TEMPORARY TABLE Temp_MBTransaction07(
		  ID            			BIGINT UNSIGNED PRIMARY KEY
		, MBAccountID       		BIGINT UNSIGNED
		, CreatedDate       		DATE
		, TransTime       			DATETIME(4)
		, MBDeviceCodeMediaDRMID  	BIGINT UNSIGNED
		, MBDeviceCodeMachineID 	BIGINT UNSIGNED
		, MBDeviceCodeTaggingID 	BIGINT UNSIGNED
		, MBDeviceModelID     		BIGINT UNSIGNED
		, MBOSID          			BIGINT UNSIGNED
		, MBUserSettingID     		BIGINT UNSIGNED
		, MBDeviceID        		BIGINT UNSIGNED
		, MBAssociationID        	BIGINT UNSIGNED
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MBAccount;
	CREATE TEMPORARY TABLE Temp_MBAccount(
		  ID            	BIGINT UNSIGNED PRIMARY KEY
		, LastLoginTime     DATETIME(4)
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeMediaDRM;
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeMediaDRM(
		  ID            		BIGINT UNSIGNED PRIMARY KEY
		, MaxLastAccessedDate   DATE
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeMachine;
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeMachine(
		  ID            		BIGINT UNSIGNED PRIMARY KEY
		, MaxLastAccessedDate   DATE
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeTagging;
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeTagging(
		  ID            		BIGINT UNSIGNED PRIMARY KEY
		, MaxLastAccessedDate   DATE
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceModel;
	CREATE TEMPORARY TABLE Temp_MBDeviceModel(
		  ID            		BIGINT UNSIGNED PRIMARY KEY
		, MaxLastAccessedDate   DATE
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_MBOS;
	CREATE TEMPORARY TABLE Temp_MBOS(
		  ID            		BIGINT UNSIGNED PRIMARY KEY
		, MaxLastAccessedDate   DATE
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_MBUserSetting;
	CREATE TEMPORARY TABLE Temp_MBUserSetting(
		  ID            		BIGINT UNSIGNED PRIMARY KEY
		, MaxLastAccessedDate   DATE
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_MBDevice;
	CREATE TEMPORARY TABLE Temp_MBDevice(
		  ID            		BIGINT UNSIGNED PRIMARY KEY
		, MaxLastAccessedDate   DATE
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_MBAssociation;
	CREATE TEMPORARY TABLE Temp_MBAssociation(
		  ID            		BIGINT UNSIGNED PRIMARY KEY
		, MaxLastAccessedDate   DATE
	);
    
    /*******GET DATA Transaction07********************/
	INSERT INTO Temp_MBTransaction07(ID, MBAccountID, CreatedDate, TransTime, MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID, MBDeviceModelID, MBOSID, MBUserSettingID, MBDeviceID)
	SELECT  trans.ID
		,	IFNULL(trans.MBAccountID, 0) AS MBAccountID
		,	trans.CreatedDate
		,	trans.TransTime
		,	IFNULL(dm.MBDeviceCodeMediaDRMID, 0) AS MBDeviceCodeMediaDRMID
		,	IFNULL(dm.MBDeviceCodeMachineID, 0) AS MBDeviceCodeMachineID
		,	IFNULL(dm.MBDeviceCodeTaggingID, 0) AS MBDeviceCodeTaggingID
		,	IFNULL(trans.MBDeviceModelID, 0) AS MBDeviceModelID
		,	IFNULL(trans.MBOSID, 0) AS MBOSID
		,	IFNULL(trans.MBUserSettingID, 0) AS MBUserSettingID
		,	IFNULL(trans.MBDeviceID, 0) AS MBDeviceID
	FROM DCS_DataCenter.MBTransaction07 AS trans
		LEFT JOIN DCS_DataCenter.MBDeviceMapping AS dm ON dm.ID = trans.MBDeviceMappingID
	WHERE trans.ID > lv_MaxID
	LIMIT ip_BatchSize;
    
    
    /*******GET LastAccessedDate ********************/
    INSERT INTO Temp_MBAccount(ID, LastLoginTime)
    SELECT	MBAccountID AS ID
		,	MAX(TransTime) AS LastLoginTime
    FROM Temp_MBTransaction07
    WHERE MBAccountID IS NOT NULL
    GROUP BY MBAccountID;
    
    INSERT INTO Temp_MBDeviceCodeMediaDRM(ID, MaxLastAccessedDate)
    SELECT	MBDeviceCodeMediaDRMID AS ID
		,	MAX(CreatedDate) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBDeviceCodeMediaDRMID IS NOT NULL
    GROUP BY MBDeviceCodeMediaDRMID;
    
    INSERT INTO Temp_MBDeviceCodeMachine(ID, MaxLastAccessedDate)
    SELECT	MBDeviceCodeMachineID AS ID
		,	MAX(CreatedDate) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBDeviceCodeMachineID IS NOT NULL
    GROUP BY MBDeviceCodeMachineID;
    
    INSERT INTO Temp_MBDeviceCodeTagging(ID, MaxLastAccessedDate)
    SELECT	MBDeviceCodeTaggingID AS ID
		,	MAX(CreatedDate) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBDeviceCodeTaggingID IS NOT NULL
    GROUP BY MBDeviceCodeTaggingID;
    
    INSERT INTO Temp_MBDeviceModel(ID, MaxLastAccessedDate)
    SELECT	MBDeviceModelID AS ID
		,	MAX(CreatedDate) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBDeviceModelID IS NOT NULL
    GROUP BY MBDeviceModelID;
    
    INSERT INTO Temp_MBOS(ID, MaxLastAccessedDate)
    SELECT	MBOSID AS ID
		,	MAX(CreatedDate) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBOSID IS NOT NULL
    GROUP BY MBOSID;
    
    INSERT INTO Temp_MBUserSetting(ID, MaxLastAccessedDate)
    SELECT	MBUserSettingID AS ID
		,	MAX(CreatedDate) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBUserSettingID IS NOT NULL
    GROUP BY MBUserSettingID;
    
    INSERT INTO Temp_MBDevice(ID, MaxLastAccessedDate)
    SELECT	MBDeviceID AS ID
		,	MAX(CreatedDate) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBDeviceID IS NOT NULL
    GROUP BY MBDeviceID;
    

	UPDATE Temp_MBTransaction07 AS tmp
		INNER JOIN DCS_DataCenter.MBAssociation AS ass ON ass.MBAccountID = tmp.MBAccountID
													AND ass.MBDeviceID = tmp.MBDeviceID
	SET tmp.MBAssociationID = ass.MBAssociationID;

    INSERT INTO Temp_MBAssociation(ID, MaxLastAccessedDate)
    SELECT	MBAssociationID AS ID
		,	MAX(CreatedDate) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBAssociationID IS NOT NULL
    GROUP BY MBAssociationID;
    
    /*******UPDATE MBAccount.LastLoginTime********************/
	UPDATE DCS_DataCenter.MBAccount AS acc
		INNER JOIN Temp_MBAccount AS tmp ON tmp.ID = acc.ID
    SET acc.LastLoginTime = tmp.LastLoginTime
	WHERE acc.LastLoginTime < tmp.LastLoginTime;
    
    /*******UPDATE MBDeviceCodeMediaDRM ********************/
	UPDATE DCS_DataCenter.MBDeviceCodeMediaDRM AS drm
		INNER JOIN Temp_MBDeviceCodeMediaDRM AS tmp ON tmp.ID = drm.ID
    SET drm.LastAccessedDate = tmp.MaxLastAccessedDate
	WHERE drm.LastAccessedDate < tmp.MaxLastAccessedDate;
    
	/*******UPDATE MBDeviceCodeMachine ********************/               
	UPDATE DCS_DataCenter.MBDeviceCodeMachine AS dc
		INNER JOIN Temp_MBDeviceCodeMachine AS tmp ON tmp.ID = dc.ID
    SET dc.LastAccessedDate = tmp.MaxLastAccessedDate
	WHERE dc.LastAccessedDate < tmp.MaxLastAccessedDate;
    
    /*******UPDATE MBDeviceCodeTagging ********************/
	UPDATE DCS_DataCenter.MBDeviceCodeTagging AS tg
		INNER JOIN Temp_MBDeviceCodeTagging AS tmp ON tmp.ID = tg.ID
    SET tg.LastAccessedDate = tmp.MaxLastAccessedDate
	WHERE tg.LastAccessedDate < tmp.MaxLastAccessedDate;
    
	/*******UPDATE MBDeviceModel ********************/         
	UPDATE DCS_DataCenter.MBDeviceModel AS dm
		INNER JOIN Temp_MBDeviceModel AS tmp ON tmp.ID = dm.ID
    SET dm.LastAccessedDate = tmp.MaxLastAccessedDate
	WHERE dm.LastAccessedDate < tmp.MaxLastAccessedDate;
    
	/*******UPDATE MBOS ********************/              
	UPDATE DCS_DataCenter.MBOS AS os
		INNER JOIN Temp_MBOS AS tmp ON tmp.ID = os.ID
    SET os.LastAccessedDate = tmp.MaxLastAccessedDate
	WHERE os.LastAccessedDate < tmp.MaxLastAccessedDate;
    
	/*******UPDATE MBUserSetting ********************/
	UPDATE DCS_DataCenter.MBUserSetting AS us
		INNER JOIN Temp_MBUserSetting AS tmp ON tmp.ID = us.ID
    SET us.LastAccessedDate = tmp.MaxLastAccessedDate
	WHERE us.LastAccessedDate < tmp.MaxLastAccessedDate;
    
	/*******UPDATE MBDevice ********************/
	UPDATE DCS_DataCenter.MBDevice AS dv
		INNER JOIN Temp_MBDevice AS tmp ON tmp.ID = dv.ID
    SET dv.LastAccessedDate = tmp.MaxLastAccessedDate
	WHERE dv.LastAccessedDate < tmp.MaxLastAccessedDate;
    
	/*******UPDATE Temp_MBAssociation ********************/
	UPDATE DCS_DataCenter.MBAssociation AS ass
		INNER JOIN Temp_MBAssociation AS tmp ON tmp.ID = dv.ID
    SET ass.LastAccessedDate = tmp.MaxLastAccessedDate
	WHERE ass.LastAccessedDate < tmp.MaxLastAccessedDate;
    
    /*******UPDATE SystemSetting MaxTransID********************/
    SELECT MAX(ID)
    INTO lv_MaxID
    FROM Temp_MBTransaction07;
    
    IF lv_MaxID IS NOT NULL THEN
		UPDATE DCS_DataCenter.SystemSetting
		SET VValue = lv_MaxID,
			UpdatedTime = lv_CurrentDatetime
		WHERE ID = CONST_SYSTEMSETTING_MAXMBTRANSACTION07ID;
    END IF;
END$$
DELIMITER ;