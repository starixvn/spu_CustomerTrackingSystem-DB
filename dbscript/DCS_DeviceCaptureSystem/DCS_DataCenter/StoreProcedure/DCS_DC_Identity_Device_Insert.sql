/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Device_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_Device_Insert`(
    IN ip_TransIDs	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231124@Jonathan.Doan
	    Task : Identity Device
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
			- 20240126@Jonathan.Doan: HF for case RawFingerPrintID and CookieID Null [Redmine: 200335]
			- 20240627@Jonathan.Doan: Change data flow v5.1 [Redmine ID: #206403]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Identity_Device_Insert('32,39');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
    DECLARE lv_DeviceFingerPrintJson LONGTEXT;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionInfo;
    
	CREATE TEMPORARY TABLE Temp_InputTrans(
		TransID		BIGINT UNSIGNED PRIMARY KEY
	);
    
	CREATE TEMPORARY TABLE Temp_TransactionInfo(
			TransID					BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	RawFingerPrintID		BIGINT UNSIGNED
		,	AccountID				BIGINT UNSIGNED
		,	BrowserInstanceID		BIGINT UNSIGNED
		,	DeviceID				BIGINT UNSIGNED
		,	RecoverType				TINYINT DEFAULT 0
	);
    
    SET @sql = CONCAT("INSERT INTO Temp_InputTrans (TransID) VALUES ('", REPLACE(ip_TransIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT INTO Temp_TransactionInfo(TransID, RawFingerPrintID, AccountID, BrowserInstanceID)
    SELECT	trans.TransID
		,	IFNULL(trans.RawFingerPrintID, 0) AS RawFingerPrintID
        ,	trans.AccountID
        ,	trans.BrowserInstanceID
    FROM Temp_InputTrans AS tmp
		INNER JOIN DCS_DataCenter.Transaction AS trans ON trans.TransID = tmp.TransID;
    
    /* === Add index === */
	ALTER TABLE Temp_TransactionInfo
	ADD INDEX IX_Temp_TransactionInfo_RawFingerPrintID (RawFingerPrintID);
    
    /******* Update Temp_TransactionInfo: DeviceID & RecoverType ********************/
    CALL DCS_DC_Identity_Device_UpdateExistsDeviceID('Temp_TransactionInfo');
    
    /* INSERT INTO FPDevice */
    INSERT IGNORE INTO DCS_DataCenter.FPDevice(FirstRawFingerPrintID, FirstCookieID, CreatedDate)
    SELECT	DISTINCT 
			RawFingerPrintID AS FirstRawFingerPrintID
		,	0 AS FirstCookieID
		,	lv_CreatedDate
    FROM Temp_TransactionInfo
    WHERE DeviceID IS NULL
		AND RawFingerPrintID > 0;
    
    /* Update deviceID by RawFingerPrintID */
    UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_DataCenter.FPDevice AS d ON d.FirstRawFingerPrintID = tmp.RawFingerPrintID AND tmp.RawFingerPrintID != 0
	SET tmp.DeviceID = d.ID
    WHERE tmp.DeviceID IS NULL;
    
    /* === Return data === */
    SELECT 	TransID
		,	DeviceID AS FPDeviceID
		,	RecoverType
    FROM Temp_TransactionInfo;
    
    /* === Insert new FPDeviceFingerPrint === */
    WITH cte_DistinctData AS (
		SELECT 	DISTINCT
				RawFingerPrintID
			,	DeviceID
		FROM Temp_TransactionInfo
		WHERE RecoverType = 0
			AND RawFingerPrintID IS NOT NULL
    )
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
				'RawFingerPrintID', RawFingerPrintID,
				'DeviceID', DeviceID
			)
		) AS json_data
	INTO lv_DeviceFingerPrintJson
	FROM cte_DistinctData;
    
    SET lv_DeviceFingerPrintJson = IFNULL(lv_DeviceFingerPrintJson,'[{}]');
	CALL DCS_DC_Identity_DeviceFingerPrint_Insert(lv_DeviceFingerPrintJson);
    
END$$

DELIMITER ;