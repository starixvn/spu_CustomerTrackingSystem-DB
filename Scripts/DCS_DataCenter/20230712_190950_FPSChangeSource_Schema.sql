/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Creator: 20230712@Casey.Huynh
Task:	 	Alter DCS_DataCenter.Association Index
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230712@Casey.Huynh: Created [#190950]
Reviewer:
*/

USE DCS_DataCenter;
ALTER TABLE Association
	DROP INDEX IX_Association_SubscriberID_AccountID_DeviceID
,	DROP INDEX IX_Association_CTSCustID_DeviceID_AccountID
,	ADD INDEX IX_Association_SubscriberID_AccountID_DeviceID_CreatedDate(SubscriberID,AccountID,DeviceID,CreatedDate)
,	ADD INDEX IX_Association_DeviceID_AccountID_CreatedDate(DeviceID,AccountID,CreatedDate);

/* =============================NOTES CURRENT SCHEMA PRO=============================
CREATE TABLE Association (
  AssociationID bigint unsigned NOT NULL AUTO_INCREMENT,
  DeviceID bigint unsigned NOT NULL,
  AccountID bigint unsigned NOT NULL,
  SubscriberID int NOT NULL,
  CreatedTime timestamp(4) NOT NULL,
  CreatedDate timestamp(4) NOT NULL,
  InsertTime timestamp(4) NOT NULL,
  IsCTSTransformed tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (AccountID,DeviceID),
  KEY IX_Association_SubscriberID_AccountID_DeviceID (SubscriberID,AccountID,DeviceID),
  KEY IX_Association_IsCTSTransformed (IsCTSTransformed),
  KEY IX_Association_CTSCustID_DeviceID_AccountID (DeviceID,AccountID),
  KEY KEY_AssociationID (AssociationID)
) ENGINE=InnoDB;
*/
