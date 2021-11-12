/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_TWProblemDetectionMonitor_GetBySite`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_TWProblemDetectionMonitor_GetBySite`(
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
			- CALL CTS_DC_CustClassification_GetBySite('487','SA-GBP,SA-NT,QQ,QQSub01,QQSub02,QQSub03');

	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_UserName;
    CREATE TEMPORARY TABLE Temp_UserName
    (
		UserName VARCHAR(50) PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SiteID;
    CREATE TEMPORARY TABLE Temp_SiteID
    (
		SiteID INT UNSIGNED PRIMARY KEY
	);
    
    SET @sql= CONCAT("INSERT INTO Temp_UserName (UserName) VALUES ('", REPLACE(ip_UserNameList, ',', "'),('"),"');");
    PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
    SET @sql= CONCAT("INSERT INTO Temp_SiteID (SiteID) VALUES ('", REPLACE(ip_SiteIDList, ',', "'),('"),"');");
    PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
    SELECT	cus.CustID
		,	tmpCus.UserName
        ,	(CASE WHEN cc.ParentID = 200 AND GROUP_CONCAT(cc.CategoryGroup) IN (201,202,205) THEN 1 ELSE 0 END) AS IsMonitorCategoryGroup
    FROM Temp_UserName AS tmpCus
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.UserName = tmpCus.UserName AND cus.CustSubID = 0 AND cus.SiteID IN (SELECT SiteID FROM Temp_SiteID)
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS ccl ON cus.CustID = ccl.CustID 
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON ccl.CategoryID = cc.CategoryID
	GROUP BY cus.CustID, cus.UserName, cc.ParentID;
	
    
END$$
DELIMITER ;

