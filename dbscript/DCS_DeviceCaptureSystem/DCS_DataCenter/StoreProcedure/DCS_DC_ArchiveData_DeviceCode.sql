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
		Task:		Archive DeviceCode
		DB:			DCS_DataCenter
		Original:

		Revisions:
			- 20210330@Casey.Huynh [Redmine ID: #152454]
		Param's Explanation (filtered by):
	*/ 
	
    DECLARE	lv_LastDeviceCodeID	BIGINT; # The Last DeviceCodeID
    DECLARE	lv_ToDeviceCodeID	BIGINT; # The Last DeviceCodeID
    DECLARE	lv_MaxDeviceCodeID	BIGINT; # The Max DeviceCodeID BY 
	DECLARE	lv_ToDate			DATE; # The DeviceCode.CreatedDate < lv_ToDate 
    
   
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

    WHILE (@lv_ToDeviceCodeID != -1)
    DO
	#	SELECT 'Debug1', NOW(),@lv_ToDeviceCodeID,lv_LastDeviceCodeID;
        
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
        SELECT			dc.DeviceID
					,	dc.CreatedTime
                    ,	dc.DeviceCodeID
        FROM		DCS_DataCenter.DeviceCode AS dc					
        WHERE	dc.CreatedDate < lv_ToDate AND EXISTS (SELECT 1 FROM CTE_Device AS cte WHERE dc.DeviceID  = cte.DeviceID); 	         
	
       # SELECT 'Debug2', NOW(),@lv_ToDeviceCodeID,lv_LastDeviceCodeID;
        
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
			SELECT 	dc.DeviceCodeID, dc.DeviceCode, dc.DeviceID, dc.FirstTransID, dc.CreatedTime, dc.CreatedDate, dc.InsertTime
			FROM	DCS_DataCenter.DeviceCode AS dc
			INNER JOIN Temp_DeviceCode AS tmpDc ON dc.DeviceCodeID = tmpDc.DeviceCodeID;
		 
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

       # SELECT 'Debug3', NOW(),@lv_ToDeviceCodeID,lv_LastDeviceCodeID;
    END WHILE;
    SELECT 'DebugN', NOW(),@lv_ToDeviceCodeID,lv_LastDeviceCodeID;
    SELECT NOW();
    
END$$

DELIMITER ;
