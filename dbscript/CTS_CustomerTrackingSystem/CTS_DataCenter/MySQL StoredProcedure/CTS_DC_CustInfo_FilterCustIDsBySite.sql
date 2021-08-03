/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb,ctsAPI" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustInfo_FilterCustIDsBySite`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustInfo_FilterCustIDsBySite`(
		IN ip_CustIDs TEXT 
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210413@Jonas.Huynh
		Task:		Get Customer With SiteName='611111' or Licencees for updating RobotUser Category
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20210413@Jonas.Huynh: Created [Redmine ID: #152250]
			- 20210622@Aries.Nguyen: Update coding convention and improve locking [Redmine ID: #157203]
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_RobotUser_CheckSiteByCustIds('3290,3292,3293,3294,3300,4687,5858,5939,5940,5941,7596195,7596638,10063375,7596184,7596189');
            - 5 Site = Credit (<> 611111): 3290,3292,3293,3294,3300
            - 5 Site = 611111: 4687,5858,5939,5940,5941
            - 5 Site = Licensee: 7596195,7596638,10063375,7596184,7596189 
	*/

	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;    
	CREATE TEMPORARY TABLE Temp_Customer(	  
			CustID              BIGINT UNSIGNED PRIMARY KEY
        ,	SiteID				INT
        ,	SubscriberID		INT 
	);
  
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customer (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;  
    
    /* Get SubscriberID, SiteID */
	SELECT  temp.CustID
    from Temp_Customer AS temp
		INNER JOIN  CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0
        INNER JOIN CTS_DataCenter.MappingSubscriberSite AS s ON s.SubscriberID = cust.SubscriberID AND s.SiteID = cust.SiteID AND (s.SiteName = '611111' OR s.SubscriberGroupID = 2);
END$$
DELIMITER ;