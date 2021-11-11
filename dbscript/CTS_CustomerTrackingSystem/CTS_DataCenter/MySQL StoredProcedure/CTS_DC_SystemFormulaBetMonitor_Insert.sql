/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_SystemFormulaBetMonitor_Insert`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SystemFormulaBetMonitor_Insert`(
	IN ip_CustIDList TEXT
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20211110@Casey.Huynh
		Task :		Insert Cust need to monitor
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20211110@Casey.Huynh: Created [Redmine ID: 164148]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL CTS_DC_SystemFormulaBetMonitor_Insert('4560695,43701418');
	*/
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;
    CREATE TEMPORARY TABLE Temp_CustID
    (
		CustID INT UNSIGNED PRIMARY KEY
	);    

    SET @sql= CONCAT("INSERT INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDList, ',', "'),('"),"');");
    PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;

    INSERT IGNORE INTO CTS_DataCenter.SystemFormulaBetMonitor(CustID, CreatedDate)
    SELECT	tmpCus.CustID
		,	CURRENT_DATE()
    FROM Temp_CustID AS tmpCus;
END$$
DELIMITER ;

