/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBDeviceCodeMediaDRM_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBDeviceCodeMediaDRM_Insert`(
	IN ip_MediaDRM	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20241121@Jonathan.Doan
	    Task : Insert MBDeviceCodeMediaDRM
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20241121@Jonathan.Doan: Transform to MBTransaction [Redmine ID: #213401]
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_Transform_MBDeviceCodeMediaDRM_Insert('');
            SELECT * FROM DCS_DataCenter.MBDeviceCodeMediaDRM ORDER BY ID DESC;
    */
    DECLARE lv_CurrentDatetime DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeMediaDRMInsert;
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeMediaDRMInsert(
			Code			VARCHAR(32) NOT NULL PRIMARY KEY
		,	IsNewRecord		TINYINT	DEFAULT 1
    );
    
    SET @sql = CONCAT("INSERT IGNORE INTO Temp_MBDeviceCodeMediaDRMInsert (Code) VALUES ('", REPLACE(ip_MediaDRM, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    DELETE FROM Temp_MBDeviceCodeMediaDRMInsert
    WHERE IFNULL(Code,'') = '';
    
    UPDATE Temp_MBDeviceCodeMediaDRMInsert AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceCodeMediaDRM AS drm ON drm.Code = tmp.Code
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.MBDeviceCodeMediaDRM(Code, InsertedTime, LastAccessedDate)
	SELECT	Code
		,	lv_CurrentDatetime AS InsertedTime
		,	DATE(lv_CurrentDatetime) AS LastAccessedDate
	FROM Temp_MBDeviceCodeMediaDRMInsert
    WHERE IsNewRecord = 1;
END$$
DELIMITER ;