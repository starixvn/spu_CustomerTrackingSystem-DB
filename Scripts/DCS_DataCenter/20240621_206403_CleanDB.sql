/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20240621@Jonathan.Doan [Redmine ID: #206403]
	Task: Change Data Flow Ver. 6
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

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
