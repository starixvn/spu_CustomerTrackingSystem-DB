/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_DeviceMapping_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_DeviceMapping_Insert`(
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
			CALL DCS_DC_Transform_DeviceMapping_Insert('50');
	*/
    DECLARE CONST_MINID_FP_DEVICEMAPPING	INT DEFAULT 24;
    
    DECLARE lv_CurrentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	DECLARE lv_Min_FP_DeviceMappingID  	BIGINT UNSIGNED;
    
	SET lv_Min_FP_DeviceMappingID = (SELECT CAST(VValue AS UNSIGNED) FROM DCS_DataCenter.SystemSetting WHERE ID = CONST_MINID_FP_DEVICEMAPPING);
	
    
    /********************** CREAT TEMP TABLE ***********************************/
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceMapping;
	DROP TEMPORARY TABLE IF EXISTS Temp_TaggingDevice;
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceFingerprintAccount;
	DROP TEMPORARY TABLE IF EXISTS Temp_NewDevice;
    
	CREATE TEMPORARY TABLE Temp_DeviceMapping(
			RawTransID									BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	FP_DeviceID									BIGINT UNSIGNED DEFAULT 0
		,	FP_TaggingID								BIGINT UNSIGNED
		,	FP_FingerPrintID							BIGINT UNSIGNED
		,	FP_DeviceFingerprintAccountID				BIGINT UNSIGNED
		,	FP_DeviceFingerprintAccount_EvolutionID		BIGINT UNSIGNED
		,	FP_DeviceFingerprintAccountOldID			BIGINT UNSIGNED
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
		,	SameDeviceWithRawTransID					BIGINT UNSIGNED
		,	FP_DeviceID									BIGINT UNSIGNED DEFAULT 0
        
		,	FP_TaggingID								BIGINT UNSIGNED
		,	FP_DeviceFingerprintAccountID				BIGINT UNSIGNED
	);
    
    /********************** Get Data ***********************************/
    INSERT IGNORE INTO Temp_DeviceMapping(RawTransID, FP_TaggingID, FP_FingerPrintID, FP_DeviceFingerprintAccountID, FP_DeviceFingerprintAccount_EvolutionID, FP_DeviceFingerprintAccountOldID)
    SELECT 	trans.RawTransID
		,	trans.FP_TaggingID
		,	trans.FP_FingerPrintID
		,	dfa.ID AS FP_DeviceFingerprintAccountID
		,	dfa.DeviceID AS FP_DeviceFingerprintAccount_EvolutionID
		,	dfao.ID AS FP_DeviceFingerprintAccountOldID
    FROM DCS_DataCenter.Transaction AS trans
		LEFT JOIN DCS_DataCenter.FP_DeviceFingerprintAccount AS dfa ON dfa.FP_FingerPrintID = trans.FP_FingerPrintID AND dfa.AccountID = trans.AccountID
		LEFT JOIN DCS_DataCenter.FP_DeviceFingerprintAccountOld AS dfao ON dfao.FP_FingerPrintOldID = trans.FP_FingerPrintOldID AND dfao.AccountID = trans.AccountID
    WHERE trans.TransID > lv_Min_FP_DeviceMappingID
    LIMIT ip_BatchSize;
    
    DELETE tmp
    FROM Temp_DeviceMapping AS tmp
		INNER JOIN DCS_DataCenter.FP_DeviceMapping AS dm ON dm.FP_TaggingID 							= tmp.FP_TaggingID
														AND dm.FP_FingerPrintID 						= tmp.FP_FingerPrintID
														AND dm.FP_DeviceFingerprintAccountID 			= tmp.FP_DeviceFingerprintAccountID
														AND dm.FP_DeviceFingerprintAccount_EvolutionID 	= tmp.FP_DeviceFingerprintAccount_EvolutionID
														AND dm.FP_DeviceFingerprintAccountOldID 		= tmp.FP_DeviceFingerprintAccountOldID;
	
    /********************** Check Rule 1 ***********************************/
    INSERT INTO Temp_TaggingDevice(FP_TaggingID)
    SELECT DISTINCT FP_TaggingID
    FROM Temp_DeviceMapping;
    
    UPDATE Temp_TaggingDevice AS tmp
		INNER JOIN DCS_DataCenter.FP_DeviceMapping AS dm ON dm.FP_TaggingID = tmp.FP_TaggingID
	SET tmp.FP_DeviceID = dm.FP_DeviceID;
    
    /********************** Update ***********************************/
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_TaggingDevice AS tmpTg ON tmpTg.FP_TaggingID = tmp.FP_TaggingID
	SET tmp.FP_DeviceID = tmpTg.FP_DeviceID;
    
    
    /********************** Check Rule 3 ***********************************/
    INSERT INTO Temp_DeviceFingerprintAccount(FP_DeviceFingerprintAccountID)
    SELECT DISTINCT FP_DeviceFingerprintAccountID
    FROM Temp_DeviceMapping
    WHERE FP_DeviceID = 0;
    
    UPDATE Temp_DeviceFingerprintAccount AS tmp
		INNER JOIN DCS_DataCenter.FP_DeviceMapping AS dm ON dm.FP_DeviceFingerprintAccountID = tmp.FP_DeviceFingerprintAccountID
	SET tmp.FP_DeviceID = dm.FP_DeviceID;
    
    /********************** Update ***********************************/
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_DeviceFingerprintAccount AS tmpDfa ON tmpDfa.FP_DeviceFingerprintAccountID = tmp.FP_DeviceFingerprintAccountID
	SET tmp.FP_DeviceID = tmpDfa.FP_DeviceID
    WHERE tmp.FP_DeviceID = 0;
    
    
    /********************** INSERT INTO Temp_NewDevice ***********************************/
    INSERT INTO Temp_NewDevice(RawTransID, FP_TaggingID, FP_DeviceFingerprintAccountID)
    SELECT 	RawTransID
		,	FP_TaggingID
		,	FP_DeviceFingerprintAccountID
    FROM Temp_DeviceMapping
    WHERE FP_DeviceID = 0;
    
    CALL DCS_DataCenter.DCS_DC_Transform_DeviceMapping_UpdateTheSameDevice('Temp_NewDevice');
    
    INSERT IGNORE INTO DCS_DataCenter.FP_Device(FirstRawTransID)
    SELECT DISTINCT SameDeviceWithRawTransID
    FROM Temp_NewDevice;
    
    UPDATE Temp_NewDevice AS tmp
		INNER JOIN DCS_DataCenter.FP_Device AS dv ON dv.FirstRawTransID = tmp.SameDeviceWithRawTransID
	SET tmp.FP_DeviceID = dv.ID;
    
    SELECT *
    FROM Temp_NewDevice;
    
    UPDATE Temp_DeviceMapping AS tmp
		INNER JOIN Temp_NewDevice AS tmpNd ON tmpNd.RawTransID = tmp.RawTransID
	SET tmp.FP_DeviceID = tmpNd.FP_DeviceID
    WHERE tmp.FP_DeviceID = 0;
    
    SELECT *
    FROM Temp_DeviceMapping;
    
END$$

DELIMITER ;


			CALL DCS_DC_Transform_DeviceMapping_Insert('50');