/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Monitoring_InsertMissingCustomer`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Monitoring_InsertMissingCustomer`(
		IN 	ip_CustomerList 	JSON
	,	IN	ip_ScannedDate		DATETIME
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201213@Harvey
		Task:		Insert missing customer [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20211217@Harvey: Initial
            - 20230228@Jonas.Huynh: Update SP [Redmine ID: 183278]
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_DataCenter.CTS_DC_Monitoring_InsertMissingCustomer ('');

	*/
	DROP TEMPORARY TABLE IF EXISTS Temp_MissingCust;    
	CREATE TEMPORARY TABLE Temp_MissingCust(
		`CustID` 		INT UNSIGNED NOT NULL,
		`CustSubID` 	INT UNSIGNED NOT NULL,
		`UserName` 		VARCHAR(50) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_ci' NULL,
        `CreatedDate` 	DATETIME NOT NULL
	);

    INSERT INTO Temp_MissingCust(CustID, CustSubID, UserName, CreatedDate)
	SELECT		CustID	
			,	CustSubID
            ,	UserName
            ,	CreatedDate
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
				CustID			INT			UNSIGNED		PATH "$.CustID" 
			,	CustSubID		INT			UNSIGNED		PATH "$.CustSubID"
            ,	UserName		VARCHAR(50)					PATH "$.UserName"
            ,	CreatedDate		DATETIME					PATH "$.CreatedDate"
			)
	) AS js;
    
    INSERT INTO CTSCustomer_Missing(CustID, CustSubID, UserName, CreatedDate, ScannedDate)
    SELECT 		CustID	
			,	CustSubID
            ,	UserName
            ,	CreatedDate
            ,	ip_ScannedDate
    FROM Temp_MissingCust;

END$$
DELIMITER ;