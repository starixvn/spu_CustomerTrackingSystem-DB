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
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_ArchiveData_MBLastAccessedDate_Update(100);
    */
    
    DECLARE CONST_SYSTEMSETTING_MAXMBTRANSACTION07ID	INT DEFAULT 30;
    DECLARE lv_MaxID	 								BIGINT UNSIGNED;
    DECLARE lv_CurrentDate 								TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    
    SELECT VValue
    INTO lv_MaxID
    FROM DCS_DataCenter.SystemSetting
    WHERE ID = CONST_SYSTEMSETTING_MAXMBTRANSACTION07ID;
    
    
    /*******INIT TEMPORARY TABLE************/
    DROP TEMPORARY TABLE IF EXISTS Temp_MBTransaction07;
	CREATE TEMPORARY TABLE Temp_MBTransaction07(
        	ID						BIGINT UNSIGNED PRIMARY KEY
        ,	MBAccountID				BIGINT UNSIGNED
        ,	CreatedDate				DATE
        ,	TransTime				DATETIME(4)
        ,	MBDeviceCodeMediaDRMID	BIGINT UNSIGNED
        ,	MBDeviceCodeMachineID	BIGINT UNSIGNED
        ,	MBDeviceCodeTaggingID	BIGINT UNSIGNED
        ,	MBDeviceModelID			BIGINT UNSIGNED
        ,	MBOSID					BIGINT UNSIGNED
        ,	MBUserSettingID			BIGINT UNSIGNED
        ,	MBDeviceID				BIGINT UNSIGNED
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MBAccount;
	CREATE TEMPORARY TABLE Temp_MBAccount(
        	ID						BIGINT UNSIGNED PRIMARY KEY
        ,	LastLoginTime			DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeMediaDRM;
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeMediaDRM(
        	ID						BIGINT UNSIGNED PRIMARY KEY
        ,	MaxLastAccessedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeMachine;
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeMachine(
        	ID						BIGINT UNSIGNED PRIMARY KEY
        ,	MaxLastAccessedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeTagging;
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeTagging(
        	ID						BIGINT UNSIGNED PRIMARY KEY
        ,	MaxLastAccessedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceModel;
	CREATE TEMPORARY TABLE Temp_MBDeviceModel(
        	ID						BIGINT UNSIGNED PRIMARY KEY
        ,	MaxLastAccessedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MBOS;
	CREATE TEMPORARY TABLE Temp_MBOS(
        	ID						BIGINT UNSIGNED PRIMARY KEY
        ,	MaxLastAccessedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MBUserSetting;
	CREATE TEMPORARY TABLE Temp_MBUserSetting(
        	ID						BIGINT UNSIGNED PRIMARY KEY
        ,	MaxLastAccessedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_MBDevice;
	CREATE TEMPORARY TABLE Temp_MBDevice(
        	ID						BIGINT UNSIGNED PRIMARY KEY
        ,	MaxLastAccessedDate		DATETIME
    );
    
    /*******GET DATA Transaction07********************/
    INSERT INTO Temp_MBTransaction07(ID, MBAccountID, CreatedDate, TransTime, MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID, MBDeviceModelID, MBOSID, MBUserSettingID, MBDeviceID)
    SELECT 	trans.ID
        ,	IFNULL(trans.MBAccountID, 0) 								AS MBAccountID
        ,	trans.CreatedDate
        ,	trans.TransTime
        ,	IFNULL(dm.MBDeviceCodeMediaDRMID, 0) 						AS MBDeviceCodeMediaDRMID
        ,	IFNULL(dm.MBDeviceCodeMachineID, 0) 						AS MBDeviceCodeMachineID
        ,	IFNULL(dm.MBDeviceCodeTaggingID, 0) 						AS MBDeviceCodeTaggingID
        ,	IFNULL(trans.MBDeviceModelID, 0) 							AS MBDeviceModelID
        ,	IFNULL(trans.MBOSID, 0) 									AS MBOSID
        ,	IFNULL(trans.MBUserSettingID, 0) 							AS MBUserSettingID
        ,	IFNULL(trans.MBDeviceID, 0) 								AS MBDeviceID
	FROM DCS_DataCenter.MBTransaction07 AS trans
		LEFT JOIN DCS_DataCenter.MBDeviceMapping AS dm ON dm.ID = trans.MBDeviceMappingID
	WHERE trans.ID > lv_MaxID
	LIMIT ip_BatchSize;
    
    
    /*******GET LastAccessedDate ********************/
    INSERT INTO Temp_MBAccount(ID, LastLoginTime)
    SELECT 	MBAccountID AS ID
		,	MAX(TransTime) AS LastLoginTime
    FROM Temp_MBTransaction07
    WHERE MBAccountID IS NOT NULL
    GROUP BY MBAccountID;
    
    INSERT INTO Temp_MBDeviceCodeMediaDRM(ID, MaxLastAccessedDate)
    SELECT 	MBDeviceCodeMediaDRMID AS ID
		,	MAX(TransTime) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBDeviceCodeMediaDRMID IS NOT NULL
    GROUP BY MBDeviceCodeMediaDRMID;
    
    INSERT INTO Temp_MBDeviceCodeMachine(ID, MaxLastAccessedDate)
    SELECT 	MBDeviceCodeMachineID AS ID
		,	MAX(TransTime) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBDeviceCodeMachineID IS NOT NULL
    GROUP BY MBDeviceCodeMachineID;
    
    INSERT INTO Temp_MBDeviceCodeTagging(ID, MaxLastAccessedDate)
    SELECT 	MBDeviceCodeTaggingID AS ID
		,	MAX(TransTime) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBDeviceCodeTaggingID IS NOT NULL
    GROUP BY MBDeviceCodeTaggingID;
    
    INSERT INTO Temp_MBDeviceModel(ID, MaxLastAccessedDate)
    SELECT 	MBDeviceModelID AS ID
		,	MAX(TransTime) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBDeviceModelID IS NOT NULL
    GROUP BY MBDeviceModelID;
    
    INSERT INTO Temp_MBOS(ID, MaxLastAccessedDate)
    SELECT 	MBOSID AS ID
		,	MAX(TransTime) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBOSID IS NOT NULL
    GROUP BY MBOSID;
    
    INSERT INTO Temp_MBUserSetting(ID, MaxLastAccessedDate)
    SELECT 	MBUserSettingID AS ID
		,	MAX(TransTime) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBUserSettingID IS NOT NULL
    GROUP BY MBUserSettingID;
    
    INSERT INTO Temp_MBDevice(ID, MaxLastAccessedDate)
    SELECT 	MBDeviceID AS ID
		,	MAX(TransTime) AS MaxLastAccessedDate
    FROM Temp_MBTransaction07
    WHERE MBDeviceID IS NOT NULL
    GROUP BY MBDeviceID;
    
    /*******UPDATE MBAccount.LastLoginTime********************/
    UPDATE DCS_DataCenter.MBAccount AS acc
		INNER JOIN Temp_MBAccount AS tmp ON tmp.ID = acc.ID
	SET acc.LastLoginTime = tmp.LastLoginTime;
    
    /*******UPDATE MBDeviceCodeMediaDRM ********************/
    DELETE tmp
    FROM Temp_MBDeviceCodeMediaDRM AS tmp
		INNER JOIN DCS_DataCenter.MBLastAccessedDate AS las ON las.TableName = 'MBDeviceCodeMediaDRM' 
															AND las.RecordID = tmp.ID
	WHERE las.LastAccessedDate >= tmp.MaxLastAccessedDate;
    
    INSERT INTO DCS_DataCenter.MBLastAccessedDate(TableName, RecordID, LastAccessedDate)
    SELECT	'MBDeviceCodeMediaDRM' 		AS TableName
		,	ID 							AS RecordID
		,	MaxLastAccessedDate			AS LastAccessedDate
	FROM Temp_MBDeviceCodeMediaDRM
    ON DUPLICATE KEY UPDATE LastAccessedDate = VALUES(LastAccessedDate),
							ModifiedTime = lv_CurrentDate;
	
	/*******UPDATE MBDeviceCodeMachine ********************/
    DELETE tmp
    FROM Temp_MBDeviceCodeMachine AS tmp
		INNER JOIN DCS_DataCenter.MBLastAccessedDate AS las ON las.TableName = 'MBDeviceCodeMachine' 
															AND las.RecordID = tmp.ID
	WHERE las.LastAccessedDate >= tmp.MaxLastAccessedDate;
    
    INSERT INTO DCS_DataCenter.MBLastAccessedDate(TableName, RecordID, LastAccessedDate)
    SELECT	'MBDeviceCodeMachine' 		AS TableName
		,	ID 							AS RecordID
		,	MaxLastAccessedDate			AS LastAccessedDate
	FROM Temp_MBDeviceCodeMachine
    ON DUPLICATE KEY UPDATE LastAccessedDate = VALUES(LastAccessedDate),
							ModifiedTime = lv_CurrentDate;
	
    /*******UPDATE MBDeviceCodeTagging ********************/
    DELETE tmp
    FROM Temp_MBDeviceCodeTagging AS tmp
		INNER JOIN DCS_DataCenter.MBLastAccessedDate AS las ON las.TableName = 'MBDeviceCodeTagging' 
															AND las.RecordID = tmp.ID
	WHERE las.LastAccessedDate >= tmp.MaxLastAccessedDate;
    
    INSERT INTO DCS_DataCenter.MBLastAccessedDate(TableName, RecordID, LastAccessedDate)
    SELECT	'MBDeviceCodeTagging' 		AS TableName
		,	ID 							AS RecordID
		,	MaxLastAccessedDate			AS LastAccessedDate
	FROM Temp_MBDeviceCodeTagging
    ON DUPLICATE KEY UPDATE LastAccessedDate = VALUES(LastAccessedDate),
							ModifiedTime = lv_CurrentDate;
                            
	/*******UPDATE MBDeviceModel ********************/
    DELETE tmp
    FROM Temp_MBDeviceModel AS tmp
		INNER JOIN DCS_DataCenter.MBLastAccessedDate AS las ON las.TableName = 'MBDeviceModel' 
															AND las.RecordID = tmp.ID
	WHERE las.LastAccessedDate >= tmp.MaxLastAccessedDate;
    
    INSERT INTO DCS_DataCenter.MBLastAccessedDate(TableName, RecordID, LastAccessedDate)
    SELECT	'MBDeviceModel' 			AS TableName
		,	ID 							AS RecordID
		,	MaxLastAccessedDate			AS LastAccessedDate
	FROM Temp_MBDeviceModel
    ON DUPLICATE KEY UPDATE LastAccessedDate = VALUES(LastAccessedDate),
							ModifiedTime = lv_CurrentDate;
                            
	/*******UPDATE MBOS ********************/
    DELETE tmp
    FROM Temp_MBOS AS tmp
		INNER JOIN DCS_DataCenter.MBLastAccessedDate AS las ON las.TableName = 'MBOS' 
															AND las.RecordID = tmp.ID
	WHERE las.LastAccessedDate >= tmp.MaxLastAccessedDate;
    
    INSERT INTO DCS_DataCenter.MBLastAccessedDate(TableName, RecordID, LastAccessedDate)
    SELECT	'MBOS' 			AS TableName
		,	ID 							AS RecordID
		,	MaxLastAccessedDate			AS LastAccessedDate
	FROM Temp_MBOS
    ON DUPLICATE KEY UPDATE LastAccessedDate = VALUES(LastAccessedDate),
							ModifiedTime = lv_CurrentDate;
                            
	/*******UPDATE MBUserSetting ********************/
    DELETE tmp
    FROM Temp_MBUserSetting AS tmp
		INNER JOIN DCS_DataCenter.MBLastAccessedDate AS las ON las.TableName = 'MBUserSetting' 
															AND las.RecordID = tmp.ID
	WHERE las.LastAccessedDate >= tmp.MaxLastAccessedDate;
    
    INSERT INTO DCS_DataCenter.MBLastAccessedDate(TableName, RecordID, LastAccessedDate)
    SELECT	'MBUserSetting' 			AS TableName
		,	ID 							AS RecordID
		,	MaxLastAccessedDate			AS LastAccessedDate
	FROM Temp_MBUserSetting
    ON DUPLICATE KEY UPDATE LastAccessedDate = VALUES(LastAccessedDate),
							ModifiedTime = lv_CurrentDate;
                            
	/*******UPDATE MBDevice ********************/
    DELETE tmp
    FROM Temp_MBDevice AS tmp
		INNER JOIN DCS_DataCenter.MBLastAccessedDate AS las ON las.TableName = 'MBDevice' 
															AND las.RecordID = tmp.ID
	WHERE las.LastAccessedDate >= tmp.MaxLastAccessedDate;
    
    INSERT INTO DCS_DataCenter.MBLastAccessedDate(TableName, RecordID, LastAccessedDate)
    SELECT	'MBDevice' 					AS TableName
		,	ID 							AS RecordID
		,	MaxLastAccessedDate			AS LastAccessedDate
	FROM Temp_MBDevice
    ON DUPLICATE KEY UPDATE LastAccessedDate = VALUES(LastAccessedDate),
							ModifiedTime = lv_CurrentDate;
                            
	
    /*******UPDATE SystemSetting MaxTransID********************/
    SELECT MAX(ID)
    INTO lv_MaxID
    FROM Temp_MBTransaction07;
    
    IF lv_MaxID IS NOT NULL
    THEN
		UPDATE DCS_DataCenter.SystemSetting
		SET VValue = lv_MaxID,
			UpdatedTime = lv_CurrentDate
		WHERE ID = CONST_SYSTEMSETTING_MAXMBTRANSACTION07ID;
    END IF;
END$$
DELIMITER ;