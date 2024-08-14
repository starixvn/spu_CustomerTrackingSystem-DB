/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_FP_DeviceMappingInsert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_FP_DeviceMappingInsert`(
	IN ip_BatchSize INT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20240729@Jonathan.Doan
	    Task : Change Data Flow Ver. 6
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20240729@Jonathan.Doan: Created [RedmineID: #206403]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Transform_FP_DeviceMappingInsert('50');
	*/
    DECLARE CONST_MIN_TRANSACTION_TRANSID	INT DEFAULT 24;
    DECLARE CONST_MINUTE_TO_WAIT_EVOLUTION	INT DEFAULT 25;
    
	DECLARE lv_Min_Transaction_TransID  	BIGINT UNSIGNED;
	DECLARE lv_Minute_To_Wait_Evolution  	INT;
    DECLARE lv_CurrentDate 					TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    
	SET lv_Min_Transaction_TransID = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_MIN_TRANSACTION_TRANSID);
	SET lv_Minute_To_Wait_Evolution = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_MINUTE_TO_WAIT_EVOLUTION);
	
    
    /********************** CREAT TEMP TABLE ***********************************/
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceMapping;
	DROP TEMPORARY TABLE IF EXISTS Temp_TaggingDevice;
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceFingerprintAccount;
	DROP TEMPORARY TABLE IF EXISTS Temp_NewDevice;
    
	CREATE TEMPORARY TABLE Temp_DeviceMapping(
			TransID										BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	RawTransID									BIGINT UNSIGNED NOT NULL
		,	FP_DeviceID									BIGINT UNSIGNED DEFAULT 0
		,	FP_TaggingID								BIGINT UNSIGNED
		,	FP_FingerPrintID							BIGINT UNSIGNED
		,	FP_DeviceFingerprintAccountID				BIGINT UNSIGNED
		,	FP_DeviceFingerprintAccount_EvolutionID		BIGINT UNSIGNED
		,	FP_DeviceFingerprintAccountOldID			BIGINT UNSIGNED
        
		,	FP_DeviceFingerprintAccount_InsertedTime	TIMESTAMP
        
		,	FP_DeviceMappingID							BIGINT UNSIGNED DEFAULT 0
	);
    
	CREATE TEMPORARY TABLE Temp_TaggingDevice(
			FP_TaggingID								BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	FP_DeviceID									BIGINT UNSIGNED DEFAULT 0
	);
    
	CREATE TEMPORARY TABLE Temp_DeviceFingerprintAccount(
			FP_DeviceFingerprintAccountID				BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	FP_DeviceID									BIGINT UNSIGNED DEFAULT 0
	);
    
	CREATE TEMPORARY TABLE Temp_NewDevice(
			RawTransID									BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	SameDeviceWithRawTransID					BIGINT UNSIGNED DEFAULT 0
		,	FP_DeviceID									BIGINT UNSIGNED DEFAULT 0
        
		,	FP_TaggingID								BIGINT UNSIGNED
		,	FP_DeviceFingerprintAccountID				BIGINT UNSIGNED
	);
    
    /********************** Get Data ***********************************/
    INSERT IGNORE INTO Temp_DeviceMapping(TransID, RawTransID, FP_TaggingID, FP_FingerPrintID, FP_DeviceFingerprintAccountID, FP_DeviceFingerprintAccount_EvolutionID, FP_DeviceFingerprintAccount_InsertedTime, FP_DeviceFingerprintAccountOldID)
    SELECT 	trans.TransID
		,	trans.RawTransID
		,	IFNULL(trans.FP_TaggingID,0) AS FP_TaggingID
		,	IFNULL(trans.FP_FingerPrintID,0) AS FP_FingerPrintID
		,	IFNULL(dfa.ID,0) AS FP_DeviceFingerprintAccountID
		,	IFNULL(dfa.DeviceID,0) AS FP_DeviceFingerprintAccount_EvolutionID
		,	dfa.InsertedTime AS FP_DeviceFingerprintAccount_InsertedTime
		,	IFNULL(dfao.ID,0) AS FP_DeviceFingerprintAccountOldID
    FROM DCS_DataCenter.Transaction AS trans
		LEFT JOIN DCS_DataCenter.FP_DeviceFingerprintAccount AS dfa ON dfa.FP_FingerPrintID = trans.FP_FingerPrintID AND dfa.AccountID = trans.AccountID
		LEFT JOIN DCS_DataCenter.FP_DeviceFingerprintAccountOld AS dfao ON dfao.FP_FingerPrintOldID = trans.FP_FingerPrintOldID AND dfao.AccountID = trans.AccountID
    WHERE trans.TransID >= lv_Min_Transaction_TransID
    LIMIT ip_BatchSize;
    
    DELETE FROM Temp_DeviceMapping
    WHERE FP_TaggingID = 0
		AND FP_FingerPrintID = 0
		AND FP_DeviceFingerprintAccountID = 0
		AND FP_DeviceFingerprintAccount_EvolutionID = 0
		AND FP_DeviceFingerprintAccountOldID = 0;
    
    SET lv_Min_Transaction_TransID = (SELECT MIN(TransID) FROM Temp_DeviceMapping);
    
    -- Wait lv_Minute_To_Wait_Evolution minutes
    DELETE tmp
    FROM Temp_DeviceMapping AS tmp
    WHERE FP_DeviceFingerprintAccountID > 0
		AND FP_DeviceFingerprintAccount_EvolutionID = 0
		AND FP_DeviceFingerprintAccount_InsertedTime >= DATE_ADD(NOW(), INTERVAL (-1)*lv_Minute_To_Wait_Evolution MINUTE);
    
    
	ALTER TABLE Temp_DeviceMapping
	ADD INDEX IX_Temp_DeviceMapping_GroupIndex (FP_TaggingID, FP_FingerPrintID, FP_DeviceFingerprintAccountID, FP_DeviceFingerprintAccount_EvolutionID, FP_DeviceFingerprintAccountOldID);
    
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN DCS_DataCenter.FP_DeviceMapping AS dm ON dm.FP_TaggingID 							= tmp.FP_TaggingID
														AND dm.FP_FingerPrintID 						= tmp.FP_FingerPrintID
														AND dm.FP_DeviceFingerprintAccountID 			= tmp.FP_DeviceFingerprintAccountID
														AND dm.FP_DeviceFingerprintAccount_EvolutionID 	= tmp.FP_DeviceFingerprintAccount_EvolutionID
														AND dm.FP_DeviceFingerprintAccountOldID 		= tmp.FP_DeviceFingerprintAccountOldID
	SET tmp.FP_DeviceMappingID  = dm.ID,
		tmp.FP_DeviceID = dm.FP_DeviceID;
    
	ALTER TABLE Temp_DeviceMapping
	ADD INDEX IX_Temp_DeviceMapping_FP_DeviceMappingID (FP_DeviceMappingID);	
    
    /********************** Check Rule 1 ***********************************/
    INSERT INTO Temp_TaggingDevice(FP_TaggingID)
    SELECT DISTINCT FP_TaggingID
    FROM Temp_DeviceMapping
    WHERE FP_DeviceMappingID = 0
		AND FP_TaggingID > 0;
    
    UPDATE Temp_TaggingDevice AS tmp
		INNER JOIN DCS_DataCenter.FP_DeviceMapping AS dm ON dm.FP_TaggingID = tmp.FP_TaggingID
	SET tmp.FP_DeviceID = dm.FP_DeviceID;
    
    /********************** Update Temp ***********************************/
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_TaggingDevice AS tmpTg ON tmpTg.FP_TaggingID = tmp.FP_TaggingID
	SET tmp.FP_DeviceID = tmpTg.FP_DeviceID
    WHERE tmp.FP_DeviceMappingID = 0;
    
    
    /********************** Check Rule 3 ***********************************/
    INSERT INTO Temp_DeviceFingerprintAccount(FP_DeviceFingerprintAccountID)
    SELECT DISTINCT FP_DeviceFingerprintAccountID
    FROM Temp_DeviceMapping
    WHERE FP_DeviceMappingID = 0
		AND FP_DeviceFingerprintAccountID > 0
		AND FP_DeviceID = 0;
    
    UPDATE Temp_DeviceFingerprintAccount AS tmp
		INNER JOIN DCS_DataCenter.FP_DeviceMapping AS dm ON dm.FP_DeviceFingerprintAccountID = tmp.FP_DeviceFingerprintAccountID
	SET tmp.FP_DeviceID = dm.FP_DeviceID;
    
    /********************** Update Temp ***********************************/
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_DeviceFingerprintAccount AS tmpDfa ON tmpDfa.FP_DeviceFingerprintAccountID = tmp.FP_DeviceFingerprintAccountID
	SET tmp.FP_DeviceID = tmpDfa.FP_DeviceID
    WHERE tmp.FP_DeviceMappingID = 0
		AND tmp.FP_DeviceID = 0;
    
    
    /********************** INSERT INTO Temp_NewDevice ***********************************/
    INSERT INTO Temp_NewDevice(RawTransID, FP_TaggingID, FP_DeviceFingerprintAccountID)
    SELECT 	RawTransID
		,	FP_TaggingID
		,	FP_DeviceFingerprintAccountID
    FROM Temp_DeviceMapping
    WHERE FP_DeviceMappingID = 0
		AND FP_DeviceID = 0
		AND (FP_TaggingID > 0
			OR FP_DeviceFingerprintAccountID > 0);
    
    CALL DCS_DataCenter.DCS_DC_Transform_FP_DeviceMappingUpdateTheSameDevice('Temp_NewDevice');
    
    INSERT IGNORE INTO DCS_DataCenter.FP_Device(FirstRawTransID)
    SELECT DISTINCT SameDeviceWithRawTransID
    FROM Temp_NewDevice
    WHERE SameDeviceWithRawTransID > 0;
    
    UPDATE Temp_NewDevice AS tmp
		INNER JOIN DCS_DataCenter.FP_Device AS dv ON dv.FirstRawTransID = tmp.SameDeviceWithRawTransID
	SET tmp.FP_DeviceID = dv.ID;
    
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_NewDevice AS tmpNd ON tmpNd.RawTransID = tmp.RawTransID
	SET tmp.FP_DeviceID = tmpNd.FP_DeviceID
    WHERE tmp.FP_DeviceMappingID = 0
		AND tmp.FP_DeviceID = 0;
    
    INSERT IGNORE INTO DCS_DataCenter.FP_DeviceMapping(FP_TaggingID, FP_FingerPrintID, FP_DeviceFingerprintAccountID, FP_DeviceFingerprintAccount_EvolutionID, FP_DeviceFingerprintAccountOldID, FP_DeviceID, FirstRawTransID)
    SELECT 	FP_TaggingID
		,	FP_FingerPrintID
        ,	FP_DeviceFingerprintAccountID
        ,	FP_DeviceFingerprintAccount_EvolutionID
        ,	FP_DeviceFingerprintAccountOldID
        ,	MIN(FP_DeviceID) AS FP_DeviceID
        ,	MIN(RawTransID) AS FirstRawTransID
    FROM Temp_DeviceMapping
    WHERE FP_DeviceID > 0
    GROUP BY FP_TaggingID, FP_FingerPrintID, FP_DeviceFingerprintAccountID, FP_DeviceFingerprintAccount_EvolutionID, FP_DeviceFingerprintAccountOldID;
    
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN DCS_DataCenter.FP_DeviceMapping AS dm ON dm.FP_TaggingID 							= tmp.FP_TaggingID
														AND dm.FP_FingerPrintID 						= tmp.FP_FingerPrintID
														AND dm.FP_DeviceFingerprintAccountID 			= tmp.FP_DeviceFingerprintAccountID
														AND dm.FP_DeviceFingerprintAccount_EvolutionID 	= tmp.FP_DeviceFingerprintAccount_EvolutionID
														AND dm.FP_DeviceFingerprintAccountOldID 		= tmp.FP_DeviceFingerprintAccountOldID
	SET tmp.FP_DeviceMappingID  = dm.ID,
		tmp.FP_DeviceID = dm.FP_DeviceID
	WHERE tmp.FP_DeviceMappingID = 0;
    
    INSERT IGNORE INTO DCS_DataCenter.FP_TransactionDeviceMapping(RawTransID, FP_DeviceMappingID, FP_DeviceID)
    SELECT 	RawTransID
		,	FP_DeviceMappingID
		,	FP_DeviceID
    FROM Temp_DeviceMapping
    WHERE FP_DeviceID > 0;
    
    /*****UPDATE MaxTransID in SystemSetting****************************************************/    
    IF lv_Min_Transaction_TransID IS NOT NULL AND lv_Min_Transaction_TransID > 0 THEN
		UPDATE DCS_DataCenter.SystemSetting AS sys
		SET sys.VValue 	= CONCAT('', lv_Min_Transaction_TransID),
		    sys.UpdatedTime = lv_CurrentDate
		WHERE ID = CONST_MIN_TRANSACTION_TRANSID;
    END IF;
    
END$$

DELIMITER ;