/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_Monitoring_CompareData`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_Monitoring_CompareData`(
	IN ip_CustomerList JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201213@Harvey
		Task:		Monitor Insert Customer [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20201213@Harvey: Initial
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_Monitoring_CompareData ('');

	*/
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;    
	CREATE TEMPORARY TABLE Temp_CTSCustomer(
			CustID			INT
		,	CustSubID 		INT
	);

    INSERT INTO Temp_CTSCustomer(CustID, CustSubID)
	SELECT		CustID	
			,	CustSubID
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
				CustID			INT		UNSIGNED		PATH "$.CustID" 
			,	CustSubID		INT		UNSIGNED		PATH "$.CustSubID"
			)
	) AS js;
END$$
DELIMITER ;