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

DROP TABLE IF EXISTS DCSConsumer_Log;

CREATE TABLE `DCSConsumer_Log` (
  `ID` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `LogType` SMALLINT DEFAULT NULL COMMENT '1: SessionKey is Null; 2: SessionKey is Empty; 3: RedisValue is Empty',
  `SessionKey` VARCHAR(100) DEFAULT NULL,
  `LoginName` VARCHAR(100) DEFAULT NULL,
  `SubscriberName` VARCHAR(50) DEFAULT NULL,
  `TransTime` TIMESTAMP(4) DEFAULT NULL,
  `UserAgent` VARCHAR(1000) DEFAULT NULL,
  `URL` VARCHAR(500) DEFAULT NULL,
  `CreatedDate` DATE DEFAULT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NULL,
  KEY `IX_DCSConsumer_Log_LogType_CreatedDate` (`LogType`,`CreatedDate`),
  KEY `IX_DCSConsumer_Log_SubscriberName_LoginName` (`SubscriberName`,`LoginName`)
) ENGINE=InnoDB;


INSERT INTO `DCS_DataTrace`.`StaticList` (`ListID`, `ListCode`, `ListName`, `ItemID`, `ItemCode`, `ItemName`, `Status`, `CreatedDate`) 
VALUES 	(2, 'DCSConsumer_LogType', 'DCSConsumer_LogType', 1, 'SessionKeyNull', 'SessionKey is Null', '1', CURRENT_TIMESTAMP())
	,	(2, 'DCSConsumer_LogType', 'DCSConsumer_LogType', 2, 'SessionKeyEmpty', 'SessionKey is Empty', '1', CURRENT_TIMESTAMP())
	,	(2, 'DCSConsumer_LogType', 'DCSConsumer_LogType', 3, 'RedisValueEmpty', 'RedisValue is Empty', '1', CURRENT_TIMESTAMP());
