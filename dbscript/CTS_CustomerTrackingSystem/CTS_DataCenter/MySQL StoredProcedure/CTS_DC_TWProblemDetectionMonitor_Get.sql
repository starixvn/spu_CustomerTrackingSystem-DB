/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_TWProblemDetectionMonitor_Get`;
DELIMITER $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_TWProblemDetectionMonitor_Get`(
	IN ip_UserNameList TEXT
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
            - 	20220906@Aries.Nguyen: Renovate PA process [Redmine ID: 172561]
            
		Param's Explanation (filtered by):	

		Example:
			- CALL CTS_DC_CustClassification_GetBySite('SA-GBP,SA-NT,QQ,QQSub01,QQSub02,QQSub03');

	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_UserName;
    CREATE TEMPORARY TABLE Temp_UserName(
		UserName VARCHAR(50) PRIMARY KEY
	);
	
    SET @sql= CONCAT("INSERT INTO Temp_UserName (UserName) VALUES ('", REPLACE(ip_UserNameList, ',', "'),('"),"');");
    PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;      
      
    SELECT	DISTINCT
			tmpCus.UserName
		,	cus.CustID
        ,	(CASE WHEN cc.ParentID = 200 AND cc.CategoryGroup IN (201,202,205) THEN 1 ELSE 0 END) AS IsMonitorCategoryGroup
        ,	(CASE WHEN cus.SiteID = 487 THEN 1 ELSE 0 END) AS IsMonitorSite
    FROM Temp_UserName AS tmpCus
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.UserName = tmpCus.UserName AND cus.CustSubID = 0 
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS ccl ON cus.CustID = ccl.CustID 
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON ccl.CategoryID = cc.CategoryID;	

END$$
DELIMITER ;

