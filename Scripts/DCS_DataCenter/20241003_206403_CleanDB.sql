/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20241003@Jonathan.Doan [Redmine ID: #206403]
	Task: Drop tables and SP not used
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

DELETE FROM `DCS_DataCenter`.`SystemSetting`
WHERE ID IN (1000, 1001);

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

DROP TABLE `DCS_DataCenter`.`Cookie`;
DROP TABLE `DCS_DataCenter`.`RawFingerPrint`;
DROP TABLE `DCS_DataCenter`.`FingerPrintAttribute`;
DROP TABLE `DCS_DataCenter`.`BrowserInstance`;
DROP TABLE `DCS_DataCenter`.`BrowserInstanceRawFingerPrint`;
DROP TABLE `DCS_DataCenter`.`RawUserAgent`;
DROP TABLE `DCS_DataCenter`.`DeviceCookie`;
DROP TABLE `DCS_DataCenter`.`FPDevice`;
DROP TABLE `DCS_DataCenter`.`FPDeviceFingerPrint`;
DROP TABLE `DCS_DataCenter`.`AccountFingerprint`;
DROP TABLE `DCS_DataCenter`.`EvolvedTransaction`;
DROP TABLE `DCS_DataCenter`.`AssociationMapping`;
DROP TABLE `DCS_DataCenter`.`AssociationNew`;

DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Cookie_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_RawUserAgent_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_RawFingerPrint_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_FingerprintAttribute_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_BrowserInstance_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_Transaction07_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Evolution_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_EvolvedTransaction_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Evolution_GetAttributes`;
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_AccountFingerPrint_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Device_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Device_Recover`;
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_Device_UpdateExistsDeviceID`;
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_DeviceCookie_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_DeviceFingerPrint_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DC_Identity_TransactionEvolution_Insert`;
