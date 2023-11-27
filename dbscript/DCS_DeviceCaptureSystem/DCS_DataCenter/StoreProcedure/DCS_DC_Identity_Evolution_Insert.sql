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
			CALL DCS_DC_Identity_Evolution_Insert('[{"TransID":10,"RawFingerPrintID":10,"RecoverRawFingerPrintID":1}]');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionInfo;    
	CREATE TEMPORARY TABLE Temp_TransactionInfo(
			TransID								BIGINT UNSIGNED PRIMARY KEY
        ,	RawFingerPrintID					BIGINT UNSIGNED
        ,	RecoverRawFingerPrintID				BIGINT UNSIGNED
        ,	DeviceID							BIGINT UNSIGNED
        ,	CookieID							BIGINT UNSIGNED
	);
    
	INSERT INTO Temp_TransactionInfo(TransID, RawFingerPrintID, RecoverRawFingerPrintID)
	SELECT	tmp.TransID
		,	tmp.RawFingerPrintID
		,	tmp.RecoverRawFingerPrintID
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
						TransID					BIGINT UNSIGNED			PATH "$.TransID",
						RawFingerPrintID		BIGINT UNSIGNED			PATH "$.RawFingerPrintID",
						RecoverRawFingerPrintID	BIGINT UNSIGNED			PATH "$.RecoverRawFingerPrintID"
				)
		   ) AS tmp;

	UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_DataCenter.Transaction AS trans ON trans.TransID = tmp.TransID
	SET tmp.CookieID = trans.CookieID;
        
    /* === Add index === */
	ALTER TABLE Temp_TransactionInfo
	ADD INDEX IX_Temp_TransactionInfo_RawFingerPrintID (RawFingerPrintID);
    
	UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_DataCenter.FPDeviceFingerPrint AS df ON tmp.RecoverFingerPrintID = df.RawFingerPrintID
	SET tmp.DeviceID = df.DeviceID;
    
    DELETE FROM Temp_TransactionInfo WHERE DeviceID IS NULL;
    
    /* === Insert new FPDeviceFingerPrint === */
    INSERT IGNORE INTO DCS_DataCenter.FPDeviceFingerPrint(RawFingerPrintID, DeviceID, CreatedDate)
	SELECT 	DISTINCT
			RawFingerPrintID
		,	DeviceID
		,	lv_CreatedDate
	FROM Temp_TransactionInfo
	WHERE RawFingerPrintID IS NOT NULL;
    
    /* === Insert new DeviceCookie === */
    INSERT IGNORE INTO DCS_DataCenter.DeviceCookie(CookieID, DeviceID, CreatedDate)
	SELECT 	DISTINCT
			CookieID
		,	DeviceID
		,	lv_CreatedDate
	FROM Temp_TransactionInfo AS tmp
	WHERE CookieID IS NOT NULL;
    
    /* === Insert new TransactionEvolution === */
    INSERT IGNORE INTO DCS_DataCenter.TransactionEvolution(RawFingerPrintID, RecoverFingerPrintID, DeviceID, CreatedDate)
    SELECT	RawFingerPrintID
		,	RecoverFingerPrintID
		,	DeviceID
		,	lv_CurrentDate AS CreatedDate
    FROM Temp_TransactionInfo;
        
END$$

DELIMITER ;
