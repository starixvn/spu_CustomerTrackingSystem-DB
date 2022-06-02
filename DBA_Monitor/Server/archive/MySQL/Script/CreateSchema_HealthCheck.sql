USE MonDB;
CREATE TABLE `HealthCheck_Alert_Cached` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `ServerID` int unsigned DEFAULT NULL,
  `HealthCheckType` varchar(50),
  `ThreadID` bigint unsigned DEFAULT '0',
  `Created` datetime DEFAULT CURRENT_TIMESTAMP,
  `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



CREATE TABLE `HealthCheck_BigQueryJob` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `ServerID` int unsigned DEFAULT NULL,
  `Threshold` int DEFAULT '180',
  `ThresholdApp` int DEFAULT '180',
  `ThresholdRowLocked` int DEFAULT '20000',
  `NotificationChannelID` int unsigned DEFAULT NULL,
  `IsActive` bit(1) DEFAULT b'1',
  `Created` datetime DEFAULT CURRENT_TIMESTAMP,
  `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `HealthCheck_BigQueryJob` VALUES (1,8,2,1,1,2,_binary '','2022-06-02 03:31:39','2022-06-07 05:32:24');



CREATE TABLE `HealthCheck_MemoryJob` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `ServerID` int unsigned DEFAULT NULL,
  `Threshold` smallint DEFAULT '50',
  `NotificationChannelID` int unsigned DEFAULT NULL,
  `IsActive` bit(1) DEFAULT b'1',
  `Created` datetime DEFAULT CURRENT_TIMESTAMP,
  `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `HealthCheck_MemoryJob` VALUES (1,8,40,2,_binary '','2022-06-06 00:02:18','2022-06-06 00:02:18');



CREATE TABLE `HealthCheck_ReplicationJob` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `ServerID` int unsigned DEFAULT NULL,
  `Threshold` int DEFAULT '180',
  `NotificationChannelID` int unsigned DEFAULT NULL,
  `IsActive` bit(1) DEFAULT b'1',
  `Created` datetime DEFAULT CURRENT_TIMESTAMP,
  `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `HealthCheck_ReplicationJob` VALUES (1,6,180,2,_binary '','2022-06-02 02:56:43','2022-06-07 04:41:56');



CREATE TABLE `HealthCheck_StorageJob` (
  `ID` int unsigned NOT NULL AUTO_INCREMENT,
  `ServerID` int unsigned DEFAULT NULL,
  `FileSystem` varchar(200) DEFAULT NULL,
  `Threshold` smallint DEFAULT '50',
  `NotificationChannelID` int unsigned DEFAULT NULL,
  `IsActive` bit(1) DEFAULT b'1',
  `Created` datetime DEFAULT CURRENT_TIMESTAMP,
  `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB  CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
INSERT INTO `HealthCheck_StorageJob` VALUES (1,8,'/dev/mapper/ubuntu--vg-root ',50,2,_binary '','2022-06-02 02:46:59','2022-06-06 00:00:00');