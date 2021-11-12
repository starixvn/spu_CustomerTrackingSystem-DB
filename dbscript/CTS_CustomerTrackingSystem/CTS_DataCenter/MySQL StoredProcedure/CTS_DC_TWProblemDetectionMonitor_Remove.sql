/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_TWProblemDetectionMonitor_Remove`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_TWProblemDetectionMonitor_Remove`(
	IN ip_CustIDList TEXT
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20211110@Casey.Huynh
		Task :		Return Cust list to scan
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20211110@Casey.Huynh: Created [Redmine ID: 164148]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL CTS_DC_TWProblemDetectionMonitor_Remove('2158796,2140907');		
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;
    CREATE TEMPORARY TABLE Temp_CustID
    (
		CustID INT UNSIGNED
	);
    
    SET @sql= CONCAT("INSERT INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDList, ',', "'),('"),"');");
    PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
	DELETE twb
    FROM CTS_DataCenter.TWProblemDetectionMonitor AS twb
		INNER JOIN Temp_CustID AS tmpCus ON twb.CustID = tmpCus.CustID;
END$$
DELIMITER ;

