/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20240223@Jonas.Huynh
	Task:	 	Customer Info Monitoring
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20240223@Jonas.Huynh: Create Schema [Redmine ID: #198000]
*/

SET @lv_CTSCustomer = (SELECT MAX(CTSCustID) FROM CTS_DataCenter.CTSCustomer); 

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('152', 'JobMonitoring_LastCTSCustomer', 'Get LastCTSCustomer to scan invalid customer info (ListID = 20, ItemID = 3)', 'BIGINT UNSIGNED', CAST(@lv_CTSCustomer AS CHAR(200)));

INSERT INTO `CTS_DataCenter`.`StaticList`(`ListID`,`ItemID`,`ListName`,`ListNameDisplay`,`ItemName`,`ItemNameDisplay`,`ItemValue`,`ItemDefaultValue`,`ItemParentItemID`,`PriorityOrder`,`Status`,`Description`,`CreatedDate`) 
VALUES (20,3,'Job Monitoring IssueType','Job Monitoring IssueType','New Customer - Missing CustInfo','New Customer - Missing CustInfo',null,null,null,null,1,null, NOW());