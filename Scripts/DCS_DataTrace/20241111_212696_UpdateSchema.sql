/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20241111@Jonathan.Doan
	Task:	 	Update DataType & clean data [Redmine ID: #212696]
	DBName:		DCS_DataTrace
*/

USE DCS_DataTrace;

DROP TABLE IF EXISTS DCSConsumer_Log;
CREATE TABLE `DCSConsumer_Log` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `LogType` SMALLINT DEFAULT NULL COMMENT 'DCS_DataCenter.StaticList.ListID = 3',
  `Environment` VARCHAR(10) DEFAULT NULL,
  `ScriptVersion` VARCHAR(10) DEFAULT NULL,
  `SessionKey` VARCHAR(500) DEFAULT NULL,
  `Tagging` VARCHAR(500) DEFAULT NULL,
  `LoginName` VARCHAR(100) DEFAULT NULL,
  `SubscriberName` VARCHAR(50) DEFAULT NULL,
  `TransTime` TIMESTAMP(4) NULL DEFAULT NULL,
  `UserAgent` VARCHAR(1000) DEFAULT NULL,
  `URL` VARCHAR(500) DEFAULT NULL,
  `CreatedDate` DATE NULL,
  `InsertedTime` TIMESTAMP NULL,
  PRIMARY KEY (`ID`),
  KEY `IX_DCSConsumer_Log_CreatedDate_LogType` (`CreatedDate`,`LogType`),
  KEY `IX_DCSConsumer_Log_CreatedDate_SubscriberName_LoginName` (`CreatedDate`,`SubscriberName`,`LoginName`)
) ENGINE=InnoDB;

