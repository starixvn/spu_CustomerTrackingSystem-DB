/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBDeviceCodeTagging_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBDeviceCodeTagging_Insert`(
	IN ip_Tagging	LONGTEXT
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
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_Transform_MBDeviceCodeTagging_Insert('');
            SELECT * FROM DCS_DataCenter.MBDeviceCodeTagging ORDER BY ID DESC;
    */
    DECLARE lv_CurrentDatetime DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeTaggingInsert;
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeTaggingInsert(
			Code			VARCHAR(32) NOT NULL PRIMARY KEY
		,	IsNewRecord		TINYINT	DEFAULT 1
    );
    
    SET @sql = CONCAT("INSERT IGNORE INTO Temp_MBDeviceCodeTaggingInsert (Code) VALUES ('", REPLACE(ip_Tagging, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    DELETE FROM Temp_MBDeviceCodeTaggingInsert
    WHERE IFNULL(Code,'') = '';
    
    UPDATE Temp_MBDeviceCodeTaggingInsert AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceCodeTagging AS tg ON tg.Code = tmp.Code
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.MBDeviceCodeTagging(Code, InsertedTime, LastAccessedDate)
	SELECT	Code
		,	lv_CurrentDatetime AS InsertedTime
		,	DATE(lv_CurrentDatetime) AS LastAccessedDate
	FROM Temp_MBDeviceCodeTaggingInsert
    WHERE IsNewRecord = 1;
END$$
DELIMITER ;