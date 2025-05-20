/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transaction_GetAccountsPerDevice`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transaction_GetAccountsPerDevice`(
		IN ip_LastDay		INT UNSIGNED,
        IN ip_NoOfDevice	INT UNSIGNED,
		IN ip_PageSize 		INT UNSIGNED,
		IN ip_PageIndex 	INT UNSIGNED,
        OUT op_TotalPages 	INT UNSIGNED,
        OUT op_TotalRows 	INT UNSIGNED
)
SQL SECURITY INVOKER
BEGIN
	/*
	Created: 20250520@Lando.Vu
	Task : Get Accounts Per Device report
	DB: DCS_DataCenter
	Original:

	Revisions:
		- 20250520@Lando.Vu: Created [Redmine ID: 227652]
		
	Param's Explanation (filtered by):

	Example:
        CALL DCS_DataCenter.DCS_DC_Transaction_GetAccountsPerDevice(100);
	*/
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AccountsPerDevice;
    
    CREATE TEMPORARY TABLE Temp_AccountsPerDevice(
			AccountID 			INT
        ,	NoOfDevice			INT
    );
    INSERT IGNORE INTO Temp_AccountsPerDevice(AccountID, NoOfDevice)
    VALUES (1, 10), (2, 20), (3, 10);
    
    SELECT 	apd.AccountID,
			apd.NoOfDevice
	FROM Temp_AccountsPerDevice AS adp;
    
    SELECT 
        5 AS TotalPages,
        100 AS TotalRows;
END$$
DELIMITER ;
