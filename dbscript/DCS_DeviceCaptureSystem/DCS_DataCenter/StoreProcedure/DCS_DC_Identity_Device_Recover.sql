/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Device_Recover`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_Device_Recover`(
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
			CALL DCS_DC_Identity_Device_Recover('6,7,32,42,45,46,54,57');
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
	ADD INDEX IX_Temp_TransactionInfo_AccountID (AccountID),
	ADD INDEX IX_Temp_TransactionInfo_RecoverType (RecoverType);
    
    /******* Update Temp_TransactionInfo: DeviceID & RecoverType ********************/
    CALL DCS_DC_Identity_Device_UpdateExistsDeviceID('Temp_TransactionInfo');
    
    
    /* Return list trans that can recover */
    SELECT 	TransID
		,	DeviceID AS FPDeviceID
		,	RecoverType
    FROM Temp_TransactionInfo
    WHERE DeviceID IS NOT NULL;
    
    INSERT INTO Temp_GroupRawFingerPrintByAccount(TransID, RawFingerPrintIDs)
	SELECT 	tmp.TransID
		,	GROUP_CONCAT(af.RawFingerPrintID) AS RawFingerPrintIDs
	FROM Temp_TransactionInfo AS tmp
		INNER JOIN DCS_DataCenter.AccountFingerprint AS af ON af.AccountID = tmp.AccountID
	WHERE af.IsEvolution = 0
		AND af.RawFingerPrintID != tmp.RawFingerPrintID
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
