Use DCS_DataCenter;
CREATE TABLE `zzHF184827_RawTransaction` (
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `SubscriberName` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `TransTime` timestamp(4) NOT NULL,
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
  `DeviceCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FingerprintCode` varchar(620) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FingerprintMoreInfo` varchar(250) COLLATE utf8_unicode_ci DEFAULT NULL,
  `UserAgent` varchar(1000) COLLATE utf8_unicode_ci DEFAULT NULL,
  `IP` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `IPID` decimal(50,0) DEFAULT NULL,
  `PluginID` bigint DEFAULT NULL,
  `URL` varchar(500) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `Action` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `ActionResult` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `InvalidDevice` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TransStatus` bit(16) DEFAULT NULL COMMENT 'Refer Table TransStatus',
  `FPSTransID` bigint unsigned DEFAULT NULL,
  `Flagged` smallint DEFAULT NULL,
  `IsProcessed` tinyint NOT NULL DEFAULT '0',
  `TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `InsertTime` timestamp(4) NULL DEFAULT NULL,
  PRIMARY KEY (`TransID`,`CreatedDate`),
  KEY `IX_RawTransaction_IsProcessed` (`IsProcessed`),
  KEY `IX_RawTransaction_SubscriberName` (`SubscriberName`,`CreatedDate`)
) ENGINE=InnoDB ;

SELECT COUNT(1) FROM DCS_DataCenter.RawTransaction WHERE CreatedDate < '2023-03-28'; 

Insert into zzHF184827_RawTransaction
SELECT * FROM DCS_DataCenter.RawTransaction WHERE CreatedDate < '2023-03-28';

DELETE rt
FROM DCS_DataCenter.RawTransaction rt
WHERE  CreatedDate < '2023-03-28';

DELETE rt
FROM DCS_DataCenter.Transaction rt
WHERE  CreatedDate < '2023-03-28';

