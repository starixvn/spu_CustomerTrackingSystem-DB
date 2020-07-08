DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_InsertAssociatedAccountMonitorValidation`$$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_InsertAssociatedAccountMonitorValidation`(
		IN ip_UsernameList 		VARCHAR(2600)
)
BEGIN
	/*
		Created: 20200706@Long.Luu
		Task: Validation usernames list for Insert into ASsociatedAccountMonitor
		DB: CTS_DataCenter
	  
		Revisions:
			- 20200706@Long.Luu: created  [Redmine ID: #134652]

		Param's Explanation:  
		
	*/

	DROP TABLE IF EXISTS TempItemTable;
	DROP TABLE IF EXISTS TmpUsernames;
    
	CREATE TEMPORARY TABLE TmpUsernames( 	 
		UserName			VARCHAR(50) PRIMARY KEY
	);
 
    SET @sql = CONCAT("INSERT INTO TmpUsernames (UserName) VALUES ('", REPLACE(ip_UsernameList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SELECT 	u.UserName
		,	CASE 
				WHEN c.CTSCustID IS NOT NULL AND a.CTSCustID IS NULL THEN 0 # ok
                WHEN c.CTSCustID IS NOT NULL AND a.CTSCustID IS NOT NULL THEN 1 # existed in AssociatedAccountMonitor
                ELSE 2 # account does not exist
			END AS AccountStatus
    FROM TmpUsernames AS u
		LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON u.UserName = c.UserName
        LEFT JOIN CTS_DataCenter.AssociatedAccountMonitor AS a ON c.CTSCustID = a.CTSCustID;
    
END$$	
DELIMITER ;