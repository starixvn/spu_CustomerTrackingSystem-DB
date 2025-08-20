/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250806@Jonathan.Doan [Redmine ID: #233405]
	Task: Change device rule 
	DB: DCS_DataCenter
*/
USE DCS_DataCenter;

ALTER TABLE DCS_DataCenter.MBRawTransaction
ADD DeviceDetails JSON;

DROP TABLE IF EXISTS MBDeviceMapping;
CREATE TABLE MBDeviceMapping (
  ID bigint unsigned NOT NULL AUTO_INCREMENT,
  MBDeviceCodeTaggingID bigint unsigned DEFAULT NULL,
  MBDeviceCodeMachineAccountID bigint unsigned DEFAULT NULL,
  MBDeviceCodeMachineMediaID bigint unsigned DEFAULT NULL,
  MBDeviceID bigint unsigned NOT NULL,
  FirstMBRawTransactionID bigint unsigned NOT NULL,
  RecoverType smallint NOT NULL COMMENT 'DCS_DataCenter.StaticList.ListID = 6',
  InsertedTime datetime NOT NULL,
  CreatedDate date DEFAULT NULL,
  PRIMARY KEY (ID),
  UNIQUE KEY UX_MBDeviceMapping_Group (MBDeviceCodeTaggingID,MBDeviceCodeMachineAccountID,MBDeviceCodeMachineMediaID),
  KEY IX_MBDeviceMapping_MBDeviceCodeTaggingID (MBDeviceCodeTaggingID),
  KEY IX_MBDeviceMapping_MBDeviceCodeMachineAccountID (MBDeviceCodeMachineAccountID),
  KEY IX_MBDeviceMapping_MBDeviceCodeMachineMediaID (MBDeviceCodeMachineMediaID),
  KEY IX_MBDeviceMapping_CreatedDate (CreatedDate)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS MBDeviceCodeMachineAccount;
CREATE TABLE MBDeviceCodeMachineAccount (
  ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  MBDeviceCodeMachineID BIGINT UNSIGNED NOT NULL,
  MBAccountID BIGINT UNSIGNED NOT NULL,
  CreatedDate DATE NULL,
  InsertedTime DATETIME NULL,
  PRIMARY KEY (ID),
  UNIQUE KEY UX_MBDeviceCodeMachineAccount_MBDeviceCodeMachineID_MBAccountID (MBDeviceCodeMachineID,MBAccountID),
  KEY IX_MBDeviceCodeMachineAccount_CreatedDate (CreatedDate)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS MBDeviceCodeMachineMedia;
CREATE TABLE MBDeviceCodeMachineMedia (
  ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  MBDeviceCodeMachineID BIGINT UNSIGNED NOT NULL,
  MBDeviceCodeMediaDRMID BIGINT UNSIGNED NOT NULL,
  CreatedDate DATE NULL,
  InsertedTime DATETIME NULL,
  PRIMARY KEY (ID),
  UNIQUE KEY UX_MBDeviceCodeMachineMedia_Unique (MBDeviceCodeMachineID,MBDeviceCodeMediaDRMID)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS MBTransaction;
CREATE TABLE MBTransaction (
  ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  MBRawTransactionID BIGINT UNSIGNED NOT NULL,
  TransTime DATETIME(4) NOT NULL,
  LoginName VARCHAR(100) NOT NULL,
  SubscriberID INT DEFAULT NULL,
  MBAccountID BIGINT UNSIGNED DEFAULT NULL,
  IP VARCHAR(50) DEFAULT NULL,
  IPID DECIMAL(50,0) DEFAULT NULL,
  ActionResultID INT DEFAULT NULL,
  Flagged SMALLINT DEFAULT NULL,
  MBDeviceCodeTaggingID BIGINT UNSIGNED DEFAULT NULL,
  MBDeviceCodeMachineAccountID BIGINT UNSIGNED DEFAULT NULL,
  MBDeviceCodeMachineMediaID BIGINT UNSIGNED DEFAULT NULL,
  MBDeviceModelID BIGINT UNSIGNED DEFAULT NULL,
  MBOSID BIGINT UNSIGNED DEFAULT NULL,
  MBUserSettingID BIGINT UNSIGNED DEFAULT NULL,
  InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (ID),
  UNIQUE KEY UX_MBTransaction_MBRawTransactionID (MBRawTransactionID)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS MBRawTransactionIOS;
CREATE TABLE MBRawTransactionIOS (
  ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  LoginName VARCHAR(100) NOT NULL,
  SubscriberName VARCHAR(50) NOT NULL,
  TransTime DATETIME(4) NOT NULL,
  IP VARCHAR(50) DEFAULT NULL,
  IPID decimal(50,0) DEFAULT NULL,
  Action VARCHAR(100) DEFAULT NULL,
  ActionResult VARCHAR(100) DEFAULT NULL,
  Flagged SMALLINT DEFAULT NULL,
  MBDeviceCodeMediaDRM VARCHAR(32) DEFAULT NULL,
  MBDeviceCodeMachine VARCHAR(32) DEFAULT NULL,
  MBDeviceCodeTagging VARCHAR(32) DEFAULT NULL,
  IsEmulator TINYINT DEFAULT NULL,
  ModelName VARCHAR(32) DEFAULT NULL,
  Manufacturer VARCHAR(32) DEFAULT NULL,
  Brand VARCHAR(32) DEFAULT NULL,
  SDKVersion VARCHAR(32) DEFAULT NULL,
  OSName VARCHAR(32) DEFAULT NULL,
  CountryName VARCHAR(32) DEFAULT NULL,
  Timezone VARCHAR(32) DEFAULT NULL,
  Language VARCHAR(32) DEFAULT NULL,
  InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  DeviceDetails JSON DEFAULT NULL,
  PRIMARY KEY (ID),
  KEY IX_MBRawTransactionIOS_SubscriberName (SubscriberName)
) ENGINE=InnoDB;
