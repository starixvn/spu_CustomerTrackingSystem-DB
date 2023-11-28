/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_DeviceCookie_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_DeviceCookie_Insert`(
		IN ip_TableName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231128@Jonathan.Doan
		Task : Insert into DCS_DataCenter.DeviceCookie
		DB: DCS_DataCenter
		Original:

		Revisions:
			- 20231128@Jonathan.Doan: Created [Redmine ID: #196570]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Identity_DeviceCookie_Insert('Temp_DeviceCookie');

	*/
    DECLARE lv_CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCookie;
        
	CREATE TEMPORARY TABLE Temp_DeviceCookie(
			CookieID				BIGINT UNSIGNED		PRIMARY KEY
        ,	DeviceID				BIGINT UNSIGNED		NOT NULL
		,	IsNewRecord				TINYINT		 		DEFAULT 1
    );
    
	SET @sql = CONCAT('INSERT IGNORE INTO Temp_DeviceCookie(CookieID, DeviceID) 
						SELECT 	DISTINCT
								CookieID
							,	DeviceID
                        FROM ', ip_TableName);
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
	 
    UPDATE Temp_DeviceCookie AS tmp
		INNER JOIN DCS_DataCenter.DeviceCookie AS dc ON dc.CookieID = tmp.CookieID
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.DeviceCookie(CookieID, DeviceID, CreatedDate)
	SELECT	CookieID
		,	DeviceID
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_DeviceCookie
    WHERE IsNewRecord = 1;
END$$

DELIMITER ;
