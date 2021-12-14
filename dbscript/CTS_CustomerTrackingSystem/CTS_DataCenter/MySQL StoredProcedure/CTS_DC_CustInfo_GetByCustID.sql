/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_GetByCustID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_GetByCustID`(
	IN ip_ListCustID LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210526@Long.Luu
		Task :		Get Customer's Site and Danger level
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20210526@Long.Luu: Created [Redmine ID: 152883]
			- 	20210720@Long.Luu: Change datatype from varchar(8k) to longtext [Redmine ID: 152883]
            -	20211213@Casey.Huynh: Enhance MM, remove Danger Level from return result [Redmine ID: 165606]
			
		Param's Explanation (filtered by):
        		
		Example:
			-	CALL CTS_DC_CustInfo_GetByCustID('1315,1495');
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;
    CREATE TEMPORARY TABLE Temp_CustID(
		CustID 	BIGINT UNSIGNED
	);
 
	SET @sql = CONCAT("INSERT INTO Temp_CustID(CustID) VALUES ('", REPLACE(ip_ListCustID, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SELECT	c.CustID
		,	c.CTSCustID
		,	c.UserName
        ,	c.SubscriberID
        , 	s.SubscriberName
		, 	c.Site
        ,	c.Currency
        ,	CASE WHEN s.SubscriberType = 0 THEN 'C' ELSE 'L' END AS SubscriberType
	FROM Temp_CustID AS t
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON t.CustID = c.CustID
		INNER JOIN  CTS_Admin.Subscriber AS s ON c.SubscriberID	= s.SubscriberID
	WHERE c.CustSubID = 0;
	 
END$$

DELIMITER ;