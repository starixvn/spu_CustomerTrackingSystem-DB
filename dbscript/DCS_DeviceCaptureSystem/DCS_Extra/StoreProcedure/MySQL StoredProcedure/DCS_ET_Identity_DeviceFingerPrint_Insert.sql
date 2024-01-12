/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Identity_DeviceFingerPrint_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Identity_DeviceFingerPrint_Insert`(
		IN ip_DeviceFingerPrintJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231205@Jonathan.Doan
		Task : Insert into DCS_Extra.FPDeviceFingerPrint
		DB: DCS_Extra
		Original:

		Revisions:
			- 20231205@Jonathan.Doan: Created [Redmine ID: #196570]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_Identity_DeviceFingerPrint_Insert('[{"RawFingerPrintID":101,"DeviceID":102},{"RawFingerPrintID":103,"DeviceID":104}]');

	*/
    DECLARE lv_CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceFingerPrintInsert;
        
	CREATE TEMPORARY TABLE Temp_DeviceFingerPrintInsert(
			RawFingerPrintID		BIGINT UNSIGNED		PRIMARY KEY
        ,	DeviceID				BIGINT UNSIGNED		NOT NULL
		,	IsNewRecord				TINYINT		 		DEFAULT 1
    );
    
    INSERT INTO Temp_DeviceFingerPrintInsert(RawFingerPrintID, DeviceID)
	SELECT	tmp.RawFingerPrintID
		,	MIN(tmp.DeviceID) AS DeviceID
    FROM JSON_TABLE(
			ip_DeviceFingerPrintJson,
			 "$[*]" COLUMNS(
							RawFingerPrintID	BIGINT UNSIGNED	PATH "$.RawFingerPrintID"
						,	DeviceID			BIGINT UNSIGNED PATH "$.DeviceID"
					)
		) AS tmp
	WHERE IFNULL(tmp.RawFingerPrintID,0) > 0
		AND IFNULL(tmp.DeviceID,0) > 0
	GROUP BY tmp.RawFingerPrintID;
	 
    UPDATE Temp_DeviceFingerPrintInsert AS tmp
		INNER JOIN DCS_Extra.FPDeviceFingerPrint AS df ON df.RawFingerPrintID = tmp.RawFingerPrintID
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_Extra.FPDeviceFingerPrint(RawFingerPrintID, DeviceID, CreatedDate)
	SELECT	RawFingerPrintID
		,	DeviceID
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_DeviceFingerPrintInsert
    WHERE IsNewRecord = 1;
    
END$$

DELIMITER ;
