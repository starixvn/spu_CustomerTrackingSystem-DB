/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_City_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_City_Insert`(
	IN ip_InputJs LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230809@Jonathan.Doan
		Task :		Insert Citys
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230809@Jonathan.Doan: Created [Redmine ID: 192402]
			
		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_City_Insert('Concepcion,Tuguegarao City,Manduria,Tokyo,Paoy Pet');
            SELECT * FROM DCS_Extra.City;
    
    */
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Input;
    
    CREATE TEMPORARY TABLE Temp_Input(
			CityName	 	VARCHAR(128)	NOT NULL PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_Input (CityName) VALUES ('", REPLACE(ip_InputJs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	DELETE tmp
    FROM Temp_Input AS tmp
		INNER JOIN DCS_Extra.City AS c ON c.CityName = tmp.CityName;

	INSERT IGNORE INTO DCS_Extra.City(CityName)
	SELECT CityName
	FROM Temp_Input;
END$$

DELIMITER ;
