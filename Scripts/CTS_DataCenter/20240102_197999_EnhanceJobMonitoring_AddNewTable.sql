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
    , 	CreatedTime		DATETIME NOT NULL 
	, 	INDEX			IX_JobMonitoring_IncorrectData_IssueTypeID(IssueTypeID)
) ENGINE=INNODB;

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('151', 'JobMonitoring_LastScanID', 'Get LastScanID to scan incorrect data', 'BIGINT UNSIGNED', '0');

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_InsertMissingCustomer;  
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_InsertMissingCustomer_xtest;  

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_InsertIncorrectCategory;  
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_InsertIncorrectCategory_xtest;  

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_Monitoring_InsertMissingCust_xtest;  

DROP TABLE IF EXISTS CTS_DataCenter.CTSCustomer_Missing; 
DROP TABLE IF EXISTS CTS_DataCenter.CTSCustomerClassification_IncorrectCategoryMonitor; 

DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_InsertMissingCusts;  
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_InsertMissingCusts_xtest;  