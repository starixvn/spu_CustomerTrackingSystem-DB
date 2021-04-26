/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_ArchiveData_DeviceCode`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_ArchiveData_DeviceCode`(
	IN ip_Size INT
	,	OUT op_IsContinue BOOLEAN # 1: Continue, 0: Stop
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
	DECLARE	lv_LastDate			DATE; # The DeviceCode.CreatedDate < lv_LastDate 
    DECLARE	lv_MaxDeviceCodeID	BIGINT; #The Fisrt DeviceCode of lv_LastDate 
    DECLARE	lv_scheDate			DATE;
   
    DROP TEMPORARY TABLE IF EXISTS Temp_Device;
    CREATE TEMPORARY TABLE Temp_Device(
			DeviceID		BIGINT UNSIGNED
        ,	MinCreatedTime	DATETIME
        ,	MaxCreatedTime	DATETIME
        
        ,	PRIMARY KEY PK_Temp_Device_DeviceID(DeviceID)
    );
    
    SET op_IsContinue = 1;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCode;
    CREATE TEMPORARY TABLE Temp_DeviceCode(
			DeviceID		BIGINT UNSIGNED        
        ,	CreatedTime		DATETIME 
        ,	DeviceCodeID	BIGINT UNSIGNED
        ,	PRIMARY KEY PK_Temp_DeviceCode_DeviceCodeID(DeviceID,DeviceCodeID)
    );
    
    SELECT 	VValue
    INTO	lv_LastDeviceCodeID
    FROM	DCS_DataCenter.SystemSetting AS ss
    WHERE	ID = 8; 
    
    SELECT 	VValue
    INTO	lv_LastDate
    FROM	DCS_DataCenter.SystemSetting AS ss
    WHERE	ID = 9;     
    
	 SELECT 	VValue
    INTO	lv_MaxDeviceCodeID
    FROM	DCS_DataCenter.SystemSetting AS ss
    WHERE	ID = 10;        
    
	INSERT  INTO	Temp_DeviceCode(DeviceID, CreatedTime, DeviceCodeID)
	WITH CTE_Device AS
	(
		SELECT	DISTINCT DeviceID
				, @lv_ToDeviceCodeID := DeviceCodeID
		FROM	DCS_DataCenter.DeviceCode AS dc
		WHERE	DeviceCodeID > lv_LastDeviceCodeID
				AND dc.CreatedDate < lv_LastDate
		LIMIT	ip_Size
	)
	SELECT	dc.DeviceID
		,	dc.CreatedTime
		,	dc.DeviceCodeID
	FROM	DCS_DataCenter.DeviceCode AS dc					
	WHERE	dc.DeviceCodeID < lv_MaxDeviceCodeID
			AND EXISTS (SELECT 1 FROM CTE_Device AS cte WHERE dc.DeviceID  = cte.DeviceID); 	
  
    #==========UPDATE LAST DATE==============
	SET lv_scheDate = DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);
    IF (lv_LastDate < lv_scheDate) THEN
    
			SET lv_LastDate = lv_scheDate;
            
            UPDATE DCS_DataCenter.SystemSetting AS ss
            SET		ss.VValue = lv_LastDate
            WHERE	ID = 9;
            
			UPDATE DCS_DataCenter.SystemSetting AS ss
            SET		ss.VValue = (SELECT DeviceCodeID FROM DCS_DataCenter.DeviceCode WHERE CreatedDate = lv_LastDate LIMIT 1)
            WHERE	ID = 10;
    END IF;
    #============================================
    
    IF EXISTS (SELECT 1 FROM Temp_DeviceCode)
    THEN
  
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

		UPDATE 	 DCS_DataCenter.SystemSetting AS dc
		SET		 VValue = @lv_ToDeviceCodeID
		WHERE	 ID = 8; 
        
        SET op_IsContinue = 1;
    ELSE 
		SET op_IsContinue = 0;
	END IF;
        
	TRUNCATE TABLE Temp_DeviceCode;
	TRUNCATE TABLE Temp_Device;
    
END$$

DELIMITER ;
