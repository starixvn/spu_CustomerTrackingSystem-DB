/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_ET_Country_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_ET_Country_Insert`(
	IN ip_InputJs JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230809@Jonathan.Doan
		Task :		Insert Countries
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20230809@Jonathan.Doan: Created [Redmine ID: 192402]
			
		Param's Explanation (filtered by):
			
		Example:
			CALL DCS_ET_Country_Insert('[{"CountryCode":"VN","CountryName":"Việt Nam"},{"CountryCode":"THA","CountryName":"Thái Lan"},{"CountryCode":"LAO","CountryName":"Lào"}]');
            SELECT * FROM DCS_Extra.Country;
    
    */
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Input;
    
    CREATE TEMPORARY TABLE Temp_Input(
			CountryCode 	VARCHAR(20)	NOT NULL PRIMARY KEY
		,	CountryName	 	VARCHAR(64)
    );
    
	INSERT IGNORE INTO Temp_Input(CountryCode, CountryName)
	SELECT	tmp.CountryCode
		,	tmp.CountryName
	FROM	JSON_TABLE(
			ip_InputJs,
			 "$[*]" COLUMNS(
					CountryCode		VARCHAR(20)		PATH "$.CountryCode",
					CountryName		VARCHAR(64)		PATH "$.CountryName"
				)
		   ) AS tmp;

	DELETE tmp
    FROM Temp_Input AS tmp
		INNER JOIN DCS_Extra.Country AS c ON c.CountryCode = tmp.CountryCode;

	INSERT IGNORE INTO DCS_Extra.Country(CountryName, CountryCode)
	SELECT 	CountryName
		,	CountryCode
	FROM Temp_Input;
END$$

DELIMITER ;
