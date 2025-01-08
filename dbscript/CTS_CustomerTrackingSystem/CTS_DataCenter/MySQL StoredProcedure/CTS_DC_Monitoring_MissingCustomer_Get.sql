/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Monitoring_MissingCustomer_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Monitoring_MissingCustomer_Get`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20241213@Jonas.Huynh
		Task:		Missing Customer [Redmine ID: 214157]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20241213@Jonas.Huynh: Missing Customer [Redmine ID: 214157]
            
		Param's Explanation (filtered by):
            
		Example:
			- CALL CTS_DataCenter.CTS_DC_Monitoring_MissingCustomer_Get();

	*/
    DECLARE CONST_BATCHSIZE							SMALLINT DEFAULT 5000;
    DECLARE CONST_MISSING_NEWCUSTOMER				TINYINT DEFAULT 2;
    DECLARE CONST_MISSING_REACTIVATEDCUSTOMER		TINYINT DEFAULT 50;
         
   	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;    
	CREATE TEMPORARY TABLE Temp_CTSCustomer(
			ID				BIGINT UNSIGNED PRIMARY KEY
		,	CustID			INT	UNSIGNED 
        ,	KEY IX_Temp_CTSCustomer_CustID(CustID)	
	);
   
    INSERT INTO Temp_CTSCustomer(ID, CustID)
	SELECT	 	a.ID	
			,	a.CustID
    FROM CTS_DataCenter.JobMonitoring_IncorrectData AS a
		INNER JOIN CTS_DataCenter.StaticList AS s ON s.ItemID = a.IssueTypeID AND s.ListID = 20
	WHERE a.IssueTypeID IN (CONST_MISSING_NEWCUSTOMER, CONST_MISSING_REACTIVATEDCUSTOMER)
		AND a.IsResolved = 0
    ORDER BY a.ID ASC
    LIMIT CONST_BATCHSIZE;
    
    SELECT 	t.ID
		,	t.CustID
        ,	CASE WHEN c.CustID IS NULL THEN 1 ELSE 0 END AS IsMissingCust 
    FROM Temp_CTSCustomer AS t
		LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON c.CustID = t.CustID;

END$$
DELIMITER ;