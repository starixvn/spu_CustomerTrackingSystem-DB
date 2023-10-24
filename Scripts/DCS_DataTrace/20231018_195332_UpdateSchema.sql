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

ALTER TABLE DCS_DataTrace.LoginTransactionSummary
ADD COLUMN FlaggedGroupID SMALLINT UNSIGNED DEFAULT NULL,
ADD COLUMN TransWeek INT UNSIGNED DEFAULT NULL,
ADD COLUMN TransMonth INT UNSIGNED DEFAULT NULL,
ADD INDEX `IX_LoginTransactionSummary_FlaggedGroupID` (`TransDate`, `SubscriberID`, `FlaggedGroupID`, `Flagged`),
ADD INDEX `IX_LoginTransactionSummary_TransWeek_SubscriberID` (`TransWeek`, `SubscriberID`),
ADD INDEX `IX_LoginTransactionSummary_TransMonth_SubscriberID` (`TransMonth`, `SubscriberID`),
DROP INDEX `IX_LoginTransactionSummary_SubscriberID`;

drop table  DCS_DataTrace.DailyLoginTransactionSummary;

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
	, 	MissingTransactionType		SMALLINT NOT NULL COMMENT '0: MissingLoginTransaction; 1: MissingBetTransaction'
	, 	TransDate					DATETIME NOT NULL
	, 	SubscriberID				INT UNSIGNED NOT NULL DEFAULT 0
	, 	CustID						INT UNSIGNED NOT NULL DEFAULT 0
	, 	CreatedTime					DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	INDEX `IX_MemberMissingTransaction_CustID` (`CustID`)
	,	INDEX `IX_MemberMissingTransaction_SubscriberID` (`SubscriberID`)
	,	UNIQUE INDEX `UX_MemberMissingTransaction_Group` (`TransDate`, `SubscriberID`, `MissingTransactionType`, `CustID`)
) ENGINE=InnoDB;

CREATE TABLE `StaticList` (
  `ListID` int NOT NULL,
  `ItemID` smallint NOT NULL,
  `ListCode` varchar(100) DEFAULT NULL,
  `ListName` varchar(200) DEFAULT NULL,
  `ItemCode` varchar(100) DEFAULT NULL,
  `ItemName` varchar(200) DEFAULT NULL,
  `Status` tinyint(1) DEFAULT NULL,
  `Description` varchar(200) DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `GroupID` smallint DEFAULT NULL,
  PRIMARY KEY (`ListID`,`ItemID`),
  UNIQUE KEY `UX_StaticList_ListCode_ItemCode` (`ListCode`,`ItemCode`)
) ENGINE=InnoDB;

INSERT INTO DCS_DataTrace.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
VALUES(3, 'MissingTrans', 'LastScannedLoginTransDate', '2023-07-01', CURRENT_TIMESTAMP);

INSERT INTO DCS_DataTrace.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
VALUES(4, 'MissingTrans', 'LastScannedBetTransDate', '2023-07-01', CURRENT_TIMESTAMP);

INSERT INTO DCS_DataTrace.StaticList (ListID, ItemID, ListCode, ListName, ItemCode, ItemName, Status, Description, CreatedDate) 
VALUES ('1', '1', 'MissingTransactionType', 'MissingTransactionType', 1, 'Missing Login Transaction', '1', 'Missing Login Transaction', CURRENT_TIMESTAMP()),
('1', '2', 'MissingTransactionType', 'MissingTransactionType', 2, 'Missing Bet Transaction', '1', 'Missing Bet Transaction', CURRENT_TIMESTAMP());

SET sql_safe_updates = 0;
UPDATE DCS_DataTrace.LoginTransactionSummary AS trans
	LEFT JOIN DCS_DataCenter.StaticList AS sl ON sl.ListID = 1 AND sl.ItemID = trans.Flagged
SET trans.TransWeek = YEARWEEK(trans.TransDate, 0),
	trans.TransMonth = DATE_FORMAT(trans.TransDate, '%Y%m'),
	trans.FlaggedGroupID = sl.GroupID;
    
DROP PROCEDURE IF EXISTS `DCS_DT_Report_DailyLoginTransactionSummary_Insert`;
DROP PROCEDURE IF EXISTS `DCS_DT_Report_DeviceTransaction_Get`;