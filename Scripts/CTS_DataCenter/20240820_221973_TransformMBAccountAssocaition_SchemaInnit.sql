/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250409@Casey.Huynh
Task:	 	Manual Script Sync data mobile association and Account to CTS
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250409@Casey.Huynh: Created [Redmine ID: #221973]
Reviewer:
*/
USE CTS_DataCenter;

#===================1. SCHEMA=================================
DROP TABLE CustDCSMBAccount;
DROP TABLE AssociationByMBDevice;

CREATE TABLE CustDCSMBAccount(
		MBAccountID 	BIGINT UNSIGNED NOT NULL
	,	CTSCustID 		BIGINT UNSIGNED NOT NULL	
	,	SubscriberID 	INT DEFAULT NULL
	,	InsertedTime 	DATETIME(4) NOT NULL
    
	,	PRIMARY KEY(MBAccountID)
	,	INDEX IX_CustDCSMBAccount_CTSCustID(CTSCustID) 
    
) ENGINE=InnoDB;

CREATE TABLE AssociationByMBDevice(
		AssID		 	BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	CTSCustID 		BIGINT UNSIGNED NOT NULL
	,	MBDeviceID 		BIGINT NOT NULL
	,	SubscriberID 	INT DEFAULT NULL
	,	CreatedTime 	DATETIME(4) NULL DEFAULT NULL
	,	InsertedTime 	DATETIME(4) NULL DEFAULT NULL
    
	,	PRIMARY KEY(AssID) 
	,	UNIQUE KEY 	IX_AssociationByMBDevice_CTSCustID_MBDeviceID(CTSCustID, MBDeviceID) 
    ,	INDEX 		IX_AssociationByMBDevice_MBDeviceID_CTSCustID(MBDeviceID, CTSCustID) 

) ENGINE=InnoDB;

#======================2. Initial Parameter=====================================
SELECT * FROM SystemParameter;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) 
VALUES(190,'Transform_DCSMBAccountToCTS','Keep the Last Transformed MBAccount.ID','BIGINT UNSIGNED','0')
	, (191,'Transform_DCSMBAssociationToCTS','Keep the Last Transformed MBAssocaition.ID','BIGINT UNSIGNED','0');

