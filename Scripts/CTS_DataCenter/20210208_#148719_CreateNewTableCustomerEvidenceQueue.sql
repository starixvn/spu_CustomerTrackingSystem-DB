/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210204@Long.Luu
Task:	 	Create new table CustEvidenceQueue [Redmine ID: #148719]
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

DROP TABLE IF EXISTS CTS_DataCenter.CustEvidenceQueue;

CREATE TABLE CTS_DataCenter.CustEvidenceQueue (
  `ID` 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `CTSCustID` 			BIGINT UNSIGNED NOT NULL,
  `CustID` 				INT UNSIGNED NOT NULL,
  `SubscriberID` 		INT UNSIGNED,
  `EvidenceID` 			SMALLINT UNSIGNED,
  `Remark` 				VARCHAR(500) DEFAULT NULL,
  `FileKey` 			VARCHAR(50) NOT NULL,
  `FileName` 			VARCHAR(200) DEFAULT NULL,
  `CreatedBy` 			INT NOT NULL,
  `CreatedTime` 		TIMESTAMP(4) NOT NULL,
  `ActionID` 			TINYINT UNSIGNED NOT NULL,
  `IsProcessed` 		BIT(1) DEFAULT b'0',
  `LastModifiedTime` 	DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `IX_CustEvidenceQueue_IsProcessed` (`IsProcessed`),
  KEY `IX_CustEvidenceQueue_CreatedTime` (`CreatedTime`),
  KEY `IX_CustEvidenceQueue_FileKey` (`FileKey`)
) ENGINE=InnoDB;
