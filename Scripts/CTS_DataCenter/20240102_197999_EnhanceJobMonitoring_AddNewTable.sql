/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20240102@Jonas.Huynh
	Task:	 	Enhance Monitoring Job
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20240102@Jonas.Huynh: Create Schema [Redmine ID: #197999]
*/

CREATE TABLE IF NOT EXISTS CTS_DataCenter.JobMonitoring_IncorrectData (
		ID				BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY 
    ,	IssueTypeID		SMALLINT UNSIGNED NOT NULL
    , 	TrackingInfo	VARCHAR(500) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_ci' NULL
    , 	CustID			INT
    ,	`Value`			BIGINT 
	, 	CreatedDate		DATE NOT NULL DEFAULT (CURRENT_DATE)
    , 	CreatedTime		DATETIME NOT NULL 
	, 	INDEX			IX_JobMonitoring_IncorrectData_IssueTypeID_CreatedDate(IssueTypeID, CreatedDate)
) ENGINE=INNODB;

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('151', 'JobMonitoring_LastScanID', 'Get LastScanID to scan incorrect data', 'BIGINT UNSIGNED', '0');

INSERT INTO `CTS_DataCenter`.`StaticList`(`ListID`,`ItemID`,`ListName`,`ListNameDisplay`,`ItemName`,`ItemNameDisplay`,`ItemValue`,`ItemDefaultValue`,`ItemParentItemID`,`PriorityOrder`,`Status`,`Description`,`CreatedDate`) VALUES
(20,1,'Job Monitoring IssueType','Job Monitoring IssueType','New Customer - Null Category','New Customer - Null Category',null,null,null,null,1,null, NOW()),
(20,2,'Job Monitoring IssueType','Job Monitoring IssueType','New Customer - Missing Customer','New Customer - Missing Customer',null,null,null,null,1,null, NOW()),
(20,100,'Job Monitoring IssueType','Job Monitoring IssueType','Realtime Classification - Inactive Category','Realtime Classification - Inactive Category',null,null,null,null,1,null, NOW()),
(20,101,'Job Monitoring IssueType','Job Monitoring IssueType','Realtime Classification - Null Category','Realtime Classification - Null Category',null,null,null,null,1,null, NOW()),
(20,200,'Job Monitoring IssueType','Job Monitoring IssueType','Classification - Excessive Gerneral Pool','Classification - Excessive Gerneral Pool',null,null,null,null,1,null, NOW()),
(20,201,'Job Monitoring IssueType','Job Monitoring IssueType','Classification - Excessive BySport Pool','Classification - Excessive BySport Pool',null,null,null,null,1,null, NOW()),
(20,500,'Job Monitoring IssueType','Job Monitoring IssueType','LoginTransaction - Excessive Login Process','LoginTransaction - Excessive Login Process',null,null,null,null,1,null, NOW());

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_InsertMissingCustomer;  
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_InsertMissingCustomer_xtest;  

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_InsertIncorrectCategory;  
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_InsertIncorrectCategory_xtest;  

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_Monitoring_InsertMissingCust_xtest;  

DROP TABLE IF EXISTS CTS_DataCenter.CTSCustomer_Missing; 
DROP TABLE IF EXISTS CTS_DataCenter.CTSCustomerClassification_IncorrectCategoryMonitor; 

DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_InsertMissingCusts;  
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_InsertMissingCusts_xtest;  