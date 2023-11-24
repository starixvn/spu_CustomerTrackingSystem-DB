/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Device_Recover_Jonathan`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_Device_Recover_Jonathan`(
    IN ip_TransIDs	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231124@Jonathan.Doan
	    Task : Recover Device
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Identity_Device_Recover_Jonathan('6,7');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionInfo;
    DROP TEMPORARY TABLE IF EXISTS Temp_GroupRawFingerPrintByAccount;
    
	CREATE TEMPORARY TABLE Temp_InputTrans(
			TransID					BIGINT UNSIGNED NOT NULL PRIMARY KEY
	);
    
	CREATE TEMPORARY TABLE Temp_TransactionInfo(
			TransID					BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	RawFingerPrintID		BIGINT UNSIGNED
		,	CookieID				BIGINT UNSIGNED
		,	DeviceID				BIGINT UNSIGNED
		,	AccountID				BIGINT UNSIGNED
		,	BrowserInstanceID		BIGINT UNSIGNED
		,	RecoverType				TINYINT DEFAULT 0
	);
    
    CREATE TEMPORARY TABLE Temp_GroupRawFingerPrintByAccount(
			TransID 				BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	RawFingerPrintIDs		LONGTEXT
    );
    
    SET @sql = CONCAT("INSERT INTO Temp_InputTrans (TransID) VALUES ('", REPLACE(ip_TransIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT INTO Temp_TransactionInfo(TransID, RawFingerPrintID, CookieID, AccountID, BrowserInstanceID)
    SELECT	tmp.TransID
		,	trans.RawFingerPrintID
		,	trans.CookieID
		,	trans.AccountID
		,	trans.BrowserInstanceID
    FROM Temp_InputTrans AS tmp
		INNER JOIN DCS_DataCenter.Transaction AS trans ON trans.TransID = tmp.TransID;
    
    /* === Add index === */
	ALTER TABLE Temp_TransactionInfo
	ADD INDEX IX_Temp_TransactionInfo_RawFingerPrintID (RawFingerPrintID),
	ADD INDEX IX_Temp_TransactionInfo_CookieID (CookieID),
	ADD INDEX IX_Temp_TransactionInfo_RecoverType (RecoverType);
    
    /* === Recover by RawFingerPrintID === */
    UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_DataCenter.FPDeviceFingerPrint AS df ON tmp.RawFingerPrintID = df.RawFingerPrintID
	SET 	tmp.DeviceID = df.DeviceID
		,	tmp.RecoverType = 1;
    
    /* === Recover by CookieID === */
    UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_DataCenter.DeviceCookie AS dc ON tmp.CookieID = dc.CookieID
	SET 	tmp.DeviceID = dc.DeviceID
		,	tmp.RecoverType = tmp.RecoverType + 2;
    
    
    /* === Insert new FPDeviceFingerPrint === */
    INSERT IGNORE INTO DCS_DataCenter.FPDeviceFingerPrint(RawFingerPrintID, DeviceID, CreatedDate)
	WITH cte AS
	(
		SELECT 	DISTINCT
				RawFingerPrintID
			,	DeviceID
		FROM Temp_TransactionInfo
        WHERE RecoverType = 2
	)
	SELECT 	cte.RawFingerPrintID
		,	cte.DeviceID
		,	lv_CreatedDate
	FROM cte;
    
    /* === Insert new DeviceCookie === */
    INSERT IGNORE INTO DCS_DataCenter.DeviceCookie(CookieID, DeviceID, CreatedDate)
	WITH cte AS
	(
		SELECT 	DISTINCT
				CookieID
			,	DeviceID
		FROM Temp_TransactionInfo
        WHERE RecoverType = 1
	)
	SELECT 	cte.CookieID
		,	cte.DeviceID
		,	lv_CreatedDate
	FROM cte;
    
    -- /* === Insert new Device === */
--     INSERT IGNORE INTO DCS_DataCenter.FPDevice(FirstRawFingerPrintId, CreatedDate)
-- 	WITH cte AS
-- 	(
-- 		SELECT DISTINCT RawFingerPrintId
-- 		FROM Temp_TransactionInfo
-- 		WHERE DeviceID IS NULL
-- 	)
-- 	SELECT 	cte.RawFingerPrintId
-- 		,	lv_CreatedDate
-- 	FROM cte;
--     
--     
--     /* === Update new DeviceID === */
--     UPDATE Temp_TransactionInfo AS tmp
-- 		INNER JOIN DCS_DataCenter.FPDevice AS d ON tmp.RawFingerPrintID = d.RawFingerPrintID
-- 	SET tmp.DeviceID = dc.DeviceID
--     WHERE tmp.DeviceID IS NULL;
--     
--     /* === Update new FPDeviceFingerPrint === */
-- 	INSERT IGNORE INTO DCS_DataCenter.FPDeviceFingerPrint(RawFingerPrintID, DeviceID, CreatedDate)
-- 	WITH cte AS
-- 	(
-- 		SELECT 	DISTINCT
-- 				RawFingerPrintID
-- 			,	DeviceID
-- 		FROM Temp_TransactionInfo
--         WHERE RecoverType = 0
-- 			AND DeviceID IS NOT NULL
-- 	)
-- 	SELECT 	cte.RawFingerPrintID
-- 		,	cte.DeviceID
-- 		,	lv_CreatedDate
-- 	FROM cte;
--     
--     /* === Update new DeviceCookie === */
-- 	INSERT IGNORE INTO DCS_DataCenter.DeviceCookie(CookieID, DeviceID, CreatedDate)
-- 	WITH cte AS
-- 	(
-- 		SELECT 	DISTINCT
-- 				CookieID
-- 			,	DeviceID
-- 		FROM Temp_TransactionInfo
--         WHERE RecoverType = 0
-- 			AND DeviceID IS NOT NULL
-- 	)
-- 	SELECT 	cte.CookieID
-- 		,	cte.DeviceID
-- 		,	lv_CreatedDate
-- 	FROM cte;
    
    
    /* Return list trans that can recover */
    SELECT 	TransID
		,	DeviceID AS FPDeviceID
    FROM Temp_TransactionInfo
    WHERE DeviceID IS NOT NULL;
    
    INSERT INTO Temp_GroupRawFingerPrintByAccount(TransID, RawFingerPrintIDs)
	SELECT 	tmp.TransID
		,	GROUP_CONCAT(af.RawFingerPrintID) AS RawFingerPrintIDs
	FROM Temp_TransactionInfo AS tmp
		INNER JOIN DCS_DataCenter.AccountFingerprint AS af ON af.AccountID = tmp.AccountID
	WHERE af.IsEvolution = 0
    GROUP BY tmp.TransID;
    
    /* Return list trans that cannot recover */
    SELECT 	tmp.TransID
		,	tmp.RawFingerPrintID
		,	tmpG.RawFingerPrintIDs
		,	bis.UserAgent
		,	bis.BrowserFamilyCode
		,	bis.OSName
		,	bis.BrowserName
		,	bis.BrowserVersion
		,	bis.Platform
		,	bis.Accept
		,	bis.Encoding
		,	bis.Headers
		,	fpa.LocalStorage
		,	fpa.DoNotTrack
		,	fpa.Cookies
		,	fpa.Canvas
		,	fpa.Fonts
		,	fpa.Vendor
		,	fpa.GLRenderer
		,	fpa.Plugins
		,	fpa.Languages
		,	fpa.Resolution
		,	fpa.Timezone
	FROM Temp_TransactionInfo AS tmp
 		LEFT JOIN Temp_GroupRawFingerPrintByAccount AS tmpG ON tmpG.TransID = tmp.TransID
 		LEFT JOIN DCS_DataCenter.FingerPrintAttribute AS fpa ON fpa.RawFingerPrintID = tmp.RawFingerPrintID
		LEFT JOIN DCS_DataCenter.BrowserInstanceRawFingerPrint AS bisa ON bisa.RawFingerPrintID = tmp.RawFingerPrintID AND bisa.BrowserInstanceID = tmp.BrowserInstanceID
		LEFT JOIN DCS_DataCenter.BrowserInstance AS bis ON bis.ID = bisa.BrowserInstanceID
    WHERE tmp.DeviceID IS NULL;
    
END$$

DELIMITER ;
