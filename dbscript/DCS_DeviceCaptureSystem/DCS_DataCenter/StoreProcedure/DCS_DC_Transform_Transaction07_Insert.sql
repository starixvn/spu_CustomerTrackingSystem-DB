/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Transaction07_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_Transaction07_Insert`(
    IN ip_TransJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20231124@Jonathan.Doan
	    Task : Insert into Transaction07
	    DB: DCS_DataCenter
	    Original:
		 
	    Revisions:
			- 20231123@Jonathan.Doan: Integrate FPSjs Phrase 2 [Redmine: 196656]
	    Param's Explanation (filtered by):
        
        Example:
			CALL DCS_DC_Transform_Transaction07_Insert('[{"TransID":1,"DeviceID":1,"FPDeviceID":100,"DeviceCodeID":2,"FirstDeviceCode":"DC","DeviceStatus":1,"DeviceFingerprintID":1}]');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputTrans;
	CREATE TEMPORARY TABLE Temp_InputTrans(
			TransID					BIGINT UNSIGNED PRIMARY KEY
		,	DeviceID				BIGINT UNSIGNED
		,	FPDeviceID				BIGINT UNSIGNED
		,	DeviceCodeID			BIGINT UNSIGNED
		,	FirstDeviceCode			VARCHAR(32)
		,	DeviceStatus			TINYINT
		,	DeviceFingerprintID		BIGINT UNSIGNED
	);
    
    INSERT INTO Temp_InputTrans(TransID, DeviceID, FPDeviceID, DeviceCodeID, FirstDeviceCode, DeviceStatus, DeviceFingerprintID)
	SELECT	tmpJs.TransID
		,	tmpJs.DeviceID
		,	tmpJs.FPDeviceID
        ,	tmpJs.DeviceCodeID
        ,	tmpJs.FirstDeviceCode
        ,	tmpJs.DeviceStatus
        ,	tmpJs.DeviceFingerprintID
    FROM JSON_TABLE(
			ip_TransJson,
			 "$[*]" COLUMNS(
							TransID					BIGINT UNSIGNED		PATH "$.TransID"
						,	DeviceID				BIGINT UNSIGNED		PATH "$.DeviceID"
						,	FPDeviceID				BIGINT UNSIGNED		PATH "$.FPDeviceID"
						,	DeviceCodeID			BIGINT UNSIGNED		PATH "$.DeviceCodeID"
						,	FirstDeviceCode			VARCHAR(32) 		PATH "$.FirstDeviceCode"
						,	DeviceStatus			TINYINT				PATH "$.DeviceStatus"
						,	DeviceFingerprintID		BIGINT UNSIGNED		PATH "$.DeviceFingerprintID"
					)
		) AS tmpJs;
    
    SELECT *
    FROM Temp_InputTrans;
END$$

DELIMITER ;
