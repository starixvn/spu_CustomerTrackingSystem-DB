/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_ArchiveData_DeviceCode`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_ArchiveData_DeviceCode`(
		IN ip_Size INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210330@Casey.Huynh
		Task:		Archive Unused DeviceCode
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
	*/ 
	
    DECLARE	lv_LastDeviceCodeID	BIGINT; # The Last DeviceCodeID
    #DECLARE	lv_ToDeviceCodeID	BIGINT; # The Last DeviceCodeID   
	DECLARE	lv_ToDate			DATE; # The DeviceCode.CreatedDate < lv_ToDate 
    DECLARE	lv_MaxDeviceCodeID	BIGINT; # The Max DeviceCodeID BY 
   
    DROP TEMPORARY TABLE IF EXISTS Temp_Device;
    CREATE TEMPORARY TABLE Temp_Device(
			DeviceID	BIGINT UNSIGNED
        ,	MinCreatedTime	BIGINT UNSIGNED
        ,	MaxCreatedTime	BIGINT UNSIGNED
        
        ,	PRIMARY KEY PK_Temp_Device_DeviceID(DeviceID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCode;
    CREATE TEMPORARY TABLE Temp_DeviceCode(
			DeviceID		BIGINT UNSIGNED        
        ,	CreatedTime		BIGINT UNSIGNED
        ,	DeviceCodeID	BIGINT UNSIGNED
        ,	PRIMARY KEY PK_Temp_DeviceCode_DeviceCodeID(DeviceID,DeviceCodeID)
    );
    
    SELECT 	VValue
    INTO	lv_LastDeviceCodeID
    FROM	DCS_DataCenter.SystemSetting AS dc
    WHERE	ID = 8; 
    
    SET lv_ToDate = DATE_SUB(CURRENT_DATE(), INTERVAL 6 DAY);
    SET @lv_ToDeviceCodeID = lv_LastDeviceCodeID;
    
    SET lv_MaxDeviceCodeID = (SELECT DeviceCodeID FROM DCS_DataCenter.DeviceCode WHERE CreatedDate = lv_ToDate LIMIT 1);

    WHILE (@lv_ToDeviceCodeID != -1)
    DO
        INSERT  INTO	Temp_DeviceCode(DeviceID, CreatedTime, DeviceCodeID)
        WITH CTE_Device AS
        (
			SELECT	DISTINCT DeviceID
					, @lv_ToDeviceCodeID := DeviceCodeID
			FROM	DCS_DataCenter.DeviceCode AS dc
			WHERE	DeviceCodeID > lv_LastDeviceCodeID
					AND dc.CreatedDate < lv_ToDate
			LIMIT	ip_Size
        )
        SELECT	dc.DeviceID
			,	dc.CreatedTime
            ,	dc.DeviceCodeID
        FROM	DCS_DataCenter.DeviceCode AS dc					
        WHERE	dc.DeviceCodeID < lv_MaxDeviceCodeID
				AND EXISTS (SELECT 1 FROM CTE_Device AS cte WHERE dc.DeviceID  = cte.DeviceID); 	         
        
        IF(lv_LastDeviceCodeID = @lv_ToDeviceCodeID)
        THEN
			SET @lv_ToDeviceCodeID = -1;
		ELSE        
			INSERT INTO Temp_Device(DeviceID, MinCreatedTime, MaxCreatedTime)
			SELECT		tmpDc.DeviceID
					,	MIN(tmpDc.CreatedTime)
					, 	MAX(tmpDc.CreatedTime)
			FROM		Temp_DeviceCode AS tmpDc
			GROUP BY 	DeviceID;
			
			DELETE	tmpDc
			FROM	Temp_DeviceCode AS tmpDc
				INNER JOIN Temp_Device AS tmpDv ON tmpDc.DeviceID = tmpDv.DeviceID AND tmpDc.CreatedTime = tmpDv.MinCreatedTime;
			
			DELETE	tmpDc
			FROM	Temp_DeviceCode AS tmpDc
				INNER JOIN Temp_Device AS tmpDv ON tmpDc.DeviceID = tmpDv.DeviceID AND tmpDc.CreatedTime = tmpDv.MaxCreatedTime;
			
			INSERT IGNORE INTO DCS_DataCenter.zzArchiveDeviceCode(DeviceCodeID, DeviceCode, DeviceID, FirstTransID, CreatedTime, CreatedDate, InsertTime)
			SELECT	dc.DeviceCodeID, dc.DeviceCode, dc.DeviceID, dc.FirstTransID, dc.CreatedTime, dc.CreatedDate, dc.InsertTime
			FROM	DCS_DataCenter.DeviceCode AS dc
				INNER JOIN	Temp_DeviceCode AS tmpDc ON dc.DeviceCodeID = tmpDc.DeviceCodeID;
		 
			DELETE	dc
			FROM	DCS_DataCenter.DeviceCode AS dc
				INNER JOIN Temp_DeviceCode AS tmpDc ON dc.DeviceCodeID = tmpDc.DeviceCodeID;   
        
			SET lv_LastDeviceCodeID = @lv_ToDeviceCodeID;
            
            UPDATE 	 DCS_DataCenter.SystemSetting AS dc
			SET		 VValue = lv_LastDeviceCodeID
			WHERE	 ID = 8; 
            
        END IF;
        
        TRUNCATE TABLE Temp_DeviceCode;
        TRUNCATE TABLE Temp_Device;
        
        DO SLEEP(0.5);
    END WHILE;
    
END$$

DELIMITER ;
