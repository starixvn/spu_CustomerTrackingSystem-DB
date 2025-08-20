/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250806@Jonathan.Doan [Redmine ID: #233405]
	Task: Migrate MBData
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

DROP TABLE IF EXISTS DCS_DataCenter.MBProcessedTransaction_bk;
RENAME TABLE DCS_DataCenter.MBProcessedTransaction
TO DCS_DataCenter.MBProcessedTransaction_bk;

DROP TABLE IF EXISTS DCS_DataCenter.MBProcessedTransaction;
CREATE TABLE MBProcessedTransaction (
  ID bigint unsigned NOT NULL,
  CreatedDate datetime NOT NULL,
  LoginName varchar(100) NOT NULL,
  SubscriberName varchar(50) NOT NULL,
  TransTime datetime(4) NOT NULL,
  IP varchar(50) DEFAULT NULL,
  IPID decimal(50,0) DEFAULT NULL,
  Action varchar(100) DEFAULT NULL,
  ActionResult varchar(100) DEFAULT NULL,
  Flagged smallint DEFAULT NULL,
  MBDeviceCodeMediaDRM varchar(32) DEFAULT NULL,
  MBDeviceCodeMachine varchar(32) DEFAULT NULL,
  MBDeviceCodeTagging varchar(32) DEFAULT NULL,
  IsEmulator tinyint DEFAULT NULL,
  ModelName varchar(32) DEFAULT NULL,
  Manufacturer varchar(32) DEFAULT NULL,
  Brand varchar(32) DEFAULT NULL,
  SDKVersion varchar(32) DEFAULT NULL,
  OSName varchar(32) DEFAULT NULL,
  Timezone varchar(32) DEFAULT NULL,
  Language varchar(32) DEFAULT NULL,
  Country varchar(32) DEFAULT NULL,
  InsertedTime datetime NOT NULL,
  DeviceDetails json DEFAULT NULL,
  PRIMARY KEY (ID,CreatedDate),
  KEY IX_MBProcessedTransaction_CreatedDate_SubscriberName (CreatedDate,SubscriberName),
  KEY IX_MBProcessedTransaction_SubscriberName_LoginName (SubscriberName,LoginName)
) ENGINE=InnoDB
/*!50100 PARTITION BY RANGE (yearweek(CreatedDate,0))
(PARTITION pw202501 VALUES LESS THAN (202502) ENGINE = InnoDB,
PARTITION pw202502 VALUES LESS THAN (202503) ENGINE = InnoDB,
PARTITION pw202503 VALUES LESS THAN (202504) ENGINE = InnoDB,
PARTITION pw202504 VALUES LESS THAN (202505) ENGINE = InnoDB,
PARTITION pw202505 VALUES LESS THAN (202506) ENGINE = InnoDB,
PARTITION pw202506 VALUES LESS THAN (202507) ENGINE = InnoDB,
PARTITION pw202507 VALUES LESS THAN (202508) ENGINE = InnoDB,
PARTITION pw202508 VALUES LESS THAN (202509) ENGINE = InnoDB,
PARTITION pw202509 VALUES LESS THAN (202510) ENGINE = InnoDB,
PARTITION pw202510 VALUES LESS THAN (202511) ENGINE = InnoDB,
PARTITION pw202511 VALUES LESS THAN (202512) ENGINE = InnoDB,
PARTITION pw202512 VALUES LESS THAN (202513) ENGINE = InnoDB,
PARTITION pw202513 VALUES LESS THAN (202514) ENGINE = InnoDB,
PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

/* TRUNCATE ALL Mobile App data */
TRUNCATE TABLE DCS_DataCenter.MBAccount;
TRUNCATE TABLE DCS_DataCenter.MBAssociation;
TRUNCATE TABLE DCS_DataCenter.MBDevice;
TRUNCATE TABLE DCS_DataCenter.MBDeviceCodeMachine;
TRUNCATE TABLE DCS_DataCenter.MBDeviceCodeMediaDRM;
TRUNCATE TABLE DCS_DataCenter.MBDeviceCodeTagging;
TRUNCATE TABLE DCS_DataCenter.MBDeviceMapping;
TRUNCATE TABLE DCS_DataCenter.MBDeviceModel;
TRUNCATE TABLE DCS_DataCenter.MBOS;
TRUNCATE TABLE DCS_DataCenter.MBRawTransaction;
TRUNCATE TABLE DCS_DataCenter.MBTransaction;
TRUNCATE TABLE DCS_DataCenter.MBUserSetting;
TRUNCATE TABLE DCS_DataCenter.MBTransaction07;

/* Load initial data into MBRawTransaction */
USE CTS_Adhoc;

SET sql_safe_updates = 0;
CALL CTS_Adhoc.Adhoc_DCS_DC_Initial_MBRawTransaction(10000);