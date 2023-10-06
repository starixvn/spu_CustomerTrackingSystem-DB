/*<info serverAlias="CTSMain-DCS_DataWatch" databaseType="2"></info>*/
/*
	Creator:	20231003@Jonathan.Doan
	Task:	 	Create new DB DCS_DataWatch [Redmine ID: #194933]
	Server:  	Master
	DBName:		DCS_DataWatch
    
	Revisions: 
			- 20231003@Jonathan.Doan: Created [Redmine ID: #194933]
	Reviewer:
*/

-- CREATE DATABASE DCS_DataWatch;

USE DCS_DataWatch;


DROP TABLE IF EXISTS DCS_DataWatch.SystemSetting;

CREATE TABLE `SystemSetting` (
  `ID` INT NOT NULL,
  `VGroup` varchar(128) NOT NULL,
  `VName` varchar(128) NOT NULL,
  `VValue` varchar(255) NOT NULL,
  `UpdatedTime` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_SystemSetting_VGroup_VName` (`VGroup`,`VName`)
) ENGINE=InnoDB;

INSERT INTO DCS_DataWatch.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
VALUES(1, 'Summary', 'TransID', 0, CURRENT_TIMESTAMP);

INSERT INTO DCS_DataWatch.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
VALUES(2, 'MissingLoginTransaction', 'TransDate', '2023-01-01', CURRENT_TIMESTAMP);

DROP TABLE IF EXISTS DCS_DataWatch.LoginTransaction;

CREATE TABLE DCS_DataWatch.LoginTransaction(
		ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate			DATETIME NOT NULL
	, 	SubscriberID		INT UNSIGNED DEFAULT NULL
	, 	AccountID			BIGINT UNSIGNED DEFAULT NULL
	, 	DeviceID			BIGINT UNSIGNED DEFAULT NULL
	, 	Flagged				SMALLINT DEFAULT NULL
	, 	TotalTrans			INT UNSIGNED DEFAULT NULL
	, 	FirstLoginTransTime	DATETIME DEFAULT NULL
	, 	LastLoginTransTime	DATETIME DEFAULT NULL
	, 	CreatedTime			DATETIME DEFAULT NULL
	, 	ModifiedTime		DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	INDEX `IX_LoginTransaction_SubscriberID` (`SubscriberID`)
	,	INDEX `IX_LoginTransaction_AccountID` (`AccountID`)
	,	UNIQUE INDEX `UX_TransactionLite_Group` (`TransDate`,`AccountID`,`SubscriberID`,`DeviceID`,`Flagged`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS DCS_DataWatch.DailyLoginTransactionMonitoring;

CREATE TABLE DCS_DataWatch.DailyLoginTransactionMonitoring(
		ID 								INT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate						DATETIME NOT NULL
	, 	SubscriberID					INT UNSIGNED DEFAULT NULL
	, 	TotalTrans						INT UNSIGNED DEFAULT NULL
	, 	CreatedTime						DATETIME DEFAULT NULL
	, 	ModifiedTime					DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	UNIQUE INDEX `UX_DailyLoginTransactionMonitoring_Group` (`TransDate`,`SubscriberID`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS DCS_DataWatch.DailyRobotMonitoring;

CREATE TABLE DCS_DataWatch.DailyRobotMonitoring(
		ID 									BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	DailyLoginTransactionMonitoringID 	INT UNSIGNED NOT NULL
	, 	TotalInvalidBrowers					INT UNSIGNED DEFAULT NULL
	, 	TotalBotTrans						INT UNSIGNED DEFAULT NULL
	, 	CreatedTime							DATETIME DEFAULT NULL
	, 	ModifiedTime						DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	UNIQUE INDEX `UX_DailyRobotMonitoring_DailyLoginTransactionMonitoringID` (`DailyLoginTransactionMonitoringID`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS DCS_DataWatch.BetTicket;

CREATE TABLE DCS_DataWatch.BetTicket(
		ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate			DATETIME NOT NULL
	, 	CustID				INT UNSIGNED DEFAULT NULL
	, 	BetCount			INT UNSIGNED DEFAULT 0
	, 	FirstBetTicketTime	DATETIME DEFAULT NULL
	, 	LastBetTicketTime	DATETIME DEFAULT NULL
	, 	CreatedTime			DATETIME DEFAULT NULL
	, 	ModifiedTime		DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	UNIQUE INDEX `UX_BetTicket_TransDate_CustID` (`TransDate`,`CustID`)
	,	INDEX `IX_BetTicket_CustID` (`CustID`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS DCS_DataWatch.CustHistory;

CREATE TABLE DCS_DataWatch.CustHistory(
		ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate			DATETIME NOT NULL
	, 	CustID				INT UNSIGNED DEFAULT NULL
	, 	SubscriberID		INT UNSIGNED DEFAULT NULL
	, 	FirstLoginTransTime	DATETIME DEFAULT NULL
	, 	LastLoginTransTime	DATETIME DEFAULT NULL
	, 	FirstBetTicketTime	DATETIME DEFAULT NULL
	, 	LastBetTicketTime	DATETIME DEFAULT NULL
	, 	CreatedTime			DATETIME DEFAULT NULL
	, 	ModifiedTime		DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	UNIQUE INDEX `UX_CustHistory_TransDate_CustID` (`TransDate`,`CustID`)
	,	INDEX `IX_CustHistory_SubscriberID_CustID` (`SubscriberID`, `CustID`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS DCS_DataWatch.MissingLoginTransaction;

CREATE TABLE DCS_DataWatch.MissingLoginTransaction(
		ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate			DATETIME NOT NULL
	, 	CustID				INT UNSIGNED DEFAULT NULL
	, 	SubscriberID		INT UNSIGNED DEFAULT NULL
	, 	CreatedTime			DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	INDEX `IX_MissingLoginTransaction_CustID` (`CustID`)
	,	INDEX `IX_MissingLoginTransaction_SubscriberID` (`SubscriberID`)
	,	UNIQUE INDEX `UX_MissingLoginTransaction_TransDate_CustID` (`TransDate`,`CustID`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS DCS_DataWatch.MissingBetTicket;

CREATE TABLE DCS_DataWatch.MissingBetTicket(
		ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate			DATETIME NOT NULL
	, 	CustID				INT UNSIGNED DEFAULT NULL
	, 	SubscriberID		INT UNSIGNED DEFAULT NULL
	, 	CreatedTime			DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	INDEX `IX_MissingBetTicket_CustID` (`CustID`)
	,	INDEX `IX_MissingBetTicket_SubscriberID` (`SubscriberID`)
	,	UNIQUE INDEX `UX_MissingBetTicket_TransDate_CustID` (`TransDate`,`CustID`)
) ENGINE=InnoDB;