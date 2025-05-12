/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBDeviceCodeTagging_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBDeviceCodeTagging_Insert`(
	IN ip_TaggingJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20241121@Jonathan.Doan
	    Task : Insert MBDeviceCodeTagging
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20241121@Jonathan.Doan: Transform to MBTransaction [Redmine ID: #213401]
		    - 20250425@Jonathan.Doan: Add field CreatedDate, CreatedTime [Redmine ID: #221973]
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_Transform_MBDeviceCodeTagging_Insert('[{"Code":"Code4","TransTime":"2025-05-12 01:02:03"});
            SELECT * FROM DCS_DataCenter.MBDeviceCodeTagging ORDER BY ID DESC;
    */
    DECLARE lv_CurrentDatetime DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeTaggingInsert;
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeTaggingInsert(
			Code			VARCHAR(32) NOT NULL PRIMARY KEY
		,	TransTime		DATETIME(4)
		,	IsNewRecord		TINYINT	DEFAULT 1
    );
	
	INSERT IGNORE INTO Temp_MBDeviceCodeTaggingInsert(Code, TransTime)
    SELECT	js.Code
		,	js.TransTime
	FROM JSON_TABLE(
			ip_TaggingJson,
			 "$[*]" COLUMNS(
						Code		VARCHAR(32) COLLATE utf8_unicode_ci PATH "$.Code"
					,	TransTime	DATETIME(4)							PATH "$.TransTime"
				)
		   ) AS js
	WHERE js.Code <> '';
	
    UPDATE Temp_MBDeviceCodeTaggingInsert AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceCodeTagging AS tg ON tg.Code = tmp.Code
    SET tmp.IsNewRecord = 0;
	
	INSERT INTO DCS_DataCenter.MBDeviceCodeTagging(Code, InsertedTime, LastAccessedDate, CreatedDate)
	SELECT	Code
		,	lv_CurrentDatetime AS InsertedTime
		,	DATE(TransTime) AS LastAccessedDate
		,	DATE(TransTime) AS CreatedDate
	FROM Temp_MBDeviceCodeTaggingInsert
    WHERE IsNewRecord = 1;
END$$
DELIMITER ;