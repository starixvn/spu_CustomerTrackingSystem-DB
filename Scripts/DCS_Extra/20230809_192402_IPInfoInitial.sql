/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2"></info>*/
/*
Creator:	20230809@Terry.Nguyen
Task:	 	New DB DCS_Extra
Server:  	Master
DBName:		DCS_Extra

Revisions: 
		- 20230809@Terry.Nguyen: Created [Redmine ID: #192402]
Reviewer:
*/


USE DCS_Extra;

CREATE TABLE `City` (
  `CityID` int NOT NULL AUTO_INCREMENT,
  `CityName` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`CityID`),
  UNIQUE KEY `UX_City_CityName` (`CityName`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

CREATE TABLE `Country` (
  `CountryID` int NOT NULL AUTO_INCREMENT,
  `CountryName` varchar(64) COLLATE utf8_unicode_ci NOT NULL,
  `CountryCode` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`CountryID`),
  UNIQUE KEY `UX_Country_CountryCode` (`CountryCode`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

CREATE TABLE `ISP` (
  `ISPID` int NOT NULL AUTO_INCREMENT,
  `ISPName` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`ISPID`),
  UNIQUE KEY `UX_ISP_ISPName` (`ISPName`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

CREATE TABLE `Region` (
  `RegionID` int NOT NULL AUTO_INCREMENT,
  `RegionName` varchar(128) COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`RegionID`),
  UNIQUE KEY `UX_Region_RegionName` (`RegionName`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

ALTER TABLE `DCS_Extra`.`RawTransaction` 
ADD COLUMN `CountryID` INT NULL AFTER `BotComponentID`,
ADD COLUMN `RegionID` INT NULL AFTER `CountryID`,
ADD COLUMN `CityID` INT NULL AFTER `RegionID`,
ADD COLUMN `ISPID` INT NULL AFTER `CityID`;

ALTER TABLE `DCS_Extra`.`ProcessedTransaction` 
ADD COLUMN `CountryID` INT NULL AFTER `BotComponentID`,
ADD COLUMN `RegionID` INT NULL AFTER `CountryID`,
ADD COLUMN `CityID` INT NULL AFTER `RegionID`,
ADD COLUMN `ISPID` INT NULL AFTER `CityID`;

ALTER TABLE `DCS_Extra`.`Transaction` 
ADD COLUMN `CountryID` INT NULL AFTER `BotComponentID`,
ADD COLUMN `RegionID` INT NULL AFTER `CountryID`,
ADD COLUMN `CityID` INT NULL AFTER `RegionID`,
ADD COLUMN `ISPID` INT NULL AFTER `CityID`;

ALTER TABLE `DCS_Extra`.`Transaction07` 
ADD COLUMN `CountryID` INT NULL AFTER `BotComponentID`,
ADD COLUMN `RegionID` INT NULL AFTER `CountryID`,
ADD COLUMN `CityID` INT NULL AFTER `RegionID`,
ADD COLUMN `ISPID` INT NULL AFTER `CityID`;

ALTER TABLE `DCS_Extra`.`Transaction07`
ADD INDEX IX_Transaction07_DeviceIDSubscriberID(DeviceID, SubscriberID),
ADD INDEX IX_Transaction07_CountryID_RegionID_CityID(CountryID, RegionID, CityID);

DELIMITER ;