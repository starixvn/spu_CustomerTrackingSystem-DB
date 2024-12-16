/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Monitoring_MissingCustomer_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Monitoring_MissingCustomer_Get`(
	OUT op_LastScannedID	BIGINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20241213@Jonas.Huynh
		Task:		Missing Customer [Redmine ID: 214157]
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
    
    DECLARE lv_LastScanID		BIGINT UNSIGNED;
    DECLARE lv_NextScanID		BIGINT UNSIGNED;
       
    SELECT ParameterValue
	INTO lv_LastScanID
	FROM CTS_DataCenter.SystemParameter 
	WHERE ParameterID = 185; 
   
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
		INNER JOIN CTS_DataCenter.StaticList AS s ON s.ItemID = a.IssueTypeID 
			AND s.ListID = 20 
            AND s.ItemID IN (CONST_MISSING_NEWCUSTOMER, CONST_MISSING_REACTIVATEDCUSTOMER)
	WHERE a.ID > lv_LastScanID
		AND a.IsResolved = 0
    ORDER BY a.ID ASC
    LIMIT CONST_BATCHSIZE; 
    
    IF (EXISTS(SELECT 1 FROM Temp_CTSCustomer)) THEN
		SET op_LastScannedID = (SELECT MAX(ID) FROM Temp_CTSCustomer);
	ELSE 
		SET lv_NextScanID = (SELECT MAX(ID) FROM CTS_DataCenter.JobMonitoring_IncorrectData);
        IF (lv_NextScanID = lv_LastScanID) THEN
			SET op_LastScannedID = NULL;
		ELSE
			SET op_LastScannedID = lv_NextScanID;
		END IF;
	END IF;
    
    SELECT DISTINCT CustID 
    FROM Temp_CTSCustomer AS t
		LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON c.CustID = t.CustID
    WHERE c.CustID IS NULL;

END$$
DELIMITER ;