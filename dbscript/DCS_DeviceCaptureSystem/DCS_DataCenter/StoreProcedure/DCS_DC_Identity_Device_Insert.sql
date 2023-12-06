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
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Identity_Device_Insert('32,39');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
    DECLARE lv_DeviceFingerPrintJson LONGTEXT;
    DECLARE lv_DeviceCookieJson LONGTEXT;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionInfo;
    
	CREATE TEMPORARY TABLE Temp_InputTrans(
		TransID		BIGINT UNSIGNED PRIMARY KEY
	);
    
	CREATE TEMPORARY TABLE Temp_TransactionInfo(
			TransID					BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	RawFingerPrintID		BIGINT UNSIGNED
		,	CookieID				BIGINT UNSIGNED
		,	AccountID				BIGINT UNSIGNED
		,	BrowserInstanceID		BIGINT UNSIGNED
		,	DeviceID				BIGINT UNSIGNED
		,	RecoverType				TINYINT DEFAULT 0
	);
    
    SET @sql = CONCAT("INSERT INTO Temp_InputTrans (TransID) VALUES ('", REPLACE(ip_TransIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT INTO Temp_TransactionInfo(TransID, RawFingerPrintID, CookieID, AccountID, BrowserInstanceID)
    SELECT	trans.TransID
		,	trans.RawFingerPrintID
        ,	trans.CookieID
        ,	trans.AccountID
        ,	trans.BrowserInstanceID
    FROM Temp_InputTrans AS tmp
		INNER JOIN DCS_DataCenter.Transaction AS trans ON trans.TransID = tmp.TransID
	WHERE trans.RawFingerPrintID IS NOT NULL;
    
    /* === Add index === */
	ALTER TABLE Temp_TransactionInfo
	ADD INDEX IX_Temp_TransactionInfo_RawFingerPrintID (RawFingerPrintID);
    
    /******* Update Temp_TransactionInfo: DeviceID & RecoverType ********************/
    CALL DCS_DC_Identity_Device_UpdateExistsDeviceID('Temp_TransactionInfo');
    
    /* === Insert new Device === */
    INSERT IGNORE INTO DCS_DataCenter.FPDevice(FirstRawFingerPrintID, CreatedDate)
	SELECT 	DISTINCT 
			RawFingerPrintID
		,	lv_CreatedDate
	FROM Temp_TransactionInfo
    WHERE DeviceID IS NULL;
    
    /* === Update new DeviceID === */
    UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_DataCenter.FPDevice AS d ON tmp.RawFingerPrintID = d.FirstRawFingerPrintID
	SET tmp.DeviceID = d.ID;

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
		WHERE RecoverType in (0,2)
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
    
    /* === Insert new DeviceCookie === */
    WITH cte_DistinctData AS (
		SELECT 	DISTINCT
				CookieID
			,	DeviceID
		FROM Temp_TransactionInfo
		WHERE RecoverType in (0,1)
			AND CookieID IS NOT NULL
    )
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
				'CookieID', CookieID,
				'DeviceID', DeviceID
			)
		) AS json_data
	INTO lv_DeviceCookieJson
	FROM cte_DistinctData;
    
    SET lv_DeviceCookieJson = IFNULL(lv_DeviceCookieJson,'[{}]');
	CALL DCS_DC_Identity_DeviceCookie_Insert(lv_DeviceCookieJson);

END$$

DELIMITER ;