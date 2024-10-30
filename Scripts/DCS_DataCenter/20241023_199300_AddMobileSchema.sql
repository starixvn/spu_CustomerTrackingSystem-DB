/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20241023@Lando.Vu
	Task: Integrate Mobile App [Redmine ID: #199300]
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

/* ========= NEW TABLES ========= */
DROP TABLE IF EXISTS MB_RawTransaction;
CREATE TABLE `MB_RawTransaction` (
	`LoginName` varchar(100) NOT NULL,
	`SubscriberName` varchar(50) NOT NULL,
	`TransTime` timestamp(4) NOT NULL,
	`CreatedDate` datetime NOT NULL COMMENT 'Date Only',
	`IP` varchar(50) DEFAULT NULL,
	`IPID` decimal(50,0) DEFAULT NULL,
	`Action` varchar(100) DEFAULT NULL,
	`ActionResult` varchar(100) DEFAULT NULL,
	`TransStatus` bit(16) DEFAULT NULL COMMENT 'Refer Table TransStatus',
	`Flagged` smallint DEFAULT NULL,
	`IsProcessed` tinyint NOT NULL DEFAULT '0',
	`TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
	`MB_AndroidCode` varchar(32) DEFAULT NULL,
	`MB_CustomCode` varchar(32) DEFAULT NULL,
	`MB_MediaDRMCode` varchar(32) DEFAULT NULL,
	`MB_IsMobileApp` tinyint DEFAULT NULL,
	`MB_IsEmulator`tinyint DEFAULT NULL,
	`MB_ModelName` varchar(32) DEFAULT NULL,
	`MB_Manufacturer` varchar(32) DEFAULT NULL,
	`MB_Brand` varchar(32) DEFAULT NULL,
	`MB_SDKVersion` varchar(32) DEFAULT NULL,
	`MB_OS` varchar(32) DEFAULT NULL,
	`MB_Timezone` varchar(32) DEFAULT NULL,
	`MB_Language` varchar(32) DEFAULT NULL,
	`MB_Country` varchar(32) DEFAULT NULL,
	PRIMARY KEY (`TransID`),
	KEY `IX_RawTransaction_SubscriberName` (`SubscriberName`,`CreatedDate`)
) ENGINE=InnoDB;

