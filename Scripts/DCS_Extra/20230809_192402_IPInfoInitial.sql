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

CREATE TABLE `IPInfo` (
  `IPInfoID` 			INT NOT NULL AUTO_INCREMENT,
  `IPInfoCode`		BIGINT COLLATE utf8_unicode_ci NOT NULL,
  `Country` 		VARCHAR(128) COLLATE utf8_unicode_ci NOT NULL,
  `CountryCode` 	VARCHAR(45)  COLLATE utf8_unicode_ci NOT NULL,
  `City` 			VARCHAR(128) COLLATE utf8_unicode_ci NOT NULL,
  `Region` 			VARCHAR(128) COLLATE utf8_unicode_ci NOT NULL,
  `ISP` 			VARCHAR(128) COLLATE utf8_unicode_ci NOT NULL, 
  
  PRIMARY KEY (`IPInfoID`),
  UNIQUE KEY `UX_IPInfo_IPInfoCode` (`IPInfoCode`),
  FULLTEXT `IX_IPInfo_IPInfo` (`CountryCode`,`Region`,`City`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

ALTER TABLE `DCS_Extra`.`RawTransaction` 
ADD COLUMN `IPInfoID` INT NULL AFTER `BotComponentID`;

ALTER TABLE `DCS_Extra`.`ProcessedTransaction` 
ADD COLUMN `IPInfoID` INT NULL AFTER `BotComponentID`;

ALTER TABLE `DCS_Extra`.`Transaction` 
ADD COLUMN `IPInfoID` INT NULL AFTER `BotComponentID`;

ALTER TABLE `DCS_Extra`.`Transaction07` 
ADD COLUMN `IPInfoID` INT NULL AFTER `BotComponentID`;

ALTER TABLE `DCS_Extra`.`Transaction07`
ADD INDEX IX_Transaction07_DeviceIDSubscriberID(DeviceID, SubscriberID),
ADD INDEX IX_Transaction07_IPInfoID(IPInfoID),
ADD INDEX IX_Transaction07_IPID(IPID);

DELIMITER ;