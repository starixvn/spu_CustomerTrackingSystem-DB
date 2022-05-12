USE MonDB;
CREATE TABLE `ReOrganizePartitionJob` (
   `ID` int unsigned NOT NULL AUTO_INCREMENT,
   `ServerID` int unsigned DEFAULT NULL,
   `Database` varchar(64) DEFAULT NULL,
   `Table` varchar(64) DEFAULT NULL,
   `PartitionType` enum('Weekly','Monthly') DEFAULT NULL,
   `PartitionPrefix` varchar(64) DEFAULT NULL,
   `PartitionMax` varchar(64) DEFAULT NULL,
   `DayRange` smallint unsigned DEFAULT NULL,
   `DateExecute` smallint unsigned DEFAULT NULL COMMENT 'WeekLy: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday. NOTE: GMT+7',
   `TimeExecute` time DEFAULT NULL COMMENT 'NOTE: GMT+7',
   `NotificationChannelID` int unsigned DEFAULT NULL,
   `HasAlert` bit(1) DEFAULT b'1',
   `LastExecuted` datetime DEFAULT NULL,
   `IsActive` bit(1) DEFAULT b'1',
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

 CREATE TABLE `DropPartitionJob` (
   `ID` int unsigned NOT NULL AUTO_INCREMENT,
   `ServerID` int unsigned DEFAULT NULL,
   `Database` varchar(64) DEFAULT NULL,
   `Table` varchar(64) DEFAULT NULL,
   `PartitionType` enum('Weekly','Monthly') DEFAULT NULL,
   `PartitionPrefix` varchar(64) DEFAULT NULL,
   `DayRange` smallint unsigned DEFAULT NULL,
   `DateExecute` smallint unsigned DEFAULT NULL COMMENT 'WeekLy: 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday. NOTE: GMT+7',
   `TimeExecute` time DEFAULT NULL COMMENT 'NOTE: GMT+7',
   `NotificationChannelID` int unsigned DEFAULT NULL,
   `HasAlert` bit(1) DEFAULT b'1',
   `LastExecuted` datetime DEFAULT NULL,
   `IsActive` bit(1) DEFAULT b'1',
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

 CREATE TABLE `SlowLogJob` (
   `ID` int unsigned NOT NULL AUTO_INCREMENT,
   `ServerID` int unsigned DEFAULT NULL,
   `NotificationChannelID` int unsigned DEFAULT NULL,
   `HasAlert` bit(1) DEFAULT b'1',
   `IsActive` bit(1) DEFAULT b'1',
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

 CREATE TABLE `SlowLog` (
   `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
   `ServerID` int unsigned NOT NULL,
   `Start_Time` timestamp(6) NOT NULL,
   `User_Host` mediumtext NOT NULL,
   `Query_Time` time(6) NOT NULL,
   `Lock_Time` time(6) NOT NULL,
   `Rows_Sent` int NOT NULL,
   `Rows_Examined` int NOT NULL,
   `DB` varchar(512) NOT NULL,
   `Last_Insert_ID` int NOT NULL,
   `Insert_ID` int NOT NULL,
   `Server_ID` int unsigned NOT NULL,
   `Sql_Text` longtext NOT NULL,
   `Thread_ID` bigint unsigned NOT NULL,
   `Created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`,`Created`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
 /*!50100 PARTITION BY RANGE (yearweek(`Created`,0))
 (PARTITION pw202215 VALUES LESS THAN (202216) ENGINE = InnoDB,
  PARTITION pw202216 VALUES LESS THAN (202217) ENGINE = InnoDB,
  PARTITION pw202217 VALUES LESS THAN (202218) ENGINE = InnoDB,
  PARTITION pw202218 VALUES LESS THAN (202219) ENGINE = InnoDB,
  PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;


  CREATE TABLE `FragmentationTableJob` (
   `ID` int unsigned NOT NULL AUTO_INCREMENT,
   `ServerID` int unsigned DEFAULT NULL,
   `Database` varchar(64) DEFAULT NULL,
   `Table` varchar(64) DEFAULT NULL,
   `NotificationChannelID` int unsigned DEFAULT NULL,
   `HasAlert` bit(1) DEFAULT b'1',
   `LastExecuted` datetime DEFAULT NULL,
   `IsActive` bit(1) DEFAULT b'1',
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;