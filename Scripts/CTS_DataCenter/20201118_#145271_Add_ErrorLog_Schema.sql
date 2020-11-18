/*<info serverAlias="CTSMain-CTS_Log" databaseType="2"></info>*/
/*
Created: 20201018@Aries.Nguyen
Task: Add ErrorLog table schema.
DB: CTS_Log
*/
USE CTS_Log;
CREATE TABLE IF NOT EXISTS  `ErrorLog` (
  `RowID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `EventName` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `InsertedTime` datetime(4) DEFAULT NULL,
  `Message` varchar(500) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `Err_No` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Description` json DEFAULT NULL,
  PRIMARY KEY (`RowID`),
  KEY `IX_ErrorLog_InsertedTime` (`InsertedTime` DESC),
  KEY `IX_ErrorLog_EventName` (`EventName`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci