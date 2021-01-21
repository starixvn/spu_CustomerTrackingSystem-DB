/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedAccountMonitor_ValidateInput`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedAccountMonitor_ValidateInput`(IN ip_UsernameList varchar(2600))
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20200706@Long.Luu
		Task: Validation usernames list for Insert into ASsociatedAccountMonitor
		DB: CTS_DataCenter
	  
		Revisions:
			- 20200706@Long.Luu: created  [Redmine ID: #134652]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723] 

		Param's Explanation:  
		
	*/

	DROP TEMPORARY TABLE IF EXISTS TmpUsernames;
    
	CREATE TEMPORARY TABLE TmpUsernames( 	 
			UserName		VARCHAR(50)
		,	IsDuplicated	BIT DEFAULT 0
        ,	INDEX 			IX_TmpUsernames_UserName (UserName)
	);
    
    DROP TEMPORARY TABLE IF EXISTS TmpDuplicatedUsernames;
    
	CREATE TEMPORARY TABLE TmpDuplicatedUsernames( 	 
			UserName		VARCHAR(50) PRIMARY KEY
	);
 
    SET @sql = CONCAT("INSERT INTO TmpUsernames (UserName) VALUES ('", REPLACE(ip_UsernameList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT INTO TmpDuplicatedUsernames(UserName)
    SELECT DISTINCT a.UserName
	FROM TmpUsernames AS a
	GROUP BY a.UserName
	HAVING COUNT(1) > 1;
    
    SET SQL_SAFE_UPDATES = 0;
    UPDATE TmpUsernames
		INNER JOIN TmpDuplicatedUsernames ON TmpUsernames.UserName = TmpDuplicatedUsernames.UserName
	SET TmpUsernames.IsDuplicated = 1;

    SELECT 	c.CTSCustID
		,	u.UserName
		,	CASE 
				WHEN u.IsDuplicated = 1 THEN 1 # duplicated username in the input list
                WHEN c.CTSCustID IS NOT NULL AND a.CTSCustID IS NOT NULL THEN 2 # existed in AssociatedAccountMonitor
				WHEN c.CTSCustID IS NOT NULL AND a.CTSCustID IS NULL THEN 0 # ok for insertion
                ELSE 3 # account does not exist
			END AS AccountStatus
    FROM TmpUsernames AS u
		LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON u.UserName = c.UserName
        LEFT JOIN CTS_DataCenter.AssociatedAccountMonitor AS a ON c.CTSCustID = a.CTSCustID;
    
END$$	
DELIMITER ;