/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20240206@Jonathan.Doan
	Task:	 	Log data Fdi [Redmine ID: #200900]
	Server:  	Master
	DBName:		DCS_DataTrace
    
	Revisions: 
			- 20240206@Jonathan.Doan: Created [Redmine ID: #200900]
	Reviewer:
*/
USE DCS_DataTrace;

CREATE TABLE `DCSConsumer_Log` (
  `ID` INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `SessionKey` VARCHAR(100) DEFAULT NULL,
  `LoginName` VARCHAR(100) DEFAULT NULL,
  `SubscriberName` VARCHAR(50) DEFAULT NULL,
  `TransTime` TIMESTAMP(4) DEFAULT NULL,
  `UserAgent` VARCHAR(1000) DEFAULT NULL,
  `URL` VARCHAR(500) DEFAULT NULL,
  `CreatedDate` DATE DEFAULT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NULL,
  KEY `IX_DCSConsumer_Log_CreatedDate` (`CreatedDate`),
  KEY `IX_DCSConsumer_Log_SubscriberName_LoginName` (`SubscriberName`,`LoginName`)
) ENGINE=InnoDB;