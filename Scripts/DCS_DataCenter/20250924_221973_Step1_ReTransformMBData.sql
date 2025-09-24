/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250924@Jonathan.Doan [Redmine ID: #221973]
	Task: Re-transform MBData from July 1
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

UPDATE DCS_DataCenter.SystemSetting 
SET VValue = 0
WHERE ID IN (4, 30);

UPDATE DCS_DataCenter.SystemSetting 
SET VValue = 8056354
WHERE ID = 1002;

DROP TABLE IF EXISTS DCS_DataCenter.MBProcessedTransaction_bk;
RENAME TABLE DCS_DataCenter.MBProcessedTransaction
TO DCS_DataCenter.MBProcessedTransaction_bk;

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
/*!50100 PARTITION BY RANGE (yearweek(CreatedDate,0)) (
  PARTITION pw202527 VALUES LESS THAN (202528) ENGINE = InnoDB,
  PARTITION pw202528 VALUES LESS THAN (202529) ENGINE = InnoDB,
  PARTITION pw202529 VALUES LESS THAN (202530) ENGINE = InnoDB,
  PARTITION pw202530 VALUES LESS THAN (202531) ENGINE = InnoDB,
  PARTITION pw202531 VALUES LESS THAN (202532) ENGINE = InnoDB,
  PARTITION pw202532 VALUES LESS THAN (202533) ENGINE = InnoDB,
  PARTITION pw202533 VALUES LESS THAN (202534) ENGINE = InnoDB,
  PARTITION pw202534 VALUES LESS THAN (202535) ENGINE = InnoDB,
  PARTITION pw202535 VALUES LESS THAN (202536) ENGINE = InnoDB,
  PARTITION pw202536 VALUES LESS THAN (202537) ENGINE = InnoDB,
  PARTITION pw202537 VALUES LESS THAN (202538) ENGINE = InnoDB,
  PARTITION pw202538 VALUES LESS THAN (202539) ENGINE = InnoDB,
  PARTITION pw202539 VALUES LESS THAN (202540) ENGINE = InnoDB,
  PARTITION pwmax    VALUES LESS THAN MAXVALUE ENGINE = InnoDB
); */;

/* TRUNCATE ALL Mobile App data */
TRUNCATE TABLE DCS_DataCenter.MBAccount;
TRUNCATE TABLE DCS_DataCenter.MBAssociation;
TRUNCATE TABLE DCS_DataCenter.MBDevice;
TRUNCATE TABLE DCS_DataCenter.MBDeviceCodeMachine;
TRUNCATE TABLE DCS_DataCenter.MBDeviceCodeMachineAccount;
TRUNCATE TABLE DCS_DataCenter.MBDeviceCodeMachineMedia;
TRUNCATE TABLE DCS_DataCenter.MBDeviceCodeMediaDRM;
TRUNCATE TABLE DCS_DataCenter.MBDeviceCodeTagging;
TRUNCATE TABLE DCS_DataCenter.MBDeviceMapping;
TRUNCATE TABLE DCS_DataCenter.MBDeviceModel;
TRUNCATE TABLE DCS_DataCenter.MBOS;
TRUNCATE TABLE DCS_DataCenter.MBRawTransaction;
TRUNCATE TABLE DCS_DataCenter.MBRawTransactionIOS;
TRUNCATE TABLE DCS_DataCenter.MBTransaction;
TRUNCATE TABLE DCS_DataCenter.MBUserSetting;
TRUNCATE TABLE DCS_DataCenter.MBTransaction07;