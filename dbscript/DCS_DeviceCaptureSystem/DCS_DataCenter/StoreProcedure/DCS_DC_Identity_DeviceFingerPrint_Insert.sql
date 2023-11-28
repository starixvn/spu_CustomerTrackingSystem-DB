/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_DeviceFingerPrint_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_DeviceFingerPrint_Insert`(
		IN ip_TableName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231128@Jonathan.Doan
		Task : Insert into DCS_DataCenter.FPDeviceFingerPrint
		DB: DCS_DataCenter
		Original:

		Revisions:
			- 20231128@Jonathan.Doan: Created [Redmine ID: #196570]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Identity_DeviceFingerPrint_Insert('Temp_DeviceFingerPrint');

	*/
    DECLARE lv_CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceFingerPrint;
        
	CREATE TEMPORARY TABLE Temp_DeviceFingerPrint(
			RawFingerPrintID		BIGINT UNSIGNED		PRIMARY KEY
        ,	DeviceID				BIGINT UNSIGNED		NOT NULL
		,	IsNewRecord				TINYINT		 		DEFAULT 1
    );
    
	SET @sql = CONCAT('INSERT IGNORE INTO Temp_DeviceFingerPrint(RawFingerPrintID, DeviceID) 
						SELECT 	DISTINCT
								RawFingerPrintID
							,	DeviceID
                        FROM ', ip_TableName);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
	 
    UPDATE Temp_DeviceFingerPrint AS tmp
		INNER JOIN DCS_DataCenter.FPDeviceFingerPrint AS df ON df.RawFingerPrintID = tmp.RawFingerPrintID
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.FPDeviceFingerPrint(RawFingerPrintID, DeviceID, CreatedDate)
	SELECT	RawFingerPrintID
		,	DeviceID
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_DeviceFingerPrint
    WHERE IsNewRecord = 1;
END$$

DELIMITER ;
