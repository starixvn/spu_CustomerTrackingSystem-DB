/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Monitoring_CheckMissingCustomer`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Monitoring_CheckMissingCustomer`(
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
			- 20211213@Harvey: Initial
			- 20230228@Jonas.Huynh: Update SP [Redmine ID: 183278]
            
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_DataCenter.CTS_DC_Monitoring_CheckMissingCustomer ('[{"CustID":82355840,"CustSubID":0,"UserName":"12BETUS$017955","CreatedDate":"2023-03-01T22:14:00"}]');

	*/
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;    
	CREATE TEMPORARY TABLE Temp_CTSCustomer(
			CustID			INT	UNSIGNED
		,	CustSubID 		INT	UNSIGNED
        ,	UserName 		VARCHAR(50)
        ,	CreatedDate		DATETIME
        ,	PRIMARY KEY (CustID, CustSubID)
	);

    INSERT INTO Temp_CTSCustomer(CustID, CustSubID, UserName, CreatedDate)
	SELECT		CustID	
			,	CustSubID
            ,	UserName
            ,   CreatedDate
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
				CustID			INT			UNSIGNED		PATH "$.CustID" 
			,	CustSubID		INT			UNSIGNED		PATH "$.CustSubID"
            ,	UserName		VARCHAR(50)					PATH "$.UserName"
            ,	CreatedDate		DATETIME					PATH "$.CreatedDate"
			)
	) AS js;
    
    SELECT tcust.CustID
		,	tcust.CustSubID
        ,	tcust.UserName
        ,	tcust.CreatedDate
	FROM Temp_CTSCustomer AS tcust
	LEFT JOIN CTSCustomer cust ON tcust.CustID = cust.CustID
		AND tcust.CustSubID = cust.CustSubID
	WHERE cust.CustID IS NULL;

END$$
DELIMITER ;