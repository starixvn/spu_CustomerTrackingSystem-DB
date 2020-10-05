-- Step 1: Create DCS_DataCenter.RawTransaction from DCS_RawTransaction.RawTransaction
USE DCS_DataCenter;
CREATE TABLE `RawTransaction` (
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `SubscriberName` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `TransTime` timestamp(4) NOT NULL,
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
  `DeviceCode` varchar(62) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'DI DeviceCode: 32 characters is auto generated',
  `FingerprintCode` varchar(2000) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Device Fingerprint Codes, the hashcode bases on the set attributes',
  `FingerprintMoreInfo` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `UserAgent` text COLLATE utf8_unicode_ci,
  `IP` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `IPID` decimal(50,0) DEFAULT NULL,
  `PluginID` bigint(20) DEFAULT NULL,
  `URL` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Action` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ActionResult` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  `InvalidDevice` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `TransStatus` bit(16) DEFAULT NULL COMMENT 'Refer Table TransStatus',
  `FPSTransID` bigint(20) unsigned DEFAULT NULL,
  `Flagged` smallint(6) DEFAULT NULL,
  `IsProcessed` tinyint(4) NOT NULL DEFAULT '0',
  `TransID` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`TransID`,`CreatedDate`),
  KEY `IX_RawTransaction_IsProcessed` (`IsProcessed`),
  KEY `IX_RawTransaction_SubscriberName` (`SubscriberName`,`CreatedDate`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Step 2: Create partition for DCS_DataCenter.RawTransaction
ALTER  TABLE DCS_DataCenter.RawTransaction  
                PARTITION BY RANGE (yearweek(CreatedDate,0)) (
                PARTITION pw202036 VALUES LESS THAN (202036),
                PARTITION pw202037 VALUES LESS THAN (202037),
                PARTITION pw202038 VALUES LESS THAN (202038),
                PARTITION pw202039 VALUES LESS THAN (202039),
                PARTITION pw202040 VALUES LESS THAN (202040),
                PARTITION pw999999 VALUES LESS THAN MAXVALUE);
                
-- Set AUTO_INCREMENT for TransID
-- ALTER TABLE DCS_DataCenter.RawTransaction AUTO_INCREMENT={[MaxTransID(RawTransaction)] + 1}, ALGORITHM=INPLACE, LOCK=NONE;  

             

