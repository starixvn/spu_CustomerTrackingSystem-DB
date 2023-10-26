/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20231018@Jonathan.Doan
	Task:	 	Build Report [Redmine ID: #195332]
	Server:  	Master
	DBName:		DCS_DataTrace
    
	Revisions: 
			- 20231018@Jonathan.Doan: Created [Redmine ID: #195332]
	Reviewer:
*/

USE DCS_DataTrace;

DROP TABLE DCS_DataTrace.LoginTransactionSummary;

CREATE TABLE `LoginTransactionSummary` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `TransDate` DATETIME NOT NULL,
  `SubscriberID` INT UNSIGNED DEFAULT NULL,
  `AccountID` BIGINT UNSIGNED DEFAULT NULL,
  `DeviceID` BIGINT UNSIGNED DEFAULT NULL,
  `Flagged` SMALLINT DEFAULT NULL,
  `TotalTrans` INT UNSIGNED DEFAULT NULL,
  `FlaggedGroupID` SMALLINT UNSIGNED DEFAULT NULL,
  `FirstLoginTransTime` DATETIME DEFAULT NULL,
  `LastLoginTransTime` DATETIME DEFAULT NULL,
  `CreatedTime` DATETIME DEFAULT NULL,
  `ModifiedTime` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`,`TransDate`),
  UNIQUE KEY `UX_LoginTransactionSummary_Group` (`TransDate`,`SubscriberID`,`AccountID`,`DeviceID`,`Flagged`),
  KEY `IX_LoginTransactionSummary_FlaggedGroupID` (`TransDate`,`SubscriberID`,`FlaggedGroupID`)
) ENGINE=InnoDB;
ALTER TABLE DCS_DataTrace.LoginTransactionSummary
    PARTITION BY RANGE (YEARWEEK(`TransDate`,0))(
    PARTITION pw202328 VALUES LESS THAN (202329),
    PARTITION pw202329 VALUES LESS THAN (202330),
    PARTITION pw202330 VALUES LESS THAN (202331),
    PARTITION pw202331 VALUES LESS THAN (202332),
    PARTITION pw202332 VALUES LESS THAN (202333),
    PARTITION pw202333 VALUES LESS THAN (202334),
    PARTITION pw202334 VALUES LESS THAN (202335),
    PARTITION pw202335 VALUES LESS THAN (202336),
    PARTITION pw202336 VALUES LESS THAN (202337),
    PARTITION pw202337 VALUES LESS THAN (202338),
    PARTITION pw202338 VALUES LESS THAN (202339),
    PARTITION pw202339 VALUES LESS THAN (202340),
    PARTITION pw202340 VALUES LESS THAN (202341),
    PARTITION pw202341 VALUES LESS THAN (202342),
    PARTITION pw202342 VALUES LESS THAN (202343),
    PARTITION pw202343 VALUES LESS THAN (202344),
    PARTITION pw202344 VALUES LESS THAN (202345),
	PARTITION pw299999 VALUES LESS THAN MAXVALUE);

CREATE TABLE DCS_DataTrace.LoginTransactionSummaryBySubscriber(
		ID 								INT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate						DATETIME NOT NULL
	, 	SubscriberID					INT UNSIGNED DEFAULT NULL
	, 	TotalTrans						INT UNSIGNED DEFAULT NULL
	, 	TotalInvalidBrowers				INT UNSIGNED DEFAULT NULL
	, 	TotalBotTrans					INT UNSIGNED DEFAULT NULL
	, 	CreatedTime						DATETIME DEFAULT NULL
	, 	ModifiedTime					DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	UNIQUE INDEX `UX_LoginTransactionSummaryBySubscriber_Group` (`TransDate`,`SubscriberID`)
) ENGINE=InnoDB;


DROP TABLE DCS_DataTrace.MissingTransaction;

CREATE TABLE DCS_DataTrace.MemberMissingTransaction(
		ID 							BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	MissingTransactionType		SMALLINT NOT NULL COMMENT '1: MissingLoginTransaction; 2: MissingBetTransaction'
	, 	TransDate					DATETIME NOT NULL
	, 	SubscriberID				INT UNSIGNED NOT NULL DEFAULT 0
	, 	CustID						INT UNSIGNED NOT NULL DEFAULT 0
	, 	CreatedTime					DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	INDEX `IX_MemberMissingTransaction_CustID` (`CustID`)
	,	INDEX `IX_MemberMissingTransaction_SubscriberID` (`SubscriberID`)
	,	UNIQUE INDEX `UX_MemberMissingTransaction_Group` (`TransDate`, `SubscriberID`, `MissingTransactionType`, `CustID`)
) ENGINE=InnoDB;

INSERT INTO DCS_DataTrace.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
VALUES(3, 'MissingTrans', 'LastScannedLoginTransDate', '2023-07-01', CURRENT_TIMESTAMP);

INSERT INTO DCS_DataTrace.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
VALUES(4, 'MissingTrans', 'LastScannedBetTransDate', '2023-07-01', CURRENT_TIMESTAMP);

SET sql_safe_updates = 0;
UPDATE DCS_DataTrace.LoginTransactionSummary AS trans
	LEFT JOIN DCS_DataCenter.StaticList AS sl ON sl.ListID = 1 AND sl.ItemID = trans.Flagged
SET trans.FlaggedGroupID = sl.GroupID;

DROP PROCEDURE IF EXISTS `DCS_DT_Report_DailyLoginTransactionSummary_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DT_Report_DeviceTransaction_Get`;