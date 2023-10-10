/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20231003@Jonathan.Doan
	Task:	 	Create new DB DCS_DataTrace [Redmine ID: #194933]
	Server:  	Master
	DBName:		DCS_DataTrace
    
	Revisions: 
			- 20231003@Jonathan.Doan: Created [Redmine ID: #194933]
	Reviewer:
*/

-- CREATE DATABASE DCS_DataTrace;

USE DCS_DataTrace;


DROP TABLE IF EXISTS DCS_DataTrace.SystemSetting;

CREATE TABLE `SystemSetting` (
  `ID` INT NOT NULL,
  `VGroup` varchar(128) NOT NULL,
  `VName` varchar(128) NOT NULL,
  `VValue` varchar(255) NOT NULL,
  `UpdatedTime` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_SystemSetting_VGroup_VName` (`VGroup`,`VName`)
) ENGINE=InnoDB;

INSERT INTO DCS_DataTrace.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
VALUES(1, 'Summary', 'TransID', 0, CURRENT_TIMESTAMP);

INSERT INTO DCS_DataTrace.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
VALUES(2, 'Summary', 'MaxBetTicketDate', '2023-01-01', CURRENT_TIMESTAMP);

DROP TABLE IF EXISTS DCS_DataTrace.LoginTransaction;

CREATE TABLE DCS_DataTrace.LoginTransaction(
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
	,	UNIQUE INDEX `UX_LoginTransaction_Group` (`TransDate`,`AccountID`,`SubscriberID`,`DeviceID`,`Flagged`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS DCS_DataTrace.DailyLoginTransactionMonitoring;

CREATE TABLE DCS_DataTrace.DailyLoginTransactionMonitoring(
		ID 								INT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate						DATETIME NOT NULL
	, 	SubscriberID					INT UNSIGNED DEFAULT NULL
	, 	TotalTrans						INT UNSIGNED DEFAULT NULL
	, 	CreatedTime						DATETIME DEFAULT NULL
	, 	ModifiedTime					DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	UNIQUE INDEX `UX_DailyLoginTransactionMonitoring_Group` (`TransDate`,`SubscriberID`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS DCS_DataTrace.DailyRobotMonitoring;

CREATE TABLE DCS_DataTrace.DailyRobotMonitoring(
		ID 									BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate							DATETIME NOT NULL
	, 	SubscriberID						INT UNSIGNED DEFAULT NULL
	, 	TotalInvalidBrowers					INT UNSIGNED DEFAULT NULL
	, 	TotalBotTrans						INT UNSIGNED DEFAULT NULL
	, 	CreatedTime							DATETIME DEFAULT NULL
	, 	ModifiedTime						DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	UNIQUE INDEX `UX_DailyRobotMonitoring_TransDate_SubscriberID` (`TransDate`,`SubscriberID`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS DCS_DataTrace.BetTicket;

CREATE TABLE DCS_DataTrace.BetTicket(
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

DROP TABLE IF EXISTS DCS_DataTrace.MissingLoginTransaction;

CREATE TABLE DCS_DataTrace.MissingLoginTransaction(
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


DROP TABLE IF EXISTS DCS_DataTrace.MissingBetTicket;

CREATE TABLE DCS_DataTrace.MissingBetTicket(
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