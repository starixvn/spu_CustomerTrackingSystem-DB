/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20241003@Jonathan.Doan
	Task:	 	Drop tables and SP not used [Redmine ID: #206403]
	DBName:		DCS_DataTrace
*/

USE DCS_DataTrace;

DROP TABLE `DCS_DataTrace`.`RawUserAgent`;
DROP TABLE `DCS_DataTrace`.`Browser`;
DROP TABLE `DCS_DataTrace`.`OS`;
DROP TABLE `DCS_DataTrace`.`DeviceType`;

TRUNCATE TABLE `DCS_DataTrace`.`LoginTransactionSummaryByBrowser`;

DROP PROCEDURE IF EXISTS `DCS_DT_Summary_RawUserAgent_Insert`;