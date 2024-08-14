/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_FP_DeviceMappingUpdateTheSameDevice`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_FP_DeviceMappingUpdateTheSameDevice`(
		IN ip_TableName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20240729@Jonathan.Doan
	    Task : Change Data Flow Ver. 6
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20240729@Jonathan.Doan: Created [RedmineID: #206403]
	    Param's Explanation (filtered by):
        
        Example:
			CREATE TEMPORARY TABLE Temp_NewDevice(
					RawTransID									BIGINT UNSIGNED NOT NULL PRIMARY KEY
				,	SameDeviceWithRawTransID					BIGINT UNSIGNED DEFAULT 0
				,	FP_DeviceID									BIGINT UNSIGNED DEFAULT 0
				
				,	FP_TaggingID								BIGINT UNSIGNED
				,	FP_DeviceFingerprintAccountID				BIGINT UNSIGNED
			);
			CALL DCS_DC_Transform_FP_DeviceMappingUpdateTheSameDevice('Temp_NewDevice');
	*/
    
    DECLARE lv_CurrentID 				INT DEFAULT 0;
    DECLARE lv_MaxID 					INT;
    DECLARE lv_CurrentFirstDeviceID 	INT;
    DECLARE lv_CurrentSecondDeviceID 	INT;
    DECLARE lv_SameDeviceWithID 		INT;
    DECLARE done 						INT DEFAULT 0;

	DROP TEMPORARY TABLE IF EXISTS Temp_SameDevice;
	DROP TEMPORARY TABLE IF EXISTS Temp_SameDevice1;
    
	CREATE TEMPORARY TABLE Temp_SameDevice(
			ID									BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	SameDeviceWithID					BIGINT UNSIGNED

		,	FirstDeviceID						BIGINT UNSIGNED
		,	SecondDeviceID						BIGINT UNSIGNED
	);
    
	SET @sql = CONCAT('INSERT INTO Temp_SameDevice(ID, FirstDeviceID, SecondDeviceID) 
						SELECT 	RawTransID 						AS ID
							,	FP_TaggingID 					AS FirstDeviceID
							,	FP_DeviceFingerprintAccountID 	AS SecondDeviceID
                        FROM ', ip_TableName, 
					' 	WHERE FP_TaggingID IS NOT NULL
							OR FP_DeviceFingerprintAccountID IS NOT NULL');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    SELECT MAX(ID) INTO lv_MaxID FROM Temp_SameDevice;

    WHILE lv_CurrentID < lv_MaxID DO
        SELECT 	ID
			,	FirstDeviceID
            ,	SecondDeviceID
            ,	SameDeviceWithID
        INTO lv_CurrentID, lv_CurrentFirstDeviceID, lv_CurrentSecondDeviceID, lv_SameDeviceWithID
        FROM Temp_SameDevice
        WHERE ID > lv_CurrentID
        ORDER BY ID ASC
        LIMIT 1;

        SELECT MIN(SameDeviceWithID)
        INTO lv_SameDeviceWithID
        FROM Temp_SameDevice
        WHERE FirstDeviceID = lv_CurrentFirstDeviceID
          AND ID < lv_CurrentID;

        IF lv_SameDeviceWithID IS NULL THEN
			SELECT MIN(SameDeviceWithID)
			INTO lv_SameDeviceWithID
			FROM Temp_SameDevice
			WHERE SecondDeviceID = lv_CurrentSecondDeviceID
			  AND ID < lv_CurrentID;
			
			IF lv_SameDeviceWithID IS NULL THEN
				SET lv_SameDeviceWithID = lv_CurrentID;
			END IF;
        END IF;

        UPDATE Temp_SameDevice
        SET SameDeviceWithID = lv_SameDeviceWithID
        WHERE ID = lv_CurrentID;
        
		SET @sql = CONCAT('UPDATE ', ip_TableName,' AS tmp
								INNER JOIN Temp_SameDevice AS tmpNd ON tmpNd.ID = tmp.RawTransID
							SET tmp.SameDeviceWithRawTransID = IFNULL(tmpNd.SameDeviceWithID, 0)');
		PREPARE stmt FROM @sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
        
    END WHILE;
END$$

DELIMITER ;
