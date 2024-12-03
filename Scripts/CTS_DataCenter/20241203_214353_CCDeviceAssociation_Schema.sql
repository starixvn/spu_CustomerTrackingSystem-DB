/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240617@Thomas.Nguyen
Task:	 	add tables
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240617@Thomas.Nguyen: Created [Redmine ID: #205317]
Reviewer:
*/

USE CTS_DataCenter;

CREATE TABLE DangerousAssociation
(
	ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	CustID BIGINT UNSIGNED NOT NULL,
	IsDisabled BIT(1) DEFAULT 0,
	InsertedTime DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
	ArchivedDate DATETIME,
	PRIMARY KEY (ID),
	KEY IX_DangerousAssociation_CustID_IsDisabled (CustID, IsDisabled)
);

CREATE TABLE DangerousAssociation_DevicePool
(
	ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
	CTSCustID BIGINT UNSIGNED NOT NULL,
    DCSDeviceID BIGINT,
	InsertedTime DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
	PRIMARY KEY (ID),
	KEY IX_DangerousAssociation_DevicePool_CTSCustID_DCSDeviceID (CTSCustID, DCSDeviceID)
);
