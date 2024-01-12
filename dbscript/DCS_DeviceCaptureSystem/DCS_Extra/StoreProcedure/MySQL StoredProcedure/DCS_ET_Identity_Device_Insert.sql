/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Identity_Device_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Identity_Device_Insert`(
    IN ip_TransIDs	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231205@Jonathan.Doan
	    Task : Identity Device
	    DB: DCS_Extra
	    Original:
		 
	    Revisions:
			- 20231205@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_ET_Identity_Device_Insert('32,39');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
    DECLARE lv_DeviceFingerPrintJson LONGTEXT;
    DECLARE lv_DeviceCookieJson LONGTEXT;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionInfo;
	DROP TEMPORARY TABLE IF EXISTS Temp_DistinctRawFingerPrint;
	DROP TEMPORARY TABLE IF EXISTS Temp_DistinctCookie;
    
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
    
	CREATE TEMPORARY TABLE Temp_DistinctRawFingerPrint(
			FirstRawFingerPrintID	BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	FirstCookieID			BIGINT UNSIGNED
	);
    
	CREATE TEMPORARY TABLE Temp_DistinctCookie(
			FirstCookieID			BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	IsNewRecord				TINYINT	DEFAULT 1
	);
    
    SET @sql = CONCAT("INSERT INTO Temp_InputTrans (TransID) VALUES ('", REPLACE(ip_TransIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT INTO Temp_TransactionInfo(TransID, RawFingerPrintID, CookieID, AccountID, BrowserInstanceID)
    SELECT	trans.TransID
		,	IFNULL(trans.RawFingerPrintID, 0) AS RawFingerPrintID
        ,	IFNULL(trans.CookieID, 0) AS CookieID
        ,	trans.AccountID
        ,	trans.BrowserInstanceID
    FROM Temp_InputTrans AS tmp
		INNER JOIN DCS_Extra.Transaction AS trans ON trans.TransID = tmp.TransID;
    
    /* === Add index === */
	ALTER TABLE Temp_TransactionInfo
	ADD INDEX IX_Temp_TransactionInfo_RawFingerPrintID (RawFingerPrintID);
    
    /******* Update Temp_TransactionInfo: DeviceID & RecoverType ********************/
    CALL DCS_ET_Identity_Device_UpdateExistsDeviceID('Temp_TransactionInfo');
    
    /* GROUP BY FPID, min CookieID */
    INSERT INTO Temp_DistinctRawFingerPrint(FirstRawFingerPrintID, FirstCookieID)
    SELECT	RawFingerPrintID AS FirstRawFingerPrintID
		,	MIN(CookieID) AS FirstCookieID
    FROM Temp_TransactionInfo
    WHERE DeviceID IS NULL
		AND RawFingerPrintID > 0
		AND CookieID > 0
    GROUP BY RawFingerPrintID;
    
    INSERT IGNORE INTO Temp_DistinctRawFingerPrint(FirstRawFingerPrintID, FirstCookieID)
    SELECT	RawFingerPrintID AS FirstRawFingerPrintID
		,	0 AS FirstCookieID
    FROM Temp_TransactionInfo
    WHERE DeviceID IS NULL
		AND RawFingerPrintID > 0
		AND CookieID = 0
    GROUP BY RawFingerPrintID;
    
    /* Insert into FPDevice */
    INSERT IGNORE INTO DCS_Extra.FPDevice(FirstRawFingerPrintID, FirstCookieID, CreatedDate)
	SELECT 	FirstRawFingerPrintID
		,	FirstCookieID
		,	lv_CreatedDate
	FROM Temp_DistinctRawFingerPrint;
    
    /* Update deviceID by RawFingerPrintID */
    UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_Extra.FPDevice AS d ON d.FirstRawFingerPrintID = tmp.RawFingerPrintID
	SET tmp.DeviceID = d.ID
    WHERE tmp.DeviceID IS NULL;
    
    /* Insert into FPDevice if DeviceID IS NULL AND CookieID > 0 (Group by CookieID)*/
    INSERT INTO Temp_DistinctCookie(FirstCookieID)
	SELECT 	DISTINCT 
			CookieID AS FirstCookieID
	FROM Temp_TransactionInfo
    WHERE DeviceID IS NULL
		AND RawFingerPrintID = 0
        AND CookieID > 0;
        
	UPDATE Temp_DistinctCookie AS tmp
		INNER JOIN DCS_Extra.FPDevice AS d ON d.FirstCookieID = tmp.FirstCookieID
    SET tmp.IsNewRecord = 0;
    
    INSERT IGNORE INTO DCS_Extra.FPDevice(FirstRawFingerPrintID, FirstCookieID, CreatedDate)
	SELECT 	DISTINCT 
			0 AS FirstRawFingerPrintID
		,	FirstCookieID
		,	lv_CreatedDate
	FROM Temp_DistinctCookie
    WHERE IsNewRecord = 1;
    
    /* Update deviceID by CookieID (DeviceID IS NULL) */
    UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_Extra.FPDevice AS d ON d.FirstCookieID = tmp.CookieID
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
	CALL DCS_ET_Identity_DeviceFingerPrint_Insert(lv_DeviceFingerPrintJson);
    
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
	CALL DCS_ET_Identity_DeviceCookie_Insert(lv_DeviceCookieJson);

END$$

DELIMITER ;