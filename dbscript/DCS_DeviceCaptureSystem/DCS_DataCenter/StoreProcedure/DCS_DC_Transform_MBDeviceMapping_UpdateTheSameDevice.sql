/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBDeviceMapping_UpdateTheSameDevice`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBDeviceMapping_UpdateTheSameDevice`(
		IN ip_TableName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20241202@Lando.Vu
	    Task : Transform Transaction
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 202401202@Lando.Vu: Transform to MBTransaction [Redmine ID: #213401]
            
	    Param's Explanation (filtered by):
        
        Example:
			DROP TABLE IF EXISTS Temp_NewDevice;
			CREATE TEMPORARY TABLE Temp_NewDevice(
					ID											BIGINT UNSIGNED NOT NULL PRIMARY KEY
				,	SameDeviceWithRawTransID					BIGINT UNSIGNED DEFAULT 0
				,	RecoverType									SMALLINT UNSIGNED DEFAULT 0
				
				,	FirstDeviceID								BIGINT UNSIGNED
				,	SecondDeviceID								BIGINT UNSIGNED
				,	ThirdDeviceID								BIGINT UNSIGNED
			);
            
            INSERT INTO Temp_NewDevice(ID, FirstDeviceID, SecondDeviceID, ThirdDeviceID)
            VALUES(1, 1, 1, 1), (2, 1, 1, 2), (3, 2, 2, 3), (4, 2, 3, 4);
            
			SET sql_safe_updates = 0;
			CALL DCS_DC_Transform_MBDeviceMapping_UpdateTheSameDevice('Temp_NewDevice');
            select * from Temp_NewDevice;
	*/
    DECLARE CONST_RECOVERTYPE_FIRSTRULE		SMALLINT DEFAULT 1;
    DECLARE CONST_RECOVERTYPE_SECONDRULE	SMALLINT DEFAULT 2;
    DECLARE CONST_RECOVERTYPE_THIRDRULE	SMALLINT DEFAULT 3;
    
    DECLARE lv_CurrentID 					BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxID 						BIGINT UNSIGNED;
    DECLARE lv_CurrentFirstDeviceID 		BIGINT UNSIGNED;
    DECLARE lv_CurrentSecondDeviceID 		BIGINT UNSIGNED;
    DECLARE lv_CurrentThirdDeviceID 		BIGINT UNSIGNED;
    DECLARE lv_SameDeviceWithID 			BIGINT UNSIGNED;
    DECLARE lv_RecoverType		 			SMALLINT; /* 1: FirstRule, 2: SecondRule, 2: ThirdRule */

	DROP TEMPORARY TABLE IF EXISTS Temp_SameMBDevice;
    
	CREATE TEMPORARY TABLE Temp_SameMBDevice(
			ID									BIGINT UNSIGNED NOT NULL PRIMARY KEY
		,	SameDeviceWithID					BIGINT UNSIGNED
		,	RecoverType							SMALLINT UNSIGNED DEFAULT 0

		,	FirstDeviceID						BIGINT UNSIGNED
		,	SecondDeviceID						BIGINT UNSIGNED
		,	ThirdDeviceID						BIGINT UNSIGNED
	);
    
	SET @sql = CONCAT('INSERT INTO Temp_SameMBDevice(ID, FirstDeviceID, SecondDeviceID, ThirdDeviceID) 
						SELECT 	ID
							,	FirstDeviceID
							,	SecondDeviceID
							,	ThirdDeviceID
                        FROM ', ip_TableName, 
					' 	WHERE FirstDeviceID IS NOT NULL
							OR SecondDeviceID IS NOT NULL
							OR ThirdDeviceID IS NOT NULL
                            ');
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    ALTER TABLE Temp_SameMBDevice
    ADD KEY IX_Temp_SameMBDevice_FirstDeviceID(FirstDeviceID),
    ADD KEY IX_Temp_SameMBDevice_SecondDeviceID(SecondDeviceID),
    ADD KEY IX_Temp_SameMBDevice_ThirdDeviceID(ThirdDeviceID);
    
    SELECT MAX(ID) INTO lv_MaxID FROM Temp_SameMBDevice;

    WHILE lv_CurrentID < lv_MaxID DO
        SELECT 	ID
			,	FirstDeviceID
            ,	SecondDeviceID
            ,	ThirdDeviceID
            ,	SameDeviceWithID
            ,	RecoverType
        INTO lv_CurrentID, lv_CurrentFirstDeviceID, lv_CurrentSecondDeviceID, lv_CurrentThirdDeviceID, lv_SameDeviceWithID, lv_RecoverType
        FROM Temp_SameMBDevice
        WHERE ID > lv_CurrentID
        ORDER BY ID ASC
        LIMIT 1;

        SELECT	MIN(SameDeviceWithID)
			,	MAX(CASE WHEN ID IS NOT NULL THEN CONST_RECOVERTYPE_FIRSTRULE ELSE 0 END) AS RecoverType
        INTO lv_SameDeviceWithID, lv_RecoverType
        FROM Temp_SameMBDevice
        WHERE FirstDeviceID <> 0
			AND FirstDeviceID = lv_CurrentFirstDeviceID
			AND ID < lv_CurrentID;
		
        IF lv_SameDeviceWithID IS NULL THEN
			SELECT 	MIN(SameDeviceWithID)
				,	MAX(CASE WHEN ID IS NOT NULL THEN CONST_RECOVERTYPE_SECONDRULE ELSE 0 END) AS RecoverType
			INTO lv_SameDeviceWithID, lv_RecoverType
			FROM Temp_SameMBDevice
			WHERE SecondDeviceID <> 0
				AND SecondDeviceID = lv_CurrentSecondDeviceID
				AND ID < lv_CurrentID;
			
			IF lv_SameDeviceWithID IS NULL THEN
				SET lv_SameDeviceWithID = lv_CurrentID;
			END IF;
        END IF;
        
        IF lv_SameDeviceWithID IS NULL THEN
			SELECT 	MIN(SameDeviceWithID)
				,	MAX(CASE WHEN ID IS NOT NULL THEN CONST_RECOVERTYPE_THIRDRULE ELSE 0 END) AS RecoverType
			INTO lv_SameDeviceWithID, lv_RecoverType
			FROM Temp_SameMBDevice
			WHERE ThirdDeviceID <> 0
				AND ThirdDeviceID = lv_CurrentThirdDeviceID
				AND ID < lv_CurrentID;
			
			IF lv_SameDeviceWithID IS NULL THEN
				SET lv_SameDeviceWithID = lv_CurrentID;
			END IF;
        END IF;
        
        UPDATE Temp_SameMBDevice
        SET SameDeviceWithID = lv_SameDeviceWithID,
			RecoverType = lv_RecoverType
        WHERE ID = lv_CurrentID;
        
		SET @sql = CONCAT('UPDATE ', ip_TableName,' AS tmp
								INNER JOIN Temp_SameMBDevice AS tmpNd ON tmpNd.ID = tmp.ID
							SET tmp.SameDeviceWithRawTransID = IFNULL(tmpNd.SameDeviceWithID, 0),
								tmp.RecoverType = IFNULL(tmpNd.RecoverType, 0)');
		PREPARE stmt FROM @sql;
		EXECUTE stmt;
		DEALLOCATE PREPARE stmt;
        
    END WHILE;
END$$

DELIMITER ;
