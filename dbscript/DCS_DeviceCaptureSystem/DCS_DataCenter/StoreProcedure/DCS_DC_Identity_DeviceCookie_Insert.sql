/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_DeviceCookie_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Identity_DeviceCookie_Insert`(
		IN ip_DeviceCookieJson LONGTEXT
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
			CALL DCS_DC_Identity_DeviceCookie_Insert('[{"CookieID": 14, "DeviceID": 8}, {"CookieID": 14, "DeviceID": 2}]');

	*/
    DECLARE lv_CreatedDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_DeviceCookieInsert;
        
	CREATE TEMPORARY TABLE Temp_DeviceCookieInsert(
			CookieID					BIGINT UNSIGNED		PRIMARY KEY
        ,	DeviceID					BIGINT UNSIGNED		NOT NULL
		,	IsNewRecord					TINYINT		 		DEFAULT 1
    );
    
    INSERT INTO Temp_DeviceCookieInsert(CookieID, DeviceID)
	SELECT	tmp.CookieID
		,	MIN(tmp.DeviceID) AS DeviceID
    FROM JSON_TABLE(
			ip_DeviceCookieJson,
			 "$[*]" COLUMNS(
							CookieID	BIGINT UNSIGNED	PATH "$.CookieID"
						,	DeviceID	BIGINT UNSIGNED PATH "$.DeviceID"
					)
		) AS tmp
	WHERE tmp.CookieID IS NOT NULL
		AND tmp.DeviceID IS NOT NULL
	GROUP BY tmp.CookieID;
	 
    UPDATE Temp_DeviceCookieInsert AS tmp
		INNER JOIN DCS_DataCenter.DeviceCookie AS dc ON dc.CookieID = tmp.CookieID
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.DeviceCookie(CookieID, DeviceID, CreatedDate)
	SELECT	CookieID
		,	DeviceID
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_DeviceCookieInsert
    WHERE IsNewRecord = 1;
END$$

DELIMITER ;
