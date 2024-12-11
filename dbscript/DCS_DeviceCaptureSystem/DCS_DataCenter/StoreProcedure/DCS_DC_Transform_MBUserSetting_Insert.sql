/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBUserSetting_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBUserSetting_Insert`(
	IN ip_MBUserSettingJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20241121@Jonathan.Doan
	    Task : Insert MBUserSetting
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20241121@Jonathan.Doan: Transform to MBTransaction [Redmine ID: #213401]
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_Transform_MBUserSetting_Insert('[{"CountryName":"CountryName1","TimeZone":"TimeZone1","LanguageName":"LanguageName1"},{"TimeZone":"TimeZone2","LanguageName":"LanguageName2"},{}]');
            SELECT * FROM DCS_DataCenter.MBUserSetting ORDER BY ID DESC;
    */
    DECLARE lv_CurrentDatetime 	DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MBUserSettingInsert;
	CREATE TEMPORARY TABLE Temp_MBUserSettingInsert(
			CountryName			VARCHAR(32) NOT NULL
		,	TimeZone			VARCHAR(32) NOT NULL
		,	LanguageName		VARCHAR(32) NOT NULL
        
		,	IsNewRecord			TINYINT	DEFAULT 1
        ,	PRIMARY KEY (CountryName, TimeZone, LanguageName)
    );
    
    INSERT IGNORE INTO Temp_MBUserSettingInsert(CountryName, TimeZone, LanguageName)
    SELECT	js.CountryName
		,	js.TimeZone
		,	js.LanguageName
	FROM JSON_TABLE(
			ip_MBUserSettingJson,
			 "$[*]" COLUMNS(
						CountryName			VARCHAR(32) 	PATH "$.CountryName"
					,	TimeZone			VARCHAR(32) 	PATH "$.TimeZone"
					,	LanguageName		VARCHAR(32) 	PATH "$.LanguageName"
				)
		   ) AS js
	WHERE js.CountryName <> ''
		OR js.TimeZone <> ''
		OR js.LanguageName <> '';
	 
    UPDATE Temp_MBUserSettingInsert AS tmp
		INNER JOIN DCS_DataCenter.MBUserSetting AS us ON us.CountryName = tmp.CountryName 
													AND us.TimeZone = tmp.TimeZone
													AND us.LanguageName = tmp.LanguageName
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.MBUserSetting(CountryName, TimeZone, LanguageName, InsertedTime, LastAccessedDate)
	SELECT	CountryName
		,	TimeZone
		,	LanguageName
		,	lv_CurrentDatetime AS InsertedTime
		,	DATE(lv_CurrentDatetime) AS LastAccessedDate
	FROM Temp_MBUserSettingInsert
    WHERE IsNewRecord = 1;
END$$
DELIMITER ;