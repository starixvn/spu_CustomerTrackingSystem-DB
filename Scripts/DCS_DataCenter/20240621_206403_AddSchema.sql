/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20240621@Jonathan.Doan [Redmine ID: #206403]
	Task: Change data flow v5.1
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

ALTER TABLE `DCS_DataCenter`.`RawTransaction`
ADD COLUMN `CookieCode` VARCHAR(64) NULL,
ADD COLUMN `RawFingerPrintCode` VARCHAR(64) NULL,
ADD COLUMN `BrowserInstanceCode` VARCHAR(64) NULL,
ADD COLUMN `RawUserAgentCode` VARCHAR(64) NULL,
ADD COLUMN `ChallengeCode` VARCHAR(50) NULL,
DROP COLUMN `CookieID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `JsChallengeID`;

ALTER TABLE `DCS_DataCenter`.`ProcessedTransaction`
ADD COLUMN `CookieCode` VARCHAR(64) NULL,
ADD COLUMN `RawFingerPrintCode` VARCHAR(64) NULL,
ADD COLUMN `BrowserInstanceCode` VARCHAR(64) NULL,
ADD COLUMN `RawUserAgentCode` VARCHAR(64) NULL,
ADD COLUMN `ChallengeCode` VARCHAR(50) NULL,
DROP COLUMN `CookieID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `JsChallengeID`;


ALTER TABLE `DCS_DataCenter`.`JSChallengeInfo`
CHANGE COLUMN `ChallengeCode` `ChallengeCode` VARCHAR(50) NOT NULL ;

ALTER TABLE `DCS_DataCenter`.`Cookie`
ADD COLUMN `FirstTransTime` TIMESTAMP(4);
