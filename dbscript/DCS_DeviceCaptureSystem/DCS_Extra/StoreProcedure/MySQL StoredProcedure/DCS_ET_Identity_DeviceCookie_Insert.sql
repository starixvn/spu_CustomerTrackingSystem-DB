/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Identity_DeviceCookie_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Identity_DeviceCookie_Insert`(
		IN ip_DeviceCookieJson LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231205@Jonathan.Doan
		Task : Insert into DCS_Extra.DeviceCookie
		DB: DCS_Extra
		Original:

		Revisions:
			- 20231205@Jonathan.Doan: Created [Redmine ID: #196570]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_Identity_DeviceCookie_Insert('[{"CookieID": 14, "DeviceID": 8}, {"CookieID": 14, "DeviceID": 2}]');

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
	WHERE IFNULL(tmp.CookieID,0) > 0
		AND IFNULL(tmp.DeviceID,0) > 0
	GROUP BY tmp.CookieID;
	 
    UPDATE Temp_DeviceCookieInsert AS tmp
		INNER JOIN DCS_Extra.DeviceCookie AS dc ON dc.CookieID = tmp.CookieID
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_Extra.DeviceCookie(CookieID, DeviceID, CreatedDate)
	SELECT	CookieID
		,	DeviceID
		,	lv_CreatedDate AS CreatedDate
	FROM Temp_DeviceCookieInsert
    WHERE IsNewRecord = 1;
END$$

DELIMITER ;
