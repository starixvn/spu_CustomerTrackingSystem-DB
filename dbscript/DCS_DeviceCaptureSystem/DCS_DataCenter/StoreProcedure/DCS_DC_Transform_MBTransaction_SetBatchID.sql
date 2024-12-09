/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBTransaction_SetBatchID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBTransaction_SetBatchID`(
		IN ip_TableName VARCHAR(50),
		IN ip_BatchSize INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	    Created: 20241205@Jonathan.Doan
	    Task : Set BatchID
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20241205@Jonathan.Doan: Created [RedmineID: #206403]
	    Param's Explanation (filtered by):
        
        Example:
			DROP TABLE IF EXISTS Temp_NewDevice;
			CREATE TEMPORARY TABLE Temp_NewDevice(
					ID							INT NOT NULL AUTO_INCREMENT PRIMARY KEY 
				,	BatchID						INT DEFAULT 0

				,	FirstDeviceID				BIGINT UNSIGNED
				,	SecondDeviceID				BIGINT UNSIGNED
				,	ThirdDeviceID				BIGINT UNSIGNED
			);
            
			INSERT INTO Temp_NewDevice(FirstDeviceID, SecondDeviceID, ThirdDeviceID)
			VALUES(1,1,1) ,(2,2,2) ,(1,1,5) ,(3,2,2) ,(0,0,0);
            
			SET sql_safe_updates = 0;
			CALL DCS_DC_Transform_MBTransaction_SetBatchID('Temp_NewDevice', 3);
            select * from Temp_NewDevice;
	*/
    
    DECLARE lv_CurrentID 					BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_MaxID 						BIGINT UNSIGNED;
    DECLARE lv_CurrentFirstDeviceID 		BIGINT UNSIGNED;
    DECLARE lv_CurrentSecondDeviceID 		BIGINT UNSIGNED;
    DECLARE lv_CurrentThirdDeviceID 		BIGINT UNSIGNED;
    DECLARE lv_BatchID 						BIGINT UNSIGNED;

	DROP TEMPORARY TABLE IF EXISTS Temp_InputData;
    DROP TEMPORARY TABLE IF EXISTS Temp_FirstDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_SecondDevice;
    DROP TEMPORARY TABLE IF EXISTS Temp_ThirdDevice;
    
	CREATE TEMPORARY TABLE Temp_InputData(
			ID							INT NOT NULL PRIMARY KEY 
		,	BatchID						INT DEFAULT 0

		,	FirstDeviceID				BIGINT UNSIGNED
		,	SecondDeviceID				BIGINT UNSIGNED
		,	ThirdDeviceID				BIGINT UNSIGNED
	);
    
    CREATE TEMPORARY TABLE Temp_FirstDevice(	
		    ID					BIGINT	UNSIGNED PRIMARY KEY
		,   BatchID				INT
    );
    
    CREATE TEMPORARY TABLE Temp_SecondDevice(	
		    ID					BIGINT	UNSIGNED PRIMARY KEY
		,   BatchID				INT
    );
    
    CREATE TEMPORARY TABLE Temp_ThirdDevice(	
		    ID					BIGINT	UNSIGNED PRIMARY KEY
		,   BatchID				INT
    );
    
	SET @sql = CONCAT('INSERT INTO Temp_InputData(ID, FirstDeviceID, SecondDeviceID, ThirdDeviceID) 
						SELECT 	ID
							,	IFNULL(FirstDeviceID, 0) AS FirstDeviceID
							,	IFNULL(SecondDeviceID, 0) AS SecondDeviceID
							,	IFNULL(ThirdDeviceID, 0) AS ThirdDeviceID
                        FROM ', ip_TableName);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    ALTER TABLE Temp_InputData
    ADD KEY IX_Temp_InputData_FirstDeviceID(FirstDeviceID),
    ADD KEY IX_Temp_InputData_SecondDeviceID(SecondDeviceID),
    ADD KEY IX_Temp_InputData_ThirdDeviceID(ThirdDeviceID);
    
    INSERT INTO Temp_FirstDevice(ID)
    SELECT DISTINCT FirstDeviceID
    FROM Temp_NewDevice;
    
    SELECT COUNT(ID)
    INTO @CountFirstDevice
    FROM Temp_FirstDevice;
    
    SET @RowId = 0;
    SET @NoOfBatch = CEIL(@CountFirstDevice / ip_BatchSize);
    
    UPDATE Temp_FirstDevice
	SET BatchID = CEIL(@RowId := @RowId + 1 / @NoOfBatch)
    ORDER BY (ID = 0) ASC, ID ASC;
    
    UPDATE Temp_InputData AS tmp
		INNER JOIN Temp_FirstDevice AS tmpF ON tmpF.ID = tmp.FirstDeviceID
	SET tmp.BatchID = tmpF.BatchID;
    
    -- SecondDevice
    INSERT INTO Temp_SecondDevice(ID, BatchID)
    SELECT SecondDeviceID, MIN(BatchID) as MinBatchID
    FROM Temp_InputData
    WHERE SecondDeviceID IS NOT NULL
		AND SecondDeviceID > 0
	GROUP BY SecondDeviceID;
    
    UPDATE Temp_InputData AS tmp
		INNER JOIN Temp_SecondDevice AS tmpNd ON tmpNd.ID = tmp.SecondDeviceID
	SET tmp.BatchID = tmpNd.BatchID;
    
    -- ThirdDevice
    INSERT INTO Temp_ThirdDevice(ID, BatchID)
    SELECT ThirdDeviceID, MIN(BatchID) as MinBatchID
    FROM Temp_InputData
    WHERE ThirdDeviceID IS NOT NULL
		AND ThirdDeviceID > 0
	GROUP BY ThirdDeviceID;
    
    UPDATE Temp_InputData AS tmp
		INNER JOIN Temp_ThirdDevice AS tmpRd ON tmpRd.ID = tmp.ThirdDeviceID
	SET tmp.BatchID = tmpRd.BatchID;
    
	SET @sql = CONCAT('UPDATE ', ip_TableName,' AS tmp
							INNER JOIN Temp_InputData AS tmpIn ON tmpIn.ID = tmp.ID
						SET tmp.BatchID = IFNULL(tmpIn.BatchID, 0)');
	PREPARE stmt FROM @sql;
	EXECUTE stmt;
	DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;