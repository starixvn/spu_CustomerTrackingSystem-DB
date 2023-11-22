/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Created: 20232610@Teddy.le [Redmine ID: #195968]
	Task: Init Schema
	DB: DCS_DataTrace
*/

USE DCS_DataTrace;

CREATE TABLE `DCS_DataTrace`.`DailyLogTrailSummary` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `EventDate` DATE NOT NULL,
  `SubscriberID` INT UNSIGNED NULL DEFAULT 0,
  `SystemName` VARCHAR(45) NULL DEFAULT '',
  `Source` VARCHAR(100) NULL DEFAULT '',
  `Destination` VARCHAR(100) NULL DEFAULT '',
  `Method` VARCHAR(100) NULL DEFAULT '',
  `Total` INT UNSIGNED NULL DEFAULT NULL,
  `CreatedTime` DATETIME NULL DEFAULT NULL,
  `ModifiedTime` DATETIME NULL DEFAULT NULL,
  `Hash` VARCHAR(100) NULL DEFAULT NULL,
  PRIMARY KEY (`ID`, `EventDate`, `SubscriberID`),
  UNIQUE KEY `UX_DailyLogTrailSummary_Hash` (`Hash`))
ENGINE = InnoDB;