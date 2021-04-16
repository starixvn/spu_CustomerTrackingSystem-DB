/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_CustInfo_GetCustomerRoles`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustInfo_GetCustomerRoles`(
		IN ip_CustIDs TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
	Created:	20210408@Irena.Vo	
	Task :		Get Customer Info by CustID list
	DB:			CTS_DataCenter
	Original: 
	Revisions:
		- 20210408@Irena.Vo [Redmine ID: #132623]: Created 
	Param's Explanation:
    Example:
		- CALL CTS_DataCenter.CTS_DC_CustInfo_GetCustomerRoles('5,1284');
	*/ 
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerRoles;
    CREATE TEMPORARY TABLE Temp_CustomerRoles (
			CustID              BIGINT UNSIGNED PRIMARY KEY 
        ,	RoleID				TINYINT
    );  
   
    -- Insert CustIDs
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustomerRoles (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
    
    -- Update Customer Roles
	UPDATE IGNORE Temp_CustomerRoles AS temp
		INNER JOIN 	CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0
    SET temp.RoleID = cust.RoleID;
    
    -- Get Results.
	SELECT DISTINCT	CustId, RoleId FROM Temp_CustomerRoles;
END$$
DELIMITER ;