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
	, 	INDEX			IX_CTSCustomerClassification_JobMonitoring_IncorrectData_IssueTypeID(IssueTypeID)
) ENGINE=INNODB;

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('151', 'JobMonitoring_LastScanID', 'Get LastScanID to scan incorrect data', 'BIGINT UNSIGNED', '0');