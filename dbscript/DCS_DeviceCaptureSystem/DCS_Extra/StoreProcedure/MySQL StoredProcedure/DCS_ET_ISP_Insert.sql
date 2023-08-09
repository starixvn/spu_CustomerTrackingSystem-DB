/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_ISP_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_ISP_Insert`(
	IN ip_InputJs LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230809@Jonathan.Doan
		Task :		Insert ISPs
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230809@Jonathan.Doan: Created [Redmine ID: 192402]
			
		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_ISP_Insert('Cosmote Mobile Telecommunications S.A.,Telecom Italia S.p.A.,PCCW Global Inc.,Rise Manila');
            SELECT * FROM DCS_Extra.ISP;
    
    */
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Input;
    
    CREATE TEMPORARY TABLE Temp_Input(
			ISPName	 	VARCHAR(128)	NOT NULL PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_Input (ISPName) VALUES ('", REPLACE(ip_InputJs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	DELETE tmp
    FROM Temp_Input AS tmp
		INNER JOIN DCS_Extra.ISP AS c ON c.ISPName = tmp.ISPName;

	INSERT IGNORE INTO DCS_Extra.ISP(ISPName)
	SELECT ISPName
	FROM Temp_Input;
END$$

DELIMITER ;
