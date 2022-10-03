/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsServiceAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_PA_ClearOld`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_ClearOld`(
		IN ip_CustIDs	LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220520@Aries.Nguyen
		Task :		Renovate PA Process
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
			- 20220520@Aries.Nguyen: Created [Redmine ID: #172561]
		
        Param's Explanation:

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_ClearOld("1,2,3,4");
	*/ 
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;    
	CREATE TEMPORARY TABLE Temp_CustID (	  
			 CustID              BIGINT UNSIGNED PRIMARY KEY 
     );
     
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;   
    
    DELETE clss
    FROM CTS_DataCenter.CTSCustomerClassificationOldCategory AS clss
    WHERE EXISTS (SELECT 1 FROM Temp_CustID AS tmp WHERE tmp.CustID = clss.CustID);
END$$

DELIMITER ;

