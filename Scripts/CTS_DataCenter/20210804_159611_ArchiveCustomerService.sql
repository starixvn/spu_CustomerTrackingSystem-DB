/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210804@Casey.Huynh
Task:	 	Schema Init Archive Customer Service [Redmine: #159611]
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
	-	20210804@Casey.Huynh: Created [Redmine: #159611]
Reviewer:
*/
USE CTS_DataCenter;
CREATE TABLE ArchiveCustomer_CTSCustomer(
		ArchivedDateMainDB DATETIME(3)
	,	CTSCustID BIGINT UNSIGNED NOT NULL
	,	SubscriberID INT UNSIGNED DEFAULT NULL
	,	CustID INT UNSIGNED DEFAULT NULL
	,	CustSubID INT UNSIGNED DEFAULT NULL
	,	UserName VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
	,	UserName2 VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
	,	RoleID TINYINT DEFAULT NULL
    ,	InsertTime DATETIME(3)
  
    ,	PRIMARY KEY (ArchivedDateMainDB, CTSCustID)
    ,	INDEX  IX_ArchiveCustomer_CTSCustomer_CTSCustID (CTSCustID)
    ,	INDEX  IX_ArchiveCustomer_CTSCustomerUserName (UserName)
    ,	INDEX  IX_ArchiveCustomer_CTSCustomer_CustID (CustID)    
) ENGINE=InnoDB;

INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES	(24, 'ArchiveCustomer_LastTime', 'Last Archive Time', 'DATETIME(3)', '2021-06-10 00:00:00')
	,	(24, 'ArchiveCustomer_LastCustID', 'Last CustID per Archive Time', 'INT UNSIGNED', '2021-06-10 00:00:00');

;SELECT * FROM SystemParameter;



