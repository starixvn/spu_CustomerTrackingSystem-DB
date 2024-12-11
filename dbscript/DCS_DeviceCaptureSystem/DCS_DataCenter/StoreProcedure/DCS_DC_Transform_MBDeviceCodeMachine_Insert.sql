/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBDeviceCodeMachine_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBDeviceCodeMachine_Insert`(
	IN ip_MBDeviceCodeMachineJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20241121@Jonathan.Doan
	    Task : Insert MBDeviceCodeMachine
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20241121@Jonathan.Doan: Transform to MBTransaction [Redmine ID: #213401]
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_Transform_MBDeviceCodeMachine_Insert('[{"Code":"Code4","MachineOS":"Android"},{"Code":"Code2"},{"Code":"Code3","MachineOS":""}]');
            SELECT * FROM DCS_DataCenter.MBDeviceCodeMachine ORDER BY ID DESC;
    */
    
    DECLARE lv_CurrentDatetime DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceCodeMachineInsert;
	CREATE TEMPORARY TABLE Temp_MBDeviceCodeMachineInsert(
			Code					VARCHAR(32) NOT NULL
		,	MachineOSType	 		SMALLINT NOT NULL COMMENT 'DCS_DataCenter.StaticList.ListID = 5'
        
		,	IsNewRecord				TINYINT	DEFAULT 1
        ,	PRIMARY KEY (Code, MachineOSType)
    );
    
	INSERT IGNORE INTO Temp_MBDeviceCodeMachineInsert(Code, MachineOSType)
    SELECT	js.Code
		,	IFNULL(sl.ItemID, 0) AS MachineOSType
	FROM JSON_TABLE(
			ip_MBDeviceCodeMachineJson,
			 "$[*]" COLUMNS(
						Code		VARCHAR(32) COLLATE utf8_unicode_ci PATH "$.Code"
					,	MachineOS	VARCHAR(32) COLLATE utf8_unicode_ci PATH "$.MachineOS"
				)
		   ) AS js
		LEFT JOIN DCS_DataCenter.StaticList AS sl ON sl.ListID = 5 AND sl.ItemCode = js.MachineOS
	WHERE js.Code <> '';
	 
    UPDATE Temp_MBDeviceCodeMachineInsert AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceCodeMachine AS ar ON ar.Code = tmp.Code AND ar.MachineOSType = tmp.MachineOSType
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.MBDeviceCodeMachine(Code, MachineOSType, InsertedTime, LastAccessedDate)
	SELECT	Code
		,	MachineOSType
		,	lv_CurrentDatetime AS InsertedTime
		,	DATE(lv_CurrentDatetime) AS LastAccessedDate
	FROM Temp_MBDeviceCodeMachineInsert
    WHERE IsNewRecord = 1;
END$$
DELIMITER ;