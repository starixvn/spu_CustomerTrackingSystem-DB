USE MonDB;
CREATE TABLE `ArchivePartitionJob` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `SourceServerID` int unsigned DEFAULT NULL,
  `SourceMasterServerID` int unsigned DEFAULT NULL,
  `SourceDatabase` varchar(64) DEFAULT NULL,
  `SourceTable` varchar(64) DEFAULT NULL,
  `DesServerID` int unsigned DEFAULT NULL,
  `DesDatabase` varchar(64) DEFAULT NULL,
  `DesTable` varchar(64) DEFAULT NULL,
  `PartitionType` enum('Weekly','Monthly') DEFAULT NULL,
  `PartitionPrefix` varchar(64) DEFAULT NULL,
  `PartitionDelimiter` varchar(5) DEFAULT NULL,
  `PartitionMax` varchar(64) DEFAULT NULL,
  `KeepDataRange` int unsigned DEFAULT NULL,
  `DateExecute` smallint unsigned DEFAULT NULL COMMENT 'WeekLy: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday. NOTE: GMT+7',
  `TimeExecute` time DEFAULT NULL COMMENT 'NOTE: GMT+7',
  `HasDropPartitionSourceTable` bit(1) DEFAULT b'0',
  `NotificationChannelID` int unsigned DEFAULT NULL,
  `HasAlert_Pre` bit(1) DEFAULT b'1',
  `DateAlert_Pre` date DEFAULT NULL,
  `IsAlerted_Pre` bit(1) DEFAULT b'0',
  `HasAlert_Done` bit(1) DEFAULT b'1',
  `LastExecuted` datetime DEFAULT NULL,
  `LastExecuteStatus` enum('Waiting','Processing','Processed') DEFAULT NULL,
  `RunType` varchar(20)  NOT NULL,
  `Created` datetime DEFAULT CURRENT_TIMESTAMP,
  `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE `ArchivePartition_Log` (
   `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
   `ArchivePartitionJob` int unsigned DEFAULT NULL,
   `Message` longtext,
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

 CREATE TABLE `MysqlServer` (
   `ID` int unsigned NOT NULL AUTO_INCREMENT,
   `DBATaskStatus` varchar(50) DEFAULT NULL,
   `SystemName` varchar(64) DEFAULT NULL,
   `SystemRole` varchar(64) DEFAULT NULL,
   `ServerName` varchar(64) DEFAULT NULL,
   `ContainerName` varchar(64) DEFAULT NULL,
   `ServerIP` varchar(50) DEFAULT NULL,
   `ServerPort` varchar(50) DEFAULT NULL,
   `MysqlUserHost` varchar(64) DEFAULT NULL,
   `MysqlGroupHost` varchar(64) DEFAULT NULL,
   `MysqlUser` varchar(64) DEFAULT NULL,
   `MysqlPassword` varchar(64) DEFAULT NULL,
   `LoginPathInfo` varchar(200) DEFAULT NULL,
   `SSHUser` varchar(64) DEFAULT NULL,
   `SSHPassword` varchar(64) DEFAULT NULL,
   `SSHKey_File` varchar(200) DEFAULT NULL,
   `DataPath` varchar(200) DEFAULT NULL,
   `DataFileOwner` varchar(64) DEFAULT NULL,
   `BinlogPath` varchar(200) DEFAULT NULL,
   `ConfigPath` varchar(200) DEFAULT NULL,
   `Description` varchar(500) DEFAULT NULL,
   `IsActive` bit(1) DEFAULT b'1',
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

 CREATE TABLE `NotificationChannel` (
   `ID` int unsigned NOT NULL AUTO_INCREMENT,
   `Name` varchar(64) DEFAULT NULL,
   `SystemName` varchar(64) DEFAULT NULL,
   `ChannelType` enum('Telegram','Skype','Mail') DEFAULT NULL,
   `MetaData` json DEFAULT NULL,
   `Description` varchar(500) DEFAULT NULL,
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;