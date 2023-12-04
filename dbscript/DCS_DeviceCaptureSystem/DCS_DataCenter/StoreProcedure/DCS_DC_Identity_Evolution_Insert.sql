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
			CALL DCS_DC_Identity_Evolution_Insert('[{"TransID":32,"RecoverRawFingerPrintID":11},{"TransID":39,"RecoverRawFingerPrintID":13}]');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
    DECLARE lv_DeviceFingerPrintJson LONGTEXT;
    DECLARE lv_DeviceCookieJson LONGTEXT;
    DECLARE lv_TransactionEvolutionJson LONGTEXT;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_TransactionInfo;
    
	CREATE TEMPORARY TABLE Temp_TransactionInfo(
			TransID								BIGINT UNSIGNED PRIMARY KEY
        ,	RawFingerPrintID					BIGINT UNSIGNED
        ,	RecoverRawFingerPrintID				BIGINT UNSIGNED
        ,	DeviceID							BIGINT UNSIGNED
        ,	CookieID							BIGINT UNSIGNED
	);
    
	INSERT INTO Temp_TransactionInfo(TransID, RecoverRawFingerPrintID)
	SELECT	tmp.TransID
		,	MIN(tmp.RecoverRawFingerPrintID) AS RecoverRawFingerPrintID
	FROM	JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
						TransID					BIGINT UNSIGNED			PATH "$.TransID",
						RecoverRawFingerPrintID	BIGINT UNSIGNED			PATH "$.RecoverRawFingerPrintID"
				)
		   ) AS tmp
	WHERE tmp.TransID IS NOT NULL
		AND tmp.RecoverRawFingerPrintID IS NOT NULL
	GROUP BY tmp.TransID;
    
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

    /* === Return data === */
    select	TransID
		,	DeviceID AS FPDeviceID
		,	4 AS RecoverType
    from Temp_TransactionInfo;
    
    DELETE FROM Temp_TransactionInfo WHERE DeviceID IS NULL;
    
    /* === Insert new FPDeviceFingerPrint === */
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
				'RawFingerPrintID', RawFingerPrintID,
				'DeviceID', DeviceID
			)
		) AS json_data
	INTO lv_DeviceFingerPrintJson
	FROM Temp_TransactionInfo
	WHERE RawFingerPrintID IS NOT NULL;
    
    SET lv_DeviceFingerPrintJson = IFNULL(lv_DeviceFingerPrintJson,'[{}]');
	CALL DCS_DC_Identity_DeviceFingerPrint_Insert(lv_DeviceFingerPrintJson);
    
    /* === Insert new DeviceCookie === */     
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
				'CookieID', CookieID,
				'DeviceID', DeviceID
			)
		) AS json_data
	INTO lv_DeviceCookieJson
	FROM Temp_TransactionInfo
	WHERE CookieID IS NOT NULL;
    
    SET lv_DeviceCookieJson = IFNULL(lv_DeviceCookieJson,'[{}]');
	CALL DCS_DC_Identity_DeviceCookie_Insert(lv_DeviceCookieJson);
    
    /* === Insert new TransactionEvolution === */     
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
				'RawFingerPrintID', RawFingerPrintID,
				'RecoverRawFingerPrintID', RecoverRawFingerPrintID,
				'DeviceID', DeviceID
			)
		) AS json_data
	INTO lv_TransactionEvolutionJson
	FROM Temp_TransactionInfo
	WHERE RawFingerPrintID IS NOT NULL;
    
    SET lv_TransactionEvolutionJson = IFNULL(lv_TransactionEvolutionJson,'[{}]');
	CALL DCS_DC_Identity_TransactionEvolution_Insert(lv_TransactionEvolutionJson);
        
END$$

DELIMITER ;
