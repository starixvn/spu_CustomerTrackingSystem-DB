/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBDevice_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBDevice_Insert`(
	IN ip_TransIDs INT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 202401202@Lando.Vu
	    Task : Transform Transaction
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 202401202@Lando.Vu: Transform to MBTransaction [Redmine ID: #213401]
            
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Transform_MBDevice_Insert('50');
	*/ 
    
    DECLARE CONST_RECOVERTYPE_FIRSTRULE			SMALLINT DEFAULT 1;
    DECLARE CONST_RECOVERTYPE_SECONDRULE		SMALLINT DEFAULT 2;
    DECLARE CONST_RECOVERTYPE_THIRDRULE			SMALLINT DEFAULT 3;
    
	DECLARE CONST_DEVICESTATUS_NEW				TINYINT DEFAULT 1;
	DECLARE CONST_DEVICESTATUS_OLD				TINYINT DEFAULT 2;
	DECLARE CONST_DEVICESTATUS_RECOVER			TINYINT DEFAULT 3;

    /********************** Local variables ***********************************/
    DECLARE lv_CurrentDate 						TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    
    /********************** CREAT TEMP TABLE ***********************************/
    DROP TEMPORARY TABLE IF EXISTS Temp_Input;
	DROP TEMPORARY TABLE IF EXISTS Temp_MBTransaction;
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceMapping;
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeMediaDRM;
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeMachine;
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeTagging;
    
    CREATE TEMPORARY TABLE Temp_Input(
			TransID			 							BIGINT UNSIGNED NOT NULL PRIMARY KEY
    );
    
	CREATE TEMPORARY TABLE Temp_MBTransaction(
			ID											BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBRawTransactionID							BIGINT UNSIGNED NOT NULL
		,	MBAccountID									BIGINT UNSIGNED
		,	MBDeviceCodeMediaDRMID						BIGINT UNSIGNED
		,	MBDeviceCodeMachineID						BIGINT UNSIGNED
		,	MBDeviceCodeTaggingID						BIGINT UNSIGNED
	);
    
	CREATE TEMPORARY TABLE Temp_MBDeviceMapping(
			TransID										BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBRawTransactionID							BIGINT UNSIGNED NOT NULL
		,	MBDeviceID									BIGINT UNSIGNED DEFAULT 0
		,	MBDeviceCodeMediaDRMID						BIGINT UNSIGNED
		,	MBDeviceCodeMachineID						BIGINT UNSIGNED
		,	MBDeviceCodeTaggingID						BIGINT UNSIGNED
        ,	RecoverType									SMALLINT UNSIGNED DEFAULT 0 /* SELECT * FROM DCS_DataCenter.StaticList WHERE ListID = 4; */
		,	MBDeviceMappingID							BIGINT UNSIGNED DEFAULT 0
		,	FirstMBRawTransactionID						BIGINT UNSIGNED
        ,	SameDeviceWithRawTransID					BIGINT UNSIGNED DEFAULT 0
	);

    CREATE TEMPORARY TABLE Temp_MBDeviceCodeMediaDRM(
			ID											BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBDeviceID									BIGINT UNSIGNED DEFAULT 0
	);
    
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeMachineID(
			ID											BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBDeviceID									BIGINT UNSIGNED DEFAULT 0
	);
    
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeTagging(
			ID											BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBDeviceID									BIGINT UNSIGNED DEFAULT 0
	);
    
    CREATE TEMPORARY TABLE Temp_CheckSameMBDevice(
			MBRawTransactionID							BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	SameDeviceWithRawTransID					BIGINT UNSIGNED DEFAULT 0
		,	MBDeviceID									BIGINT UNSIGNED DEFAULT 0
		,	RecoverType									SMALLINT UNSIGNED DEFAULT 0
        
		,	FirstDeviceID								BIGINT UNSIGNED
		,	SecondDeviceID								BIGINT UNSIGNED
		,	ThirdDeviceID								BIGINT UNSIGNED
	);
    
    CREATE TEMPORARY TABLE Temp_ExistingDevice(
			MBRawTransactionID							BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	MBDeviceID									BIGINT UNSIGNED DEFAULT 0
		,	SameDeviceWithRawTransID					BIGINT UNSIGNED DEFAULT 0
	);
    
    /********************** Get Data ***********************************/
    SET @sql = CONCAT("INSERT IGNORE INTO Temp_Input(TransID) VALUES ('", REPLACE(ip_TransIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT INTO Temp_MBTransaction(ID, MBRawTransactionID, MBAccountID, MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID)
    SELECT 	ID
		,	MBRawTransactionID
        ,	MBAccountID
        ,	MBDeviceCodeMediaDRMID
        ,	MBDeviceCodeMachineID
		,	MBDeviceCodeTaggingID
    FROM Temp_Input AS tmp
		INNER JOIN DCS_DataCenter.MBTransaction AS trans ON trans.ID = tmp.TransID
    ORDER BY tmp.TransID ASC;
    
	ALTER TABLE Temp_MBTransaction
	ADD INDEX IX_Temp_MBTransaction_MBDeviceCodeMediaDRMID_MBAccountID (MBDeviceCodeMediaDRMID, MBAccountID),
	ADD INDEX IX_Temp_MBTransaction_MBDeviceCodeMachineID_MBAccountID (MBDeviceCodeMachineID, MBAccountID),
	ADD INDEX IX_Temp_MBTransaction_MBDeviceCodeTaggingID_MBAccountID (MBDeviceCodeTaggingID, MBAccountID);
    
    
    INSERT IGNORE INTO Temp_MBDeviceMapping(TransID, MBRawTransactionID, MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID)
    SELECT	tmp.ID
		,	tmp.MBRawTransactionID
		,	IFNULL(tmp.MBDeviceCodeMediaDRMID, 0) AS MBDeviceCodeMediaDRMID
		,	IFNULL(tmp.MBDeviceCodeMachineID, 0) AS MBDeviceCodeMachineID
		,	IFNULL(tmp.MBDeviceCodeTaggingID, 0) AS MBDeviceCodeTaggingID
    FROM Temp_MBTransaction AS tmp;
	
	ALTER TABLE Temp_MBDeviceMapping
	ADD INDEX IX_Temp_MBDeviceMapping_MBRawTransactionID (MBRawTransactionID),
	ADD INDEX IX_Temp_MBDeviceMapping_GroupIndex (MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID);

	/********************** Check Same Device ***********************************/
    INSERT INTO Temp_CheckSameMBDevice(MBRawTransactionID, FirstDeviceID, SecondDeviceID, ThirdDeviceID)
    SELECT 	MBRawTransactionID
		,	MBDeviceCodeMediaDRMID AS FirstDeviceID
		,	MBDeviceCodeMachineID AS SecondDeviceID
		,	MBDeviceCodeTaggingID AS ThirdDeviceID
    FROM Temp_MBDeviceMapping
    WHERE MBDeviceCodeMediaDRMID > 0
		OR MBDeviceCodeMachineID > 0
		OR MBDeviceCodeTaggingID > 0;
    
    CALL DCS_DataCenter.DCS_DC_Transform_MBDeviceMappingUpdateTheSameDevice('Temp_CheckSameMBDevice');
    
	ALTER TABLE Temp_CheckSameMBDevice
	ADD INDEX IX_Temp_CheckSameMBDevice_MBRawTransactionID (MBRawTransactionID);
    
    UPDATE Temp_MBDeviceMapping AS tmp
		INNER JOIN Temp_CheckSameMBDevice AS tmpND ON tmpND.MBRawTransactionID = tmp.MBRawTransactionID
	SET tmp.SameDeviceWithRawTransID = tmpND.SameDeviceWithRawTransID,
		tmp.RecoverType = CASE tmpND.RecoverType 
							WHEN 1 THEN CONST_RECOVERTYPE_FIRSTRULE
                            WHEN 2 THEN CONST_RECOVERTYPE_SECONDRULE
                            WHEN 3 THEN CONST_RECOVERTYPE_THIRDRULE
						END;
    
    
    /********************** Get Device in FP_DeviceMapping ***********************************/
    UPDATE Temp_MBDeviceMapping AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceMapping AS dm ON dm.MBDeviceCodeMediaDRMID 					= tmp.MBDeviceCodeMediaDRMID
														AND dm.MBDeviceCodeMachineID 					= tmp.MBDeviceCodeMachineID
														AND dm.MBDeviceCodeTaggingID 					= tmp.MBDeviceCodeTaggingID
	SET tmp.MBDeviceID = dm.MBDeviceID;
    
    /********************** Insert into Temp_ExistingDevice ***********************************/
    INSERT IGNORE INTO Temp_ExistingDevice(MBRawTransactionID, MBDeviceID, SameDeviceWithRawTransID)
    SELECT	MBRawTransactionID
		,	MBDeviceID
        ,	SameDeviceWithRawTransID
	FROM Temp_MBDeviceMapping
    WHERE MBDeviceID > 0;
    
    UPDATE Temp_MBDeviceMapping AS tmp
		INNER JOIN Temp_ExistingDevice AS tmpED ON tmpED.SameDeviceWithRawTransID = tmp.SameDeviceWithRawTransID
	SET tmp.MBDeviceID = tmpED.MBDeviceID
	WHERE tmp.MBDeviceID = 0;
    
    /********************** Check Rule 1 ***********************************/
    INSERT INTO Temp_MBDeviceCodeMediaDRM(ID)
    SELECT DISTINCT MBDeviceCodeMediaDRMID
    FROM Temp_MBDeviceMapping
    WHERE MBDeviceID = 0
		AND MBDeviceCodeMediaDRMID > 0;
    
    UPDATE Temp_MBDeviceCodeMediaDRM AS tmp
	SET tmp.MBDeviceID = IFNULL((
		SELECT dm.MBDeviceID
		FROM DCS_DataCenter.MBDeviceMapping AS dm
		WHERE dm.MBDeviceCodeMediaDRMID = tmp.ID
		ORDER BY dm.ID DESC
        LIMIT 1
	), 0);
    
    /********************** Update Temp ***********************************/
    UPDATE Temp_MBDeviceMapping AS tmp
		INNER JOIN Temp_MBDeviceCodeMediaDRM AS dc ON dc.ID = tmp.MBDeviceCodeMediaDRMID
	SET tmp.MBDeviceID = dc.MBDeviceID,
		tmp.RecoverType = CONST_RECOVERTYPE_FIRSTRULE
    WHERE tmp.MBDeviceID = 0
		AND dc.ID > 0;

	INSERT IGNORE INTO Temp_ExistingDevice(MBRawTransactionID, MBDeviceID, SameDeviceWithRawTransID)
    SELECT	MBRawTransactionID
		,	MBDeviceID
        ,	SameDeviceWithRawTransID
	FROM Temp_MBDeviceMapping 
    WHERE MBDeviceID > 0;
    
    UPDATE Temp_MBDeviceMapping AS tmp
		INNER JOIN Temp_ExistingDevice AS tmpED ON tmpED.SameDeviceWithRawTransID = tmp.SameDeviceWithRawTransID
	SET tmp.MBDeviceID = tmpED.MBDeviceID
	WHERE tmp.MBDeviceID = 0;
    
    
	/********************** Check Rule 2 ***********************************/
    INSERT INTO Temp_MBDeviceCodeMachineID(ID)
    SELECT DISTINCT MBDeviceCodeMachineID
    FROM Temp_MBDeviceMapping
    WHERE MBDeviceID = 0
		AND MBDeviceCodeMachineID > 0;
    
    UPDATE Temp_MBDeviceCodeMachineID AS tmp
	SET tmp.MBDeviceID = IFNULL((
		SELECT dm.MBDeviceID
		FROM DCS_DataCenter.MBDeviceMapping AS dm
		WHERE dm.MBDeviceCodeMachineID = tmp.ID
		ORDER BY dm.ID DESC
        LIMIT 1
	), 0);
    
    
    /********************** Update Temp ***********************************/
    UPDATE Temp_MBDeviceMapping AS tmp
		INNER JOIN Temp_MBDeviceCodeMachineID AS dc ON dc.ID = tmp.MBDeviceCodeMachineID
	SET tmp.MBDeviceID = dc.MBDeviceID,
		tmp.RecoverType = CONST_RECOVERTYPE_SECONDRULE
    WHERE tmp.MBDeviceID = 0
		AND dc.ID > 0;
	
    INSERT IGNORE INTO Temp_ExistingDevice(MBRawTransactionID, MBDeviceID, SameDeviceWithRawTransID)
    SELECT	MBRawTransactionID
		,	MBDeviceID
        ,	SameDeviceWithRawTransID
	FROM Temp_MBDeviceMapping 
    WHERE MBDeviceID > 0;
    
    UPDATE Temp_MBDeviceMapping AS tmp
		INNER JOIN Temp_ExistingDevice AS tmpED ON tmpED.SameDeviceWithRawTransID = tmp.SameDeviceWithRawTransID
	SET tmp.MBDeviceID = tmpED.MBDeviceID
	WHERE tmp.MBDeviceID = 0;
    
	/********************** Check Rule 3 ***********************************/
    INSERT INTO Temp_MBDeviceCodeTagging(ID)
    SELECT DISTINCT MBDeviceCodeTaggingID
    FROM Temp_MBDeviceMapping
    WHERE MBDeviceID = 0
		AND MBDeviceCodeTaggingID > 0;
    
    UPDATE Temp_MBDeviceCodeTagging AS tmp
	SET tmp.MBDeviceID = IFNULL((
		SELECT dm.MBDeviceID
		FROM DCS_DataCenter.MBDeviceMapping AS dm
		WHERE dm.MBDeviceCodeTaggingID = tmp.ID
		ORDER BY dm.ID DESC
        LIMIT 1
	), 0);
    
    
    /********************** Update Temp ***********************************/
    UPDATE Temp_MBDeviceMapping AS tmp
		INNER JOIN Temp_MBDeviceCodeTagging AS dc ON dc.ID = tmp.MBDeviceCodeTaggingID
	SET tmp.MBDeviceID = dc.MBDeviceID,
		tmp.RecoverType = CONST_RECOVERTYPE_THIRDRULE
    WHERE tmp.MBDeviceID = 0
		AND dc.ID > 0;
	
    INSERT IGNORE INTO Temp_ExistingDevice(MBRawTransactionID, MBDeviceID, SameDeviceWithRawTransID)
    SELECT	MBRawTransactionID
		,	MBDeviceID
        ,	SameDeviceWithRawTransID
	FROM Temp_MBDeviceMapping 
    WHERE MBDeviceID > 0;
    
    UPDATE Temp_MBDeviceMapping AS tmp
		INNER JOIN Temp_ExistingDevice AS tmpED ON tmpED.SameDeviceWithRawTransID = tmp.SameDeviceWithRawTransID
	SET tmp.MBDeviceID = tmpED.MBDeviceID
	WHERE tmp.MBDeviceID = 0;
    
    /********************** INSERT New device ***********************************/
    INSERT IGNORE INTO DCS_DataCenter.MBDevice(FirstMBRawTransactionID)
    SELECT DISTINCT SameDeviceWithRawTransID
    FROM Temp_MBDeviceMapping
    WHERE MBDeviceID = 0
		AND SameDeviceWithRawTransID > 0;
    
    UPDATE Temp_MBDeviceMapping AS tmp
		INNER JOIN DCS_DataCenter.MBDevice AS dv ON dv.FirstMBRawTransactionID = tmp.SameDeviceWithRawTransID
	SET tmp.MBDeviceID = dv.ID
    WHERE tmp.MBDeviceID = 0;
    
    INSERT IGNORE INTO DCS_DataCenter.MBDeviceMapping(MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID, MBDeviceID, FirstMBRawTransactionID, RecoverType)
    SELECT 	MBDeviceCodeMediaDRMID
		,   MBDeviceCodeMachineID
		,   MBDeviceCodeTaggingID
		,   MBDeviceID
		,   MBRawTransactionID AS FirstMBRawTransactionID
		,   RecoverType
    FROM Temp_MBDeviceMapping
    WHERE MBDeviceID > 0;
END$$
DELIMITER ;