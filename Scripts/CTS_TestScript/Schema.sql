USE MonDB;
CREATE TABLE `DBA_DummyData_CustClass` (
   `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
   `AccountType` enum('NewCustomer','Normal','Problem') DEFAULT NULL,
   `CustStatusID` int DEFAULT NULL,
   `Role` enum('Super','Master','Agent','Member') DEFAULT NULL COMMENT 'Super-4,Master-3,Agent-2,Member-1',
   `IsInternal` smallint DEFAULT '0',
   `IsLicensee` smallint DEFAULT '0',
   `IsExeptionRobot` smallint DEFAULT '0',
   `LastTicketDate` datetime DEFAULT NULL,
   `CategoryID` json DEFAULT NULL,
   `OldCategoryID` json DEFAULT NULL,
   `SpecialCC` int DEFAULT '0',
   `IsPin` smallint DEFAULT '0',
   `HasAIRobot` smallint DEFAULT '0',
   `RobotType` enum('None','Good','Bad') DEFAULT NULL,
   `UplineSuper_CategoryID` json DEFAULT NULL,
   `UplineSuper_OldCategoryID` json DEFAULT NULL,
   `UplineMaster_CategoryID` json DEFAULT NULL,
   `UplineMaster_OldCategoryID` json DEFAULT NULL,
   `UplineAgent_CategoryID` json DEFAULT NULL,
   `UplineAgent_OldCategoryID` json DEFAULT NULL,
   `ParamID` bigint DEFAULT '0',
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB;

 CREATE TABLE `DBA_DummyData_Param` (
   `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
   `ParamType` varchar(50) DEFAULT NULL,
   `CategoryID` int DEFAULT NULL,
   `CategoryGroup` int DEFAULT NULL,
   `ReasonID` int DEFAULT NULL,
   `EvidenceID` int DEFAULT NULL,
   `WinlossStatus` smallint DEFAULT NULL,
   `TurnoverRM` decimal(20,4) DEFAULT NULL,
   `WinlossRM` decimal(20,4) DEFAULT NULL,
   `BetCount` bigint DEFAULT NULL,
   `ActiveDays` int DEFAULT NULL,
   `RobotCounter` smallint DEFAULT NULL,
   `DWCateGroup` smallint unsigned DEFAULT NULL,
   `TWBetCount` bigint DEFAULT NULL,
   `TWGroupBettingRate` decimal(10,4) DEFAULT NULL,
   `TWTicketRejectRate` decimal(10,4) DEFAULT NULL,
   `TWDesktopUsageRate` decimal(10,4) DEFAULT NULL,
   `TaggingID` smallint DEFAULT NULL,
   `TaggingType` smallint DEFAULT NULL,
   `CreatedBy` int unsigned DEFAULT NULL,
   `Remark` varchar(500) DEFAULT NULL,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB;


 INSERT INTO `DBA_DummyData_CustClass` VALUES (1,'NewCustomer',1,'Member',0,0,0,NULL,NULL,NULL,0,0,0,NULL,'[201]',NULL,'[201]',NULL,'[201]',NULL,2),(2,'NewCustomer',1,'Member',0,1,0,NULL,NULL,NULL,0,0,0,NULL,'[201]',NULL,'[201]',NULL,'[201]',NULL,2),(3,'NewCustomer',1,'Member',0,0,0,NULL,NULL,NULL,0,0,0,NULL,'[210]','[55]','[201]',NULL,'[201]',NULL,2),(4,'NewCustomer',1,'Member',0,1,0,NULL,NULL,NULL,0,0,0,NULL,'[201]',NULL,'[205]',NULL,'[201]',NULL,2),(5,'NewCustomer',1,'Agent',0,0,0,NULL,NULL,NULL,0,0,0,NULL,'[201]',NULL,'[55]',NULL,NULL,NULL,2),(6,'Normal',1,'Member',0,0,1,'2022-05-30 02:09:48','[210]','[52]',0,0,0,NULL,'[201]',NULL,'[201]',NULL,'[201]',NULL,2),(7,'Normal',1,'Member',0,0,0,'2022-05-30 02:09:48','[201]',NULL,88,0,0,NULL,'[201]',NULL,'[201]',NULL,'[201]',NULL,0),(8,'Normal',1,'Member',0,1,1,'2022-05-30 02:09:48','[201]',NULL,0,0,1,'Good','[201]',NULL,'[201]',NULL,'[201]',NULL,2),(9,'Normal',1,'Member',0,0,1,'2022-05-30 02:09:48','[201]',NULL,0,1,0,NULL,'[201]',NULL,'[201]',NULL,'[201]',NULL,2),(10,'Normal',1,'Member',0,1,1,'2022-05-30 02:09:48','[201]',NULL,0,0,0,NULL,'[55]',NULL,'[52]',NULL,'[56]',NULL,2),(11,'Problem',1,'Member',0,0,0,'2022-05-30 02:09:48','[52, 55, 56]',NULL,0,0,1,'Bad','[201]',NULL,'[201]',NULL,'[201]',NULL,2),(12,'Problem',1,'Member',0,1,0,'2022-05-30 02:09:48','[52, 55, 56]',NULL,0,0,0,NULL,'[201]',NULL,'[201]',NULL,'[201]',NULL,2),(13,'Problem',1,'Member',0,0,0,'2022-05-30 02:09:48','[52, 55, 56]',NULL,0,0,0,NULL,'[201]',NULL,'[201]',NULL,'[201]',NULL,2),(14,'Problem',1,'Member',0,1,0,'2022-05-30 02:09:48','[52, 55, 56]',NULL,0,0,0,NULL,'[201]',NULL,'[201]',NULL,'[201]',NULL,2),(15,'Problem',1,'Member',0,0,1,'2022-05-30 02:09:48','[61, 63, 56]',NULL,0,0,1,'Good','[201]',NULL,'[201]',NULL,'[201]',NULL,2);



 INSERT INTO `DBA_DummyData_Param` VALUES (1,'InsertNormal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(2,'InsertPAByCategoryID',52,52,68,40,1,50000.0000,50000.0000,50,90,1212,1,2,3.0000,4.0000,5.0000,6,7,12313,'PA'),(3,'InsertPAByReason',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(4,'InsertPAByEvidence',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL),(5,'InsertVVIP',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL);
