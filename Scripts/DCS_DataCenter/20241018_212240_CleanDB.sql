/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20241018@Jonathan.Doan [Redmine ID: #212240]
	Task: Drop tables and SP not used (#206403)
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

ALTER TABLE `DCS_DataCenter`.`RawTransaction`
DROP COLUMN `CookieID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `JsChallengeID`;

ALTER TABLE `DCS_DataCenter`.`ProcessedTransaction`
DROP COLUMN `CookieID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `JsChallengeID`;

ALTER TABLE `DCS_DataCenter`.`Transaction`
DROP COLUMN `CookieID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`;

ALTER TABLE `DCS_DataCenter`.`Transaction07`
DROP COLUMN `CookieID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`,
DROP COLUMN `FPDeviceID`,
DROP COLUMN `RecoverType`;
