/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Identity_Device_UpdateExistsDeviceID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Identity_Device_UpdateExistsDeviceID`(
	IN ip_TableName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231205@Jonathan.Doan
	    Task : Update Exists DeviceID into temp table
	    DB: DCS_Extra
	    Original:
		 
	    Revisions:
			- 20231205@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_ET_Identity_Device_UpdateExistsDeviceID('6,7,32,42,45,46,54,57');
	*/
    DECLARE lv_CreatedDate DATETIME DEFAULT CURRENT_TIMESTAMP;
    DECLARE lv_DeviceFingerPrintJson LONGTEXT;
    DECLARE lv_DeviceCookieJson LONGTEXT;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_TransExistsDeviceID;
        
	CREATE TEMPORARY TABLE Temp_TransExistsDeviceID(
			TransID				BIGINT UNSIGNED 	PRIMARY KEY
        ,	RawFingerPrintID	BIGINT UNSIGNED		DEFAULT NULL
        ,	CookieID			BIGINT UNSIGNED		DEFAULT NULL
        ,	DeviceID			BIGINT UNSIGNED		DEFAULT NULL
		,	RecoverType			TINYINT		 		DEFAULT 0
    );
    
	SET @sql = CONCAT('INSERT INTO Temp_TransExistsDeviceID(TransID, RawFingerPrintID, CookieID) 
						SELECT 	TransID
							,	RawFingerPrintID 
							,	CookieID 
                        FROM ', ip_TableName);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    /* === Add index === */
	ALTER TABLE Temp_TransExistsDeviceID
		ADD INDEX IX_Temp_TransExistsDeviceID_RawFingerPrintID (RawFingerPrintID),
		ADD INDEX IX_Temp_TransExistsDeviceID_CookieID (CookieID);
    
    /* === Recover by RawFingerPrintID === */
    UPDATE Temp_TransExistsDeviceID AS tmp
		INNER JOIN DCS_Extra.FPDeviceFingerPrint AS df ON tmp.RawFingerPrintID = df.RawFingerPrintID
	SET 	tmp.DeviceID = df.DeviceID
		,	tmp.RecoverType = 1;
    
    /* === Recover by CookieID === */
    UPDATE Temp_TransExistsDeviceID AS tmp
		INNER JOIN DCS_Extra.DeviceCookie AS dc ON tmp.CookieID = dc.CookieID
	SET 	tmp.DeviceID = dc.DeviceID
		,	tmp.RecoverType = tmp.RecoverType + 2;
    
    
    /* === Update data to source table === */
	SET @sql = CONCAT('UPDATE ', ip_TableName,' AS tmp
						INNER JOIN Temp_TransExistsDeviceID AS tmpDes ON tmpDes.TransID = tmp.TransID
                        SET tmp.DeviceID = tmpDes.DeviceID
                        ,	tmp.RecoverType = tmpDes.RecoverType');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    /* === Insert new FPDeviceFingerPrint === */
	WITH cte_DistinctData AS (
		SELECT 	DISTINCT
				RawFingerPrintID
			,	DeviceID
		FROM Temp_TransactionInfo
		WHERE RecoverType = 2
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
		WHERE RecoverType = 1
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
