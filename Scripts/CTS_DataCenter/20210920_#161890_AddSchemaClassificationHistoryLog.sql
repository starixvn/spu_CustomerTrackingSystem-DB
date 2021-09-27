/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/

/*
Creator: 	20210920@Aries.Nguyen
Task:	 	Add schema classification hisotry log [Redmine ID: #161890]
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
CREATE TABLE `CTSCustomerClassification_Log` (
  `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `CustID` bigint unsigned DEFAULT NULL,
  `CTSCustID` bigint unsigned DEFAULT NULL,
  `SportGroupID` smallint unsigned DEFAULT NULL,
  `CategoryID` smallint DEFAULT NULL,
  `TurnoverRM` decimal(20,4) DEFAULT NULL,
  `WinlossRM` decimal(20,4) DEFAULT NULL,
  `BetCount` bigint DEFAULT NULL,
  `ActiveDays` int DEFAULT NULL,
  `RobotCounter` smallint DEFAULT NULL,
  `ProbationPeriodWinloss` decimal(20,4) DEFAULT NULL,
  `TargetCC` smallint DEFAULT NULL,
  `SourceTypeID` smallint unsigned DEFAULT NULL,
  `FromCategoryID` smallint unsigned DEFAULT NULL,
  `ToCategoryID` smallint unsigned DEFAULT NULL,
  `IsAppliedCC` bit(1) DEFAULT b'0',
  `IsDataChanged` bit(1) DEFAULT b'0',
  `ActionType` tinyint DEFAULT NULL,
  `IsAuto` bit(1) DEFAULT NULL,
  `LastModifiedDate` datetime DEFAULT NULL,
  `LastModifiedBy` int unsigned DEFAULT NULL,
  `InsertDate` datetime NOT NULL,
  `TaggingType` smallint DEFAULT '1',
  `TargetDangerLevel1` smallint DEFAULT NULL,
  `IsAppliedDangerLevel1` bit(1) DEFAULT b'0',
  `TWGroupBettingRate` decimal(10,4) DEFAULT NULL,
  `TWTicketRejectRate` decimal(10,4) DEFAULT NULL,
  `TWBetCount` bigint DEFAULT NULL,
  `TWDesktopUsageRate` decimal(10,4) DEFAULT NULL,
  PRIMARY KEY (`ID`,`InsertDate`),
  KEY `IX_CTSCustomerClassification_History_CustID` (`CustID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci
/*!50100 PARTITION BY RANGE (extract(year_month from `InsertDate`))
(PARTITION pm202108 VALUES LESS THAN (202109) ENGINE = InnoDB,
 PARTITION pm202109 VALUES LESS THAN (202110) ENGINE = InnoDB,
 PARTITION pm202110 VALUES LESS THAN (202111) ENGINE = InnoDB,
 PARTITION pm202111 VALUES LESS THAN (202112) ENGINE = InnoDB,
 PARTITION pm202112 VALUES LESS THAN (202201) ENGINE = InnoDB,
 PARTITION pm202201 VALUES LESS THAN (202202) ENGINE = InnoDB,
 PARTITION pm202202 VALUES LESS THAN (202203) ENGINE = InnoDB,
 PARTITION pm202203 VALUES LESS THAN (202204) ENGINE = InnoDB,
 PARTITION pm202204 VALUES LESS THAN (202205) ENGINE = InnoDB,
 PARTITION pm202205 VALUES LESS THAN (202206) ENGINE = InnoDB,
 PARTITION pm202206 VALUES LESS THAN (202207) ENGINE = InnoDB,
 PARTITION pm202207 VALUES LESS THAN (202208) ENGINE = InnoDB,
 PARTITION pm202208 VALUES LESS THAN (202209) ENGINE = InnoDB,
 PARTITION pm202209 VALUES LESS THAN (202210) ENGINE = InnoDB,
 PARTITION pm202210 VALUES LESS THAN (202211) ENGINE = InnoDB,
 PARTITION pm202211 VALUES LESS THAN (202212) ENGINE = InnoDB,
 PARTITION pm999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */
    

