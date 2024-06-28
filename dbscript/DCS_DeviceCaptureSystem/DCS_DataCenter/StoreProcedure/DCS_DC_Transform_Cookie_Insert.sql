/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Cookie_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_Cookie_Insert`(
	IN ip_CookieJson	LONGTEXT
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
			CALL DCS_DC_Transform_Cookie_Insert('[{"CookieCode":"123","FirstTransTime":"2024-06-21 12:10:01.1234"}]');

	*/
    DECLARE lv_CurrentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CookieInsert;
        
	CREATE TEMPORARY TABLE Temp_CookieInsert(
			ID				INT UNSIGNED AUTO_INCREMENT		PRIMARY KEY
        ,	CookieCode		VARCHAR(64) 					NOT NULL
        ,	FirstTransTime	TIMESTAMP(4)
        
		,	IsNewCookie		TINYINT		 					DEFAULT 1
    );
    
    INSERT INTO Temp_CookieInsert(CookieCode, FirstTransTime)
    SELECT	jt.CookieCode
		,	jt.FirstTransTime
	FROM JSON_TABLE(
			ip_CookieJson,
			 "$[*]" COLUMNS(
						CookieCode			VARCHAR(64) 	PATH "$.CookieCode"
					,	FirstTransTime		TIMESTAMP(4) 	PATH "$.FirstTransTime"
				)
		   ) AS jt;
	
	ALTER TABLE Temp_CookieInsert
	ADD INDEX IX_Temp_CookieInsert_CookieCode (CookieCode);
    
    UPDATE Temp_CookieInsert AS tmp
		INNER JOIN DCS_DataCenter.Cookie AS c ON c.CookieCode = tmp.CookieCode
    SET tmp.IsNewCookie = 0;
	
	INSERT IGNORE INTO DCS_DataCenter.Cookie(CookieCode, FirstTransTime, CreatedDate)
	SELECT	CookieCode
		,	MIN(FirstTransTime) AS FirstTransTime
		,	lv_CurrentDate AS CreatedDate
	FROM Temp_CookieInsert
    WHERE IsNewCookie = 1
    GROUP BY CookieCode;
    
END$$

DELIMITER ;
