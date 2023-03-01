/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Monitoring_InsertIncorrectCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_Monitoring_InsertIncorrectCategory`(
		IN 	ip_CustomerList 	JSON
	,	IN	ip_InvalidType		SMALLINT
) 
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20230227@Jonas.Huynh
		Task:  Job monitor customer category
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20230227@Jonas.Huynh: Created SP [RedmineID: #183278]
            
		Param's Explanation (filtered by):    
			CALL CTS_DC_CustClassification_Monitoring_InsertIncorrectCategory('123,456')
	*/  
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;    
	CREATE TEMPORARY TABLE Temp_CustInfo(
		`CustID` 		BIGINT UNSIGNED NOT NULL,
		`CategoryID` 	INT UNSIGNED NOT NULL,
		`InvalidType` 	SMALLINT
	);

    INSERT INTO Temp_CustInfo(CustID, CategoryID, InvalidType)
	SELECT		js.CustID	
			,	js.CategoryID
            ,	js.InvalidType
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
				CustID			BIGINT	UNSIGNED	PATH "$.CustID" 
			,	CategoryID		INT		UNSIGNED	PATH "$.CategoryID"
			)
	) AS js;

	INSERT INTO CTSCustomerClassification_IncorrectData_Monitor(CustID, CategoryID, CreatedDate, InvalidType)
	SELECT 		CustID
			, 	CategoryID
			,	NOW()
			, 	ip_InvalidType
	FROM Temp_CustInfo;
	
END$$
DELIMITER ;