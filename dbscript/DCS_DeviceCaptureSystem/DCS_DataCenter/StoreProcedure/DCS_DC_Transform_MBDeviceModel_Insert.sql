/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_MBDeviceModel_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_MBDeviceModel_Insert`(
	IN ip_MBDeviceModelJson	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20241121@Jonathan.Doan
	    Task : Insert MBDeviceModel
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
		    - 20241121@Jonathan.Doan: Transform to MBTransaction [Redmine ID: #214026]
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_Transform_MBDeviceModel_Insert('[{"ModelName":"ModelName3","Manufacturer":"Manufacturer1","Brand":"Brand1"},{"ModelName":"ModelName2"},{"ModelName":"ModelName3","Brand":"Brand3"},{}]');
            SELECT * FROM DCS_DataCenter.MBDeviceModel ORDER BY ID DESC;
    */
    DECLARE lv_CurrentDatetime 	DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MBDeviceModelInsert;
	CREATE TEMPORARY TABLE Temp_MBDeviceModelInsert(
			ModelName			VARCHAR(32) NOT NULL
		,	Manufacturer		VARCHAR(32) NOT NULL
		,	Brand				VARCHAR(32) NOT NULL
        
		,	IsNewRecord			TINYINT	DEFAULT 1
        ,	PRIMARY KEY (ModelName, Manufacturer, Brand)
    );
    
    INSERT IGNORE INTO Temp_MBDeviceModelInsert(ModelName, Manufacturer, Brand)
    SELECT	IFNULL(js.ModelName, '') AS ModelName
		,	IFNULL(js.Manufacturer, '') AS Manufacturer
		,	IFNULL(js.Brand, '') AS Brand
	FROM JSON_TABLE(
			ip_MBDeviceModelJson,
			 "$[*]" COLUMNS(
						ModelName			VARCHAR(32) 	PATH "$.ModelName"
					,	Manufacturer		VARCHAR(32) 	PATH "$.Manufacturer"
					,	Brand				VARCHAR(32) 	PATH "$.Brand"
				)
		   ) AS js
	WHERE js.ModelName IS NOT NULL
		OR js.Manufacturer IS NOT NULL
		OR js.Brand IS NOT NULL;
	 
    UPDATE Temp_MBDeviceModelInsert AS tmp
		INNER JOIN DCS_DataCenter.MBDeviceModel AS dm ON dm.ModelName = tmp.ModelName 
													AND dm.Manufacturer = tmp.Manufacturer
													AND dm.Brand = tmp.Brand
    SET tmp.IsNewRecord = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.MBDeviceModel(ModelName, Manufacturer, Brand, InsertedTime, LastAccessedDate)
	SELECT	ModelName
		,	Manufacturer
		,	Brand
		,	lv_CurrentDatetime AS InsertedTime
		,	lv_CurrentDatetime AS LastAccessedDate
	FROM Temp_MBDeviceModelInsert
    WHERE IsNewRecord = 1;
END$$
DELIMITER ;