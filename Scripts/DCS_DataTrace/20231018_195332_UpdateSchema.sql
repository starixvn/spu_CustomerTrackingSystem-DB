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

DROP TABLE IF EXISTS DCS_DataTrace.LoginTransactionSummary;

CREATE TABLE DCS_DataTrace.LoginTransactionSummary(
		ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate			DATETIME NOT NULL
	, 	TransWeek			INT UNSIGNED NOT NULL
	, 	TransMonth			INT UNSIGNED NOT NULL
	, 	SubscriberID		INT UNSIGNED DEFAULT NULL
	, 	SubscriberName		VARCHAR(50) DEFAULT NULL
	, 	AccountID			BIGINT UNSIGNED DEFAULT NULL
	, 	CTSCustID			BIGINT UNSIGNED DEFAULT NULL
	, 	LoginName			VARCHAR(100) DEFAULT NULL
	, 	DeviceID			BIGINT UNSIGNED DEFAULT NULL
	, 	Flagged				SMALLINT DEFAULT NULL
	, 	FlaggedGroup		SMALLINT DEFAULT NULL
	, 	TotalTrans			INT UNSIGNED DEFAULT NULL
	, 	FirstLoginTransTime	DATETIME DEFAULT NULL
	, 	LastLoginTransTime	DATETIME DEFAULT NULL
	, 	CreatedTime			DATETIME DEFAULT NULL
	, 	ModifiedTime		DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`, `TransDate`)
	,	INDEX `IX_LoginTransactionSummary_SubscriberID` (`SubscriberID`)
	,	INDEX `IX_LoginTransactionSummary_AccountID` (`AccountID`)
	,	INDEX `IX_LoginTransactionSummary_FlaggedGroup_Flagged` (`FlaggedGroup`, `Flagged`)
	,	UNIQUE INDEX `UX_LoginTransactionSummary_Group` (`TransDate`,`SubscriberID`,`AccountID`,`DeviceID`,`Flagged`)
) ENGINE=InnoDB;




