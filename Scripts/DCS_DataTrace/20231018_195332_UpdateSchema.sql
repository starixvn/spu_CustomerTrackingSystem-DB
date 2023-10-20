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
ADD COLUMN TransWeek INT UNSIGNED DEFAULT NULL,
ADD COLUMN TransMonth INT UNSIGNED DEFAULT NULL,
ADD COLUMN FlaggedGroup SMALLINT UNSIGNED DEFAULT NULL,
ADD INDEX `IX_LoginTransactionSummary_FlaggedGroup` (`TransDate`, `SubscriberID`, `FlaggedGroup`, `Flagged`),
DROP INDEX `IX_LoginTransactionSummary_SubscriberID`,
DROP INDEX `IX_LoginTransactionSummary_AccountID`;
    
CREATE TABLE DCS_DataTrace.DailyLoginTransactionSummary(
		ID 								INT UNSIGNED NOT NULL AUTO_INCREMENT
	, 	TransDate						DATETIME NOT NULL
	, 	SubscriberID					INT UNSIGNED DEFAULT NULL
	, 	TotalTrans						INT UNSIGNED DEFAULT NULL
	, 	TotalInvalidBrowers				INT UNSIGNED DEFAULT NULL
	, 	TotalBotTrans					INT UNSIGNED DEFAULT NULL
	, 	CreatedTime						DATETIME DEFAULT NULL
	, 	ModifiedTime					DATETIME DEFAULT NULL
	,	PRIMARY KEY (`ID`)
	,	UNIQUE INDEX `UX_DailyLoginTransactionSummary_Group` (`TransDate`,`SubscriberID`)
) ENGINE=InnoDB;

ALTER TABLE `DCS_DataTrace`.`MissingTransaction` 
CHANGE COLUMN `MissingType` `MissingType` SMALLINT NOT NULL COMMENT '1: MissingLoginTransaction; 2: MissingBetTransaction' ;
