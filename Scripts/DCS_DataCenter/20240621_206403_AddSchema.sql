/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20240621@Jonathan.Doan [Redmine ID: #206403]
	Task: Change column in table RawTransaction
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

ALTER TABLE `DCS_DataCenter`.`RawTransaction`
ADD COLUMN `CookieCode` VARCHAR(64) NULL,
ADD COLUMN `RawFingerPrintCode` VARCHAR(64) NULL,
ADD COLUMN `BrowserInstanceCode` VARCHAR(64) NULL,
ADD COLUMN `RawUserAgentCode` VARCHAR(64) NULL,
ADD COLUMN `ChallengeCode` VARCHAR(64) NULL,
DROP COLUMN `CookieID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `JsChallengeID`;



ALTER TABLE `DCS_DataCenter`.`JSChallengeInfo`
CHANGE COLUMN `ChallengeCode` `ChallengeCode` VARCHAR(50) NOT NULL ;
