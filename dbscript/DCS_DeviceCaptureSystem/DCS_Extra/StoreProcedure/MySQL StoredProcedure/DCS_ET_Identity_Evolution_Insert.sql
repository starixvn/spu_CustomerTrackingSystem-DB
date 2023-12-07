/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Identity_Evolution_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Identity_Evolution_Insert`(
    IN ip_TransJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231205@Jonathan.Doan
	    Task : Evolution Insert
	    DB: DCS_Extra
	    Original:
		 
	    Revisions:
			- 20231205@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_ET_Identity_Evolution_Insert('[{"TransID":32,"RecoverRawFingerPrintID":11},{"TransID":39,"RecoverRawFingerPrintID":13}]');
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
        ,	AccountID							BIGINT UNSIGNED
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
		   ) AS tmp
	WHERE tmp.TransID IS NOT NULL
		AND tmp.RecoverRawFingerPrintID IS NOT NULL;
    
	UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_Extra.Transaction AS trans ON trans.TransID = tmp.TransID
	SET tmp.RawFingerPrintID 	= trans.RawFingerPrintID,
    	tmp.CookieID 			= trans.CookieID,
    	tmp.AccountID 			= trans.AccountID;
    
    /* === Add index === */
	ALTER TABLE Temp_TransactionInfo
	ADD INDEX IX_Temp_TransactionInfo_RawFingerPrintID (RawFingerPrintID);
    
	UPDATE Temp_TransactionInfo AS tmp
		INNER JOIN DCS_Extra.FPDeviceFingerPrint AS df ON df.RawFingerPrintID = tmp.RecoverRawFingerPrintID
	SET tmp.DeviceID = df.DeviceID;

    /* === Return data === */
    select	TransID
		,	DeviceID AS FPDeviceID
		,	4 AS RecoverType
    from Temp_TransactionInfo;
    
    DELETE FROM Temp_TransactionInfo WHERE DeviceID IS NULL;
    
    /* === Insert new FPDeviceFingerPrint === */
	WITH cte_DistinctData AS (
		SELECT 	DISTINCT
				RawFingerPrintID
			,	DeviceID
		FROM Temp_TransactionInfo
		WHERE RawFingerPrintID IS NOT NULL
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
		WHERE CookieID IS NOT NULL
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
    
    /* === Insert new TransactionEvolution === */
	WITH cte_DistinctData AS (
		SELECT 	DISTINCT
				RawFingerPrintID
			,	RecoverRawFingerPrintID
			,	DeviceID
		FROM Temp_TransactionInfo
		WHERE RawFingerPrintID IS NOT NULL
    )
	SELECT JSON_ARRAYAGG(
			JSON_OBJECT(
				'RawFingerPrintID', RawFingerPrintID,
				'RecoverRawFingerPrintID', RecoverRawFingerPrintID,
				'DeviceID', DeviceID
			)
		) AS json_data
	INTO lv_TransactionEvolutionJson
	FROM cte_DistinctData;
    
    SET lv_TransactionEvolutionJson = IFNULL(lv_TransactionEvolutionJson,'[{}]');
	CALL DCS_ET_Identity_TransactionEvolution_Insert(lv_TransactionEvolutionJson);
	
    /* === Update AccountFingerprint === */
	UPDATE DCS_Extra.AccountFingerprint AS af
		INNER JOIN Temp_TransactionInfo AS tmp ON tmp.AccountID = af.AccountID 
											AND tmp.RecoverRawFingerPrintID = af.RawFingerPrintID 
	SET af.IsEvolution = 1,
		af.ModifiedDate = lv_CreatedDate;
END$$

DELIMITER ;
