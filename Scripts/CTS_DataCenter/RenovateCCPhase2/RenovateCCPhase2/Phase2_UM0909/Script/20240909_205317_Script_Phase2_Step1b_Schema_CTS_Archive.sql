/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
Creator:	20240809@Victoria.Le
Task:	 	Initial data
Server:  	Master
DBName:		CTS_Archive

Revisions: 
		- 20240809@Victoria.Le: 		Initial Writing - Phase 2-a: Schema [Redmine ID: #205317]
										I. 	Get Max ID of table:
											1. [Existing] 	CTSCustomerClassification_History_Archive 
											2. [Existing] 	CTSCustomerClassification_BySport_History_Archive 
										II. Create table:
											1. [New] 		CTSCustomerClassification_History_Renovate_Archive - Replace table CTSCustomerClassification_History_Archive 
											2. [New] 		CTSCustomerClassification_BySport_History_Renovate_Archive  - Replace table CTSCustomerClassification_BySport_History_Archive 
*/

USE CTS_Archive;

/* STEP 3.1.2 */

/******************** I. Get Max ID of table ********************/
SELECT `AUTO_INCREMENT`
INTO @lv_MAXID_History_General_Archive
FROM  INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'CTS_Archive'
AND   TABLE_NAME   = 'CTSCustomerClassification_History_Archive';


SELECT `AUTO_INCREMENT`
INTO @lv_MAXID_History_BySport_Archive
FROM  INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'CTS_Archive'
AND   TABLE_NAME   = 'CTSCustomerClassification_BySport_History_Archive';

/******************** II. Create table ********************/
/* 1. [New] 		CTSCustomerClassification_History_Renovate_Archive - Replace table CTSCustomerClassification_History_Archive  */
CREATE TABLE CTSCustomerClassification_History_Renovate_Archive (
		ID 					bigint unsigned NOT NULL AUTO_INCREMENT
	,	HistoryID 			bigint unsigned NOT NULL
	,	CustID 				bigint unsigned DEFAULT NULL
	,	CTSCustID 			bigint unsigned DEFAULT NULL
	,	ParentID	 		int unsigned DEFAULT NULL
	,	CategoryID 			int DEFAULT NULL
	,	TurnoverRM 			decimal(20,4) DEFAULT NULL
	,	WinlossRM 			decimal(20,4) DEFAULT NULL
	,	BetCount 			bigint DEFAULT NULL
	,	ActiveDays 			int DEFAULT NULL
	,	RobotCounter 		smallint DEFAULT NULL
	,	TargetCC 			int DEFAULT NULL
	,	SourceTypeID 		smallint unsigned DEFAULT NULL
	,	OldCategoryID 		int unsigned DEFAULT NULL
	,	DWCategoryID		int unsigned DEFAULT NULL
	,	IsDataChanged 		bit(1) DEFAULT b'0'
	,	ActionType 			tinyint DEFAULT NULL
	,	IsAuto 				bit(1) DEFAULT NULL
	,	LastModifiedDate 	datetime DEFAULT NULL
	,	LastModifiedBy 		int unsigned DEFAULT NULL
	,	InsertDate 			datetime NOT NULL
	,	TaggingType 		smallint DEFAULT '1'
	,	TargetDangerLevel1 	smallint DEFAULT NULL
	,	TWGroupBettingRate 	decimal(10,4) DEFAULT NULL
	,	TWTicketRejectRate 	decimal(10,4) DEFAULT NULL
	,	TWBetCount 			bigint DEFAULT NULL
	,	TWDesktopUsageRate 	decimal(10,4) DEFAULT NULL
	,	Remark 				varchar(500) DEFAULT NULL
	,	IsMarkedDirectly	bit(1) DEFAULT NULL
	,	TVSRequestID 		bigint unsigned DEFAULT NULL
	,	IsFromTVS 			bit(1) DEFAULT b'0'
	,	IsFromTW 			bit(1) DEFAULT b'0'
	,	IsFromCTS 			bit(1) DEFAULT b'0'
	,	IsFromAI 			bit(1) DEFAULT b'0'
	,	IsFromImperva 		bit(1) DEFAULT b'0'
	,	IsParlay 			bit(1) DEFAULT NULL
	,	SportType 			smallint DEFAULT NULL
	,	IssueTypeID 		tinyint DEFAULT NULL
	,	PerformanceTime 	datetime DEFAULT NULL
	,	PRIMARY KEY (ID)
	,	KEY IX_CTSCustomerClassification_History_Renovate_CTSCustID (CTSCustID)
	,	KEY IX_CTSCustomerClassification_History_Renovate_CustID_Infor (CustID)
) ;

SET @SQL = CONCAT('ALTER TABLE `CTSCustomerClassification_History_Renovate_Archive` AUTO_INCREMENT = ', @lv_MAXID_History_General_Archive);
PREPARE st FROM @SQL;
EXECUTE st;

/* 2. [New] 		CTSCustomerClassification_BySport_History_Renovate_Archive  - Replace table CTSCustomerClassification_BySport_History_Archive */
CREATE TABLE CTSCustomerClassification_BySport_History_Renovate_Archive (
		ID 					bigint unsigned NOT NULL AUTO_INCREMENT
	,	HistoryID 			bigint unsigned NOT NULL
	,	CustID 				bigint unsigned DEFAULT NULL
	,	CTSCustID 			bigint unsigned DEFAULT NULL
	,	SportID 			smallint unsigned DEFAULT NULL
	,	ParentID 			int unsigned DEFAULT NULL
	,	CategoryID 			int unsigned DEFAULT NULL
	,	TurnoverRM 			decimal(20,4) DEFAULT NULL
	,	WinlossRM 			decimal(20,4) DEFAULT NULL
	,	BetCount 			bigint DEFAULT NULL
	,	ActiveDays 			int DEFAULT NULL
	,	TargetCC 			int DEFAULT NULL
	,	ActionType 			tinyint DEFAULT NULL
	,	LastModifiedDate 	datetime DEFAULT NULL
	,	LastModifiedBy 		int unsigned DEFAULT NULL
	,	InsertDate 			datetime DEFAULT NULL
	,	PerformanceTime 	datetime DEFAULT NULL
	,	Remark 				varchar(500) DEFAULT NULL
	,	SourceTypeID 		smallint DEFAULT NULL
	,	PRIMARY KEY (ID)
	,	KEY IX_CTSCustomerClassification_BySport_History_CustID_Infor (CustID)
) ;

SET @SQL = CONCAT('ALTER TABLE `CTSCustomerClassification_BySport_History_Renovate_Archive` AUTO_INCREMENT = ', @lv_MAXID_History_BySport_Archive);
PREPARE st FROM @SQL;
EXECUTE st;