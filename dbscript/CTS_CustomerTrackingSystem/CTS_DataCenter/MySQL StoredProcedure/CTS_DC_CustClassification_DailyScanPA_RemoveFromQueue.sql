/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_DailyScanPA_RemoveFromQueue`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_DailyScanPA_RemoveFromQueue`(
		IN ip_CustIDs      			TEXT
	,	IN ip_MaxScannedTime		DATETIME
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20230313@Jonas.Huynh
		Task:  Return PA category for daily scan PA
		DB: CTS_DataCenter
		Original:
		Revisions:
            - 20230313@Jonas.Huynh: Get PA category for daily scan PA [Redmine ID: #184772]

		Param's Explanation (filtered by):      
			- CALL CTS_DC_CustClassification_DailyScanPA_RemoveFromQueue ('123,455', '2023-03-14 00:00:00');
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
	CREATE TEMPORARY TABLE Temp_Customers (
		 	CustID			BIGINT UNSIGNED	PRIMARY KEY
	);
    
	INSERT INTO Temp_Customers (CustID)
    SELECT DISTINCT temp.CustID
    FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),
			'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (
				CustID 		BIGINT UNSIGNED PATH '$'
			))) AS temp;
            
    DELETE queue
    FROM CTS_DataCenter.CTSCustomerClassification_DailyPAQueue AS queue 
    WHERE queue.CreatedTime <= ip_MaxScannedTime
		AND EXISTS (SELECT 1 FROM Temp_Customers AS tmp WHERE tmp.CustID = clss.CustID);
    
END$$
DELIMITER ;