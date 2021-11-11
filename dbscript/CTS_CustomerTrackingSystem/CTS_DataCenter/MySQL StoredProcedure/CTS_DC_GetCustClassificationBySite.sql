/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_GetCustClassificationBySite`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_GetCustClassificationBySite`(
		IN ip_SiteIDList	VARCHAR(500)
	,	IN ip_UserNameList TEXT
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20211110@Casey.Huynh
		Task :		Return Classification of Cust that has Site in 'ip_SiteList'
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20211110@Casey.Huynh: Created [Redmine ID: 164148]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL CTS_DC_GetCustClassificationBySite('487','SA-GBP,SA-NT,QQ,QQSub01,QQSub02,QQSub03');
			SELECT * FROM CTSCustomer WHERE CustID IN (12,30,1349398,1812820,1816112,4560695);
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;
    CREATE TEMPORARY TABLE Temp_CustID
    (
		UserName VARCHAR(50) PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SiteID;
    CREATE TEMPORARY TABLE Temp_SiteID
    (
		SiteID INT UNSIGNED PRIMARY KEY
	);
    
    SET @sql= CONCAT("INSERT INTO Temp_CustID (UserName) VALUES ('", REPLACE(ip_UserNameList, ',', "'),('"),"');");
    PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
    SET @sql= CONCAT("INSERT INTO Temp_SiteID (SiteID) VALUES ('", REPLACE(ip_SiteIDList, ',', "'),('"),"');");
    PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;

    SELECT	cus.CustID
		,	tmpCus.UserName
        ,	cus.RoleID
        ,	ctc.CustomerClass
    FROM Temp_CustID AS tmpCus
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.UserName = tmpCus.UserName AND cus.CustSubID = 0 AND cus.SiteID IN (SELECT SiteID FROM Temp_SiteID)
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS ccl ON cus.CustID = ccl.CustID 
        INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS ctc ON ccl.CategoryID = ctc.CategoryID;
    
END$$
DELIMITER ;

