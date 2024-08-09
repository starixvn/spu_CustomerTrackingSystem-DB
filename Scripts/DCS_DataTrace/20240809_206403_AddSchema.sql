/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20240809@Jonathan.Doan
	Task:	 	Create new DB DCS_DataTrace [Redmine ID: #206403]
	DBName:		DCS_DataTrace
*/

-- CREATE DATABASE DCS_DataTrace;

USE DCS_DataTrace;

DROP TABLE `DCS_DataTrace`.`RawUserAgent`;
DROP TABLE `DCS_DataTrace`.`Browser`;
DROP TABLE `DCS_DataTrace`.`OS`;
DROP TABLE `DCS_DataTrace`.`DeviceType`;

DROP PROCEDURE IF EXISTS `DCS_DT_Summary_RawUserAgent_Insert`;
