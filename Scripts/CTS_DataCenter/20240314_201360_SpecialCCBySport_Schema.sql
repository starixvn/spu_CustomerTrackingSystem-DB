/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240314@Thomas.Nguyen
Task:	 	new history table for special CC by sport.
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240314@Thomas.Nguyen: Created [Redmine ID: #201360]
Reviewer:
*/

USE CTS_DataCenter;

ALTER TABLE CTSCustomerClassification_BySport_History
ADD Remark VARCHAR(500);

ALTER TABLE CTSCustomerClassification_BySport_History
ADD SourceTypeID SMALLINT;

ALTER TABLE CTSCustomerClassification_BySport_Log
ADD Remark VARCHAR(500);

ALTER TABLE CTSCustomerClassification_BySport_Log
ADD SourceTypeID SMALLINT;

CREATE TABLE SpecialCustomerClass_History 
(
	ID bigint unsigned NOT NULL AUTO_INCREMENT,
	CTSCustID bigint unsigned NOT NULL,
	CustID int unsigned NOT NULL,
	RootCTSCustID bigint unsigned NOT NULL,
	SubscriberID int NOT NULL,
	CustomerClass smallint DEFAULT NULL,
	CreatedBy int NOT NULL,
	CreatedDate datetime NOT NULL,
	LastModifiedBy int DEFAULT NULL,
	LastModifiedDate datetime DEFAULT NULL,
	CreatedFromFunction tinyint NOT NULL,
	ActionType tinyint,
	Remark varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
	PRIMARY KEY (ID),
	KEY IX_SpecialCustomerClass_History_CTSCustID (CTSCustID)
);

CREATE TABLE SpecialCustomerClass_BySport (
  CTSCustID bigint unsigned NOT NULL,
  CustID int unsigned NOT NULL,
  SportID SMALLINT UNSIGNED,
  SubscriberID int NOT NULL,
  CustomerClass smallint DEFAULT NULL,
  CreatedBy int NOT NULL,
  CreatedDate datetime NOT NULL,
  LastModifiedBy int DEFAULT NULL,
  LastModifiedDate datetime DEFAULT NULL,
  /*`CreatedFromFunction` tinyint NOT NULL COMMENT '1: Normal, 11: VVIP, 21: Pin Category',*/
  PRIMARY KEY (CTSCustID,SportID),
  KEY IX_SpecialCustomerClass_SubscriberID (SubscriberID),
  KEY IX_SpecialCustomerClass_CustID (CustID)
);


CREATE TABLE SpecialCustomerClass_BySport_History 
(
	ID bigint unsigned NOT NULL AUTO_INCREMENT,
	CTSCustID bigint unsigned NOT NULL,
	CustID int unsigned NOT NULL,
	SportID SMALLINT UNSIGNED,
	SubscriberID int NOT NULL,
	CustomerClass smallint DEFAULT NULL,
	CreatedBy int NOT NULL,
	CreatedDate datetime NOT NULL,
	LastModifiedBy int DEFAULT NULL,
	LastModifiedDate datetime DEFAULT NULL,
	ActionType tinyint,
	Remark varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
	PRIMARY KEY (ID),
	KEY IX_SpecialCustomerClass_History_CTSCustID (CTSCustID)
);