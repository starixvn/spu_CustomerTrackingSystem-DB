/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Cookie_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_Cookie_Insert`(
    IN ip_CookieCodes	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20231108@Jonathan.Doan
		Task : Insert into DCS_DataCenter.Cookie
		DB: DCS_DataCenter
		Original:

		Revisions:
			- 20231108@Jonathan.Doan: Created [Redmine ID: #196570]
			- 20240621@Jonathan.Doan: Change data flow v5.1 [Redmine ID: #206403]

		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_DC_Transform_Cookie_Insert('123,345');

	*/
    DECLARE lv_CurrentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CookieInsert;
        
	CREATE TEMPORARY TABLE Temp_CookieInsert(
			ID				INT UNSIGNED AUTO_INCREMENT		PRIMARY KEY
        ,	CookieCode		VARCHAR(64) 					NOT NULL
		,	IsNewCookie		TINYINT		 					DEFAULT 1
    );
    
    SET @sql = CONCAT("INSERT INTO Temp_CookieInsert (CookieCode) VALUES ('", REPLACE(ip_CookieCodes, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    UPDATE Temp_CookieInsert AS tmp
		INNER JOIN DCS_DataCenter.Cookie AS c ON c.CookieCode = tmp.CookieCode
    SET tmp.IsNewCookie = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.Cookie(CookieCode, CreatedDate)
	SELECT	DISTINCT
			CookieCode
		,	lv_CurrentDate AS CreatedDate
	FROM Temp_CookieInsert
    WHERE IsNewCookie = 1;
    
END$$

DELIMITER ;
