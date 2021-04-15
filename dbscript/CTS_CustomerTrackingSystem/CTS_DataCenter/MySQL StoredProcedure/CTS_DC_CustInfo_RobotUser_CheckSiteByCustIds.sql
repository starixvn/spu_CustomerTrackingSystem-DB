/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb,ctsAPI" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_RobotUser_CheckSiteByCustIds`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_RobotUser_CheckSiteByCustIds`(
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
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_RobotUser_GetSites('1,123');
	*/

	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;    
	CREATE TEMPORARY TABLE Temp_Customer(	  
			CustID              BIGINT UNSIGNED PRIMARY KEY
        ,	SiteID				INT
        ,	SubscriberID		INT
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Subscriber;    
	CREATE TEMPORARY TABLE Temp_Subscriber(	  
			SubscriberID        INT
        ,   SiteID				INT
        ,	INDEX 				IX_Temp_Subscriber (SubscriberID,SiteID)
	);
    
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customer (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;  

	UPDATE      Temp_Customer AS temp
    INNER JOIN  CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0
    SET         temp.SiteID = cust.SiteID
			,	temp.SubscriberID = cust.SubscriberID;
            
	INSERT INTO Temp_Subscriber (SubscriberID, SiteID)
	SELECT s.SubscriberID, s.SiteID
    FROM CTS_DataCenter.MappingSubscriberSite AS s
		INNER JOIN CTS_DataCenter.SubscriberGroup AS sg ON s.SubscriberGroupID = sg.SubscriberGroupID
		LEFT JOIN CTS_Admin.Subscriber AS sub ON s.SubscriberID = sub.SubscriberID
	 WHERE sg.IsActive = 1
		AND sub.IsTest = 0
		AND (s.SiteName = '611111' OR s.SubscriberGroupID = 2);
        
	-- Return CustID
	SELECT Distinct cust.CustID AS CustID
    FROM Temp_Customer AS cust
		INNER JOIN Temp_Subscriber AS s ON cust.SiteID = s.SiteID AND cust.SubscriberID = s.SubscriberID;
        
END$$

DELIMITER ;