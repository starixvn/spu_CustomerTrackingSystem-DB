/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBDeviceMapping_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBDeviceMapping_Insert`(
	IN ip_TableName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20241205@Jonathan.Doan
	    Task : Transform MBDevice
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20241205@Jonathan.Doan: Created [RedmineID: #213401]
		    - 20250108@Jonathan.Doan: HotFix when duplicate  [RedmineID: #213401]
		    - 20250425@Jonathan.Doan: Add field CreatedDate, CreatedTime [Redmine ID: #221973]
	    Param's Explanation (filtered by):
        
        Example:
			DROP TABLE IF EXISTS Temp_NewDevice;
			CREATE TEMPORARY TABLE Temp_NewDevice(
					TransID						INT NOT NULL AUTO_INCREMENT PRIMARY KEY 
				,	MBRawTransactionID			INT DEFAULT 0
				,	SameDeviceID				BIGINT UNSIGNED
				,	RecoverType					SMALLINT

				,	MBDeviceCodeMediaDRMID		BIGINT UNSIGNED
				,	MBDeviceCodeMachineID		BIGINT UNSIGNED
				,	MBDeviceCodeTaggingID		BIGINT UNSIGNED
                
				,	MBDeviceMappingID			BIGINT UNSIGNED
				,	MBDeviceID					BIGINT UNSIGNED
			);
            
			INSERT INTO Temp_NewDevice(TransID, MBRawTransactionID, SameDeviceID, RecoverType)
			VALUES(4,4,4,0);
            
			CALL DCS_DC_Transform_MBDeviceMapping_Insert('Temp_NewDevice');
            select * from Temp_NewDevice;
            select * from MBDeviceMapping;
	*/
    
    /********************** Constants ***********************************/    
    DECLARE CONST_RECOVERTYPE_FIRSTRULE		SMALLINT DEFAULT 1;
    DECLARE CONST_RECOVERTYPE_SECONDRULE	SMALLINT DEFAULT 2;
    DECLARE CONST_RECOVERTYPE_THIRDRULE		SMALLINT DEFAULT 3;

    /********************** Local variables ***********************************/
    DECLARE lv_CurrentDatetime 				DATETIME DEFAULT NOW();
    
    /********************** Error handler ***********************************/
	DECLARE lv_SQLState CHAR(5);
	DECLARE lv_ErrorCode INT;
	DECLARE lv_ErrorMessage TEXT;
	DECLARE lv_FullMessage TEXT;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN
		GET DIAGNOSTICS CONDITION 1
			lv_SQLState = RETURNED_SQLSTATE,
			lv_ErrorCode = MYSQL_ERRNO,
			lv_ErrorMessage = MESSAGE_TEXT;

		SET lv_FullMessage = CONCAT('SQL:', lv_SQLState, ', code:', lv_ErrorCode, ', Msg:', lv_ErrorMessage);
        
		INSERT INTO CTS_Log.FPSLog(SpName, JsonString, OtherText, InsertTime)
		SELECT 'DCS_DC_Transform_MBDeviceMapping_Insert', NULL, lv_FullMessage, CURRENT_TIMESTAMP();
        
        RESIGNAL;
	END;
        
    /********************** CREAT TEMP TABLE ***********************************/
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceMapping;
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceMappingInsert;
	DROP TEMPORARY TABLE IF EXISTS Temp_CheckSameDevice;
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistingDevice;
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeMediaDRM;
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeMachine;
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeTagging;
    
    
	CREATE TEMPORARY TABLE Temp_DeviceMapping(
			TransID							BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBRawTransactionID				BIGINT UNSIGNED NOT NULL
		,	MBDeviceCodeMediaDRMID			BIGINT UNSIGNED
		,	MBDeviceCodeMachineID			BIGINT UNSIGNED
		,	MBDeviceCodeTaggingID			BIGINT UNSIGNED
		,	MBDeviceMappingID				BIGINT UNSIGNED DEFAULT 0
		,	MBDeviceID						BIGINT UNSIGNED DEFAULT 0
		,	TransTime						DATETIME(4)
		,	SameDeviceID					BIGINT UNSIGNED DEFAULT 0
        ,	RecoverType						SMALLINT DEFAULT 0 /* SELECT * FROM DCS_DataCenter.StaticList WHERE ListID = 6; */
	);
    
	CREATE TEMPORARY TABLE Temp_CheckSameDevice(
			ID								BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	SameDeviceID					BIGINT UNSIGNED DEFAULT 0
		,	MBDeviceID						BIGINT UNSIGNED DEFAULT 0
		,	RecoverType						SMALLINT		DEFAULT 0
		,	MBDeviceCodeMediaDRMID			BIGINT UNSIGNED
		,	MBDeviceCodeMachineID			BIGINT UNSIGNED
		,	MBDeviceCodeTaggingID			BIGINT UNSIGNED
	);
    
	CREATE TEMPORARY TABLE Temp_ExistingDevice(
			SameDeviceID					BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBDeviceID						BIGINT UNSIGNED DEFAULT 0
	);
    
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeMediaDRM(
			MBDeviceCodeMediaDRMID			BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBDeviceID						BIGINT UNSIGNED DEFAULT 0
	);
    
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeMachine(
			MBDeviceCodeMachineID			BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBDeviceID						BIGINT UNSIGNED DEFAULT 0
	);
    
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeTagging(
			MBDeviceCodeTaggingID			BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBDeviceID						BIGINT UNSIGNED DEFAULT 0
	);
    
	CREATE TEMPORARY TABLE Temp_DeviceMappingInsert(
			MBDeviceCodeMediaDRMID			BIGINT UNSIGNED
		,	MBDeviceCodeMachineID			BIGINT UNSIGNED
		,	MBDeviceCodeTaggingID			BIGINT UNSIGNED
		,	IsNewRecord						TINYINT	DEFAULT 1
        , 	PRIMARY KEY (MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID)
    );
    
	SET @sql = CONCAT('INSERT INTO Temp_DeviceMapping(TransID, MBRawTransactionID, TransTime, SameDeviceID, RecoverType, MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID) 
						SELECT 	tmp.TransID
							,	trans.MBRawTransactionID
							,	trans.TransTime
							,	tmp.SameDeviceID
							,	tmp.RecoverType
							,	IFNULL(trans.MBDeviceCodeMediaDRMID, 0) AS MBDeviceCodeMediaDRMID
							,	IFNULL(trans.MBDeviceCodeMachineID, 0) AS MBDeviceCodeMachineID
							,	IFNULL(trans.MBDeviceCodeTaggingID, 0) AS MBDeviceCodeTaggingID
                        FROM ', ip_TableName , ' tmp
							INNER JOIN DCS_DataCenter.MBTransaction AS trans ON trans.ID = tmp.TransID
                        WHERE trans.MBDeviceCodeMediaDRMID > 0
							OR trans.MBDeviceCodeMachineID > 0
							OR trans.MBDeviceCodeTaggingID > 0
                        ');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    /********************** Get MBDeviceID from MBDeviceMapping ***********************************/
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN MBDeviceMapping AS dm ON dm.MBDeviceCodeMediaDRMID = tmp.MBDeviceCodeMediaDRMID
										AND dm.MBDeviceCodeMachineID = tmp.MBDeviceCodeMachineID
										AND dm.MBDeviceCodeTaggingID = tmp.MBDeviceCodeTaggingID
	SET tmp.MBDeviceID = dm.MBDeviceID;
    
    
    /********************** Insert into Temp_ExistingDevice ***********************************/
    INSERT INTO Temp_ExistingDevice(SameDeviceID, MBDeviceID)
    SELECT	SameDeviceID
		,	MIN(MBDeviceID) AS MBDeviceID
	FROM Temp_DeviceMapping
    WHERE MBDeviceID > 0
    GROUP BY SameDeviceID;
    
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_ExistingDevice AS tmpED ON tmpED.SameDeviceID = tmp.SameDeviceID
	SET tmp.MBDeviceID = tmpED.MBDeviceID
	WHERE tmp.MBDeviceID = 0;
    
    /********************** Check Rule 1 (MBDeviceCodeMediaDRM) ***********************************/
    INSERT INTO Temp_MBDeviceCodeMediaDRM(MBDeviceCodeMediaDRMID)
    SELECT DISTINCT MBDeviceCodeMediaDRMID
    FROM Temp_DeviceMapping
    WHERE MBDeviceID = 0
		AND MBDeviceCodeMediaDRMID > 0;
    
    UPDATE Temp_MBDeviceCodeMediaDRM AS tmp
	SET tmp.MBDeviceID = IFNULL((
		SELECT dm.MBDeviceID
		FROM DCS_DataCenter.MBDeviceMapping AS dm
		WHERE dm.MBDeviceCodeMediaDRMID = tmp.MBDeviceCodeMediaDRMID
		ORDER BY dm.ID DESC
        LIMIT 1
	), 0);
    
    /********************** Update after Check Rule 1 ***********************************/
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_MBDeviceCodeMediaDRM AS tmpR1 ON tmpR1.MBDeviceCodeMediaDRMID = tmp.MBDeviceCodeMediaDRMID
	SET tmp.MBDeviceID = tmpR1.MBDeviceID,
		tmp.RecoverType = CONST_RECOVERTYPE_FIRSTRULE
    WHERE tmp.MBDeviceID = 0
		AND tmpR1.MBDeviceID > 0;
    
    INSERT IGNORE INTO Temp_ExistingDevice(SameDeviceID, MBDeviceID)
    SELECT	SameDeviceID
		,	MBDeviceID
	FROM Temp_DeviceMapping 
    WHERE MBDeviceID > 0;
    
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_ExistingDevice AS tmpED ON tmpED.SameDeviceID = tmp.SameDeviceID
	SET tmp.MBDeviceID = tmpED.MBDeviceID
	WHERE tmp.MBDeviceID = 0;
    
    /********************** Check Rule 2 (MBDeviceCodeMachineID) ***********************************/
    INSERT INTO Temp_MBDeviceCodeMachine(MBDeviceCodeMachineID)
    SELECT DISTINCT MBDeviceCodeMachineID
    FROM Temp_DeviceMapping
    WHERE MBDeviceID = 0
		AND MBDeviceCodeMachineID > 0;
    
    UPDATE Temp_MBDeviceCodeMachine AS tmp
	SET tmp.MBDeviceID = IFNULL((
		SELECT dm.MBDeviceID
		FROM DCS_DataCenter.MBDeviceMapping AS dm
		WHERE dm.MBDeviceCodeMachineID = tmp.MBDeviceCodeMachineID
		ORDER BY dm.ID DESC
        LIMIT 1
	), 0);
    
    /********************** Update after Check Rule 2 ***********************************/
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_MBDeviceCodeMachine AS tmpR2 ON tmpR2.MBDeviceCodeMachineID = tmp.MBDeviceCodeMachineID
	SET tmp.MBDeviceID = tmpR2.MBDeviceID,
		tmp.RecoverType = CONST_RECOVERTYPE_SECONDRULE
    WHERE tmp.MBDeviceID = 0
		AND tmpR2.MBDeviceID > 0;
    
    INSERT IGNORE INTO Temp_ExistingDevice(SameDeviceID, MBDeviceID)
    SELECT	SameDeviceID
		,	MBDeviceID
	FROM Temp_DeviceMapping
    WHERE MBDeviceID > 0;
    
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_ExistingDevice AS tmpED ON tmpED.SameDeviceID = tmp.SameDeviceID
	SET tmp.MBDeviceID = tmpED.MBDeviceID
	WHERE tmp.MBDeviceID = 0;
    
    /********************** Check Rule 3 (MBDeviceCodeTaggingID) ***********************************/
    INSERT INTO Temp_MBDeviceCodeTagging(MBDeviceCodeTaggingID)
    SELECT DISTINCT MBDeviceCodeTaggingID
    FROM Temp_DeviceMapping
    WHERE MBDeviceID = 0
		AND MBDeviceCodeTaggingID > 0;
    
    UPDATE Temp_MBDeviceCodeTagging AS tmp
	SET tmp.MBDeviceID = IFNULL((
		SELECT dm.MBDeviceID
		FROM DCS_DataCenter.MBDeviceMapping AS dm
		WHERE dm.MBDeviceCodeTaggingID = tmp.MBDeviceCodeTaggingID
		ORDER BY dm.ID DESC
        LIMIT 1
	), 0);
    
    /********************** Update after Check Rule 3 ***********************************/
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_MBDeviceCodeTagging AS tmpR3 ON tmpR3.MBDeviceCodeTaggingID = tmp.MBDeviceCodeTaggingID
	SET tmp.MBDeviceID = tmpR3.MBDeviceID,
		tmp.RecoverType = CONST_RECOVERTYPE_THIRDRULE
    WHERE tmp.MBDeviceID = 0
		AND tmpR3.MBDeviceID > 0;
    
    INSERT IGNORE INTO Temp_ExistingDevice(SameDeviceID, MBDeviceID)
    SELECT	SameDeviceID
		,	MBDeviceID
	FROM Temp_DeviceMapping
    WHERE MBDeviceID > 0;
    
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_ExistingDevice AS tmpED ON tmpED.SameDeviceID = tmp.SameDeviceID
	SET tmp.MBDeviceID = tmpED.MBDeviceID
	WHERE tmp.MBDeviceID = 0;
    
    
    /********************** INSERT New device ***********************************/
    INSERT IGNORE INTO DCS_DataCenter.MBDevice(FirstMBRawTransactionID, LastAccessedDate, CreatedDate, CreatedTime)
    SELECT 	DISTINCT 
			SameDeviceID
		,	DATE(lv_CurrentDatetime) AS LastAccessedDate
		,	DATE(TransTime) AS CreatedDate
		,	TransTime AS CreatedTime
    FROM Temp_DeviceMapping
    WHERE MBDeviceID = 0
		AND SameDeviceID > 0;
    
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN DCS_DataCenter.MBDevice AS dv ON dv.FirstMBRawTransactionID = tmp.SameDeviceID
	SET tmp.MBDeviceID = dv.ID
    WHERE tmp.MBDeviceID = 0;
    
    INSERT IGNORE INTO Temp_DeviceMappingInsert(MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID)
    SELECT	MBDeviceCodeMediaDRMID
		,	MBDeviceCodeMachineID
        ,	MBDeviceCodeTaggingID
    FROM Temp_DeviceMapping
    GROUP BY MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID;
    
    UPDATE Temp_DeviceMappingInsert AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceMapping AS dm ON dm.MBDeviceCodeMediaDRMID = tmp.MBDeviceCodeMediaDRMID
														AND dm.MBDeviceCodeMachineID = tmp.MBDeviceCodeMachineID
														AND dm.MBDeviceCodeTaggingID = tmp.MBDeviceCodeTaggingID
    SET tmp.IsNewRecord = 0;
    
    INSERT INTO DCS_DataCenter.MBDeviceMapping(MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID, MBDeviceID, FirstMBRawTransactionID, RecoverType, InsertedTime, CreatedDate)
    SELECT 	tmp.MBDeviceCodeMediaDRMID
		,	tmp.MBDeviceCodeMachineID
        ,	tmp.MBDeviceCodeTaggingID
        ,	MIN(tmp.MBDeviceID) AS MBDeviceID
        ,	MIN(tmp.MBRawTransactionID) AS FirstMBRawTransactionID
        ,	MIN(tmp.RecoverType) AS RecoverType
        ,	lv_CurrentDatetime AS InsertedTime
        ,	DATE(MIN(TransTime)) AS CreatedDate
    FROM Temp_DeviceMapping AS tmp
		INNER JOIN Temp_DeviceMappingInsert AS tmpI ON tmp.MBDeviceCodeMediaDRMID = tmpI.MBDeviceCodeMediaDRMID
													AND tmp.MBDeviceCodeMachineID = tmpI.MBDeviceCodeMachineID
													AND tmp.MBDeviceCodeTaggingID = tmpI.MBDeviceCodeTaggingID
                                                    AND tmpI.IsNewRecord = 1
    WHERE tmp.MBDeviceID > 0
    GROUP BY tmp.MBDeviceCodeMediaDRMID, tmp.MBDeviceCodeMachineID, tmp.MBDeviceCodeTaggingID;
    
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceMapping AS dm ON dm.MBDeviceCodeMediaDRMID = tmp.MBDeviceCodeMediaDRMID
														AND dm.MBDeviceCodeMachineID = tmp.MBDeviceCodeMachineID
														AND dm.MBDeviceCodeTaggingID = tmp.MBDeviceCodeTaggingID
	SET tmp.MBDeviceMappingID = dm.ID,
		tmp.MBDeviceID = dm.MBDeviceID,
        tmp.RecoverType = CASE WHEN tmp.MBRawTransactionID = dm.FirstMBRawTransactionID THEN tmp.RecoverType
								WHEN tmp.MBDeviceCodeMediaDRMID > 0 THEN 1
								WHEN tmp.MBDeviceCodeMachineID > 0 THEN 2
								WHEN tmp.MBDeviceCodeTaggingID > 0 THEN 3
								ELSE -1
							END;
        
    
	SET @sql = CONCAT('UPDATE ', ip_TableName,' AS tmp
							LEFT JOIN Temp_DeviceMapping AS dm ON dm.TransID = tmp.TransID
						SET tmp.MBDeviceMappingID = dm.MBDeviceMappingID,
							tmp.MBDeviceID = dm.MBDeviceID,
							tmp.RecoverType = CASE WHEN dm.TransID IS NULL THEN -1 ELSE dm.RecoverType END');
	PREPARE stmt FROM @sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;