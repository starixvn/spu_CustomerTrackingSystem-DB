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
			CALL DCS_DC_Identity_Device_Insert('6,7');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionInfo;
	DROP TEMPORARY TABLE IF EXISTS Temp_AccountFingerprint;
    
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
    
	CREATE TEMPORARY TABLE Temp_AccountFingerprint(
			ID							INT UNSIGNED AUTO_INCREMENT		PRIMARY KEY 
        ,	AccountID					BIGINT UNSIGNED 				
        ,	RawFingerPrintID			BIGINT UNSIGNED
		,	IsNewAccountFingerprint		TINYINT DEFAULT 1
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
    FROM Temp_TransactionInfo;
    
    
    /* === Update new FPDeviceFingerPrint === */
	INSERT IGNORE INTO DCS_DataCenter.FPDeviceFingerPrint(RawFingerPrintID, DeviceID, CreatedDate)
	SELECT 	DISTINCT
			RawFingerPrintID
		,	DeviceID
		,	lv_CreatedDate
	FROM Temp_TransactionInfo
	WHERE RecoverType in (0,2);
    
    /* === Update new DeviceCookie === */
	INSERT IGNORE INTO DCS_DataCenter.DeviceCookie(CookieID, DeviceID, CreatedDate)
	SELECT 	DISTINCT
			CookieID
		,	DeviceID
		,	lv_CreatedDate
	FROM Temp_TransactionInfo
	WHERE RecoverType in (0,1)
		AND CookieID IS NOT NULL;
    
    -- /******* Insert into AccountFingerPrint ********************/
--     CALL DCS_DC_Identity_AccountFingerPrint_Insert('Temp_TransactionInfo');
    
END$$

DELIMITER ;
