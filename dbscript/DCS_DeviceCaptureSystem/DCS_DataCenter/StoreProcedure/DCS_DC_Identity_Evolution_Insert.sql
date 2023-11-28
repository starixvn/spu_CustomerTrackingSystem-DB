/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Evolution_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_Evolution_Insert`(
    IN ip_TransJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231127@Jonathan.Doan
	    Task : Evolution Insert
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
			- 20231127@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Identity_Evolution_Insert('[{"TransID":7,"RecoverRawFingerPrintID":11}]');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionInfo;
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceFingerPrint;
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCookie;
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionEvolution;
    
	CREATE TEMPORARY TABLE Temp_TransactionInfo(
			TransID								BIGINT UNSIGNED PRIMARY KEY
        ,	RawFingerPrintID					BIGINT UNSIGNED
        ,	RecoverRawFingerPrintID				BIGINT UNSIGNED
        ,	DeviceID							BIGINT UNSIGNED
        ,	CookieID							BIGINT UNSIGNED
	);
    
	CREATE TEMPORARY TABLE Temp_DeviceFingerPrint(
			ID									INT UNSIGNED AUTO_INCREMENT	PRIMARY KEY 
        ,	RawFingerPrintID					BIGINT UNSIGNED
        ,	DeviceID							BIGINT UNSIGNED
	);
    
	CREATE TEMPORARY TABLE Temp_DeviceCookie(
			ID									INT UNSIGNED AUTO_INCREMENT	PRIMARY KEY 
        ,	CookieID							BIGINT UNSIGNED
        ,	DeviceID							BIGINT UNSIGNED
	);
    
	CREATE TEMPORARY TABLE Temp_TransactionEvolution(
			RawFingerPrintID					BIGINT UNSIGNED PRIMARY KEY
        ,	RecoverRawFingerPrintID				BIGINT UNSIGNED
        ,	DeviceID							BIGINT UNSIGNED
	);
    
	INSERT INTO Temp_TransactionInfo(TransID, RecoverRawFingerPrintID)
	SELECT	tmp.TransID
		,	tmp.RecoverRawFingerPrintID
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
						TransID					BIGINT UNSIGNED			PATH "$.TransID",
						RecoverRawFingerPrintID	BIGINT UNSIGNED			PATH "$.RecoverRawFingerPrintID"
				)
		   ) AS tmp;

	UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_DataCenter.Transaction AS trans ON trans.TransID = tmp.TransID
	SET tmp.RawFingerPrintID = trans.RawFingerPrintID
    ,	tmp.CookieID = trans.CookieID;
    
    /* === Add index === */
	ALTER TABLE Temp_TransactionInfo
	ADD INDEX IX_Temp_TransactionInfo_RawFingerPrintID (RawFingerPrintID);
    
	UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_DataCenter.FPDeviceFingerPrint AS df ON df.RawFingerPrintID = tmp.RecoverRawFingerPrintID
	SET tmp.DeviceID = df.DeviceID;
    
    DELETE FROM Temp_TransactionInfo WHERE DeviceID IS NULL;
    
    /* === Insert new FPDeviceFingerPrint === */
    INSERT INTO Temp_DeviceFingerPrint(RawFingerPrintID, DeviceID)
    SELECT	DISTINCT
			RawFingerPrintID
		,	DeviceID
	FROM Temp_TransactionInfo
	WHERE RawFingerPrintID IS NOT NULL;
    
    CALL DCS_DC_Identity_DeviceFingerPrint_Insert('Temp_DeviceFingerPrint');
    
    /* === Insert new DeviceCookie === */
    INSERT INTO Temp_DeviceCookie(CookieID, DeviceID)
    SELECT	DISTINCT
			CookieID
		,	DeviceID
	FROM Temp_TransactionInfo
	WHERE CookieID IS NOT NULL;
    
    CALL DCS_DC_Identity_DeviceCookie_Insert('Temp_DeviceCookie');
    
    /* === Insert new TransactionEvolution === */
    INSERT IGNORE INTO Temp_TransactionEvolution(RawFingerPrintID, RecoverRawFingerPrintID, DeviceID)
    SELECT	RawFingerPrintID
		,	RecoverRawFingerPrintID
		,	DeviceID
	FROM Temp_TransactionInfo
	WHERE RawFingerPrintID IS NOT NULL;
    
    CALL DCS_DC_Identity_TransactionEvolution_Insert('Temp_TransactionEvolution');
        
END$$

DELIMITER ;
