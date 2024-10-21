/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241017@Victoria.Le
	Task:		RenovateCC Phase 2 - Change datatype & Clean up redundant code - Drop columns with prefix _arc/new/bk
	Server:  	Master
	DBName:		CTS_DataCenter

	Param's Expanation:
	
	Example:
		
	Revisions: 
		- 20241017@Victoria.Le:			Initial Writing [Redmine ID: #212240]
*/

USE CTS_DataCenter;

/************************* 1. Tables CTSCustomerClassification ******************************/
	ALTER TABLE CTSCustomerClassification 
	DROP SportGroupID_arc
, 	DROP CategoryID_arc
, 	DROP CreatedDate_new
, 	DROP LastScannedDate_new
, 	DROP SportGroupID_bk
, 	DROP CreatedDate_bk
, 	DROP CategoryID_bk
, 	DROP LastScannedDate_bk;

	ALTER TABLE CTSCustomerClassification 
	MODIFY ParentID INT UNSIGNED AFTER IsAffectToDownline;
	
	ALTER TABLE CTSCustomerClassification 
	MODIFY CategoryID INT UNSIGNED AFTER ParentID;

/************************* 2. Tables CTSCustomerClassification_BySport ******************************/
	ALTER TABLE CTSCustomerClassification_BySport 
	DROP CategoryID_arc
, 	DROP CreatedDate_new
, 	DROP LastScannedDate_new
, 	DROP CategoryID_bk
, 	DROP CreatedDate_bk
, 	DROP LastScannedDate_bk;

	ALTER TABLE CTSCustomerClassification_BySport 
	MODIFY CategoryID INT UNSIGNED AFTER ParentID;

/************************* 3. Tables CTSCustomerClassification_History ******************************/
	ALTER TABLE CTSCustomerClassification_History 
	DROP LastXDaysMargin
, 	DROP ProbationPeriodWinloss
, 	DROP IsAppliedCC
, 	DROP IsAppliedDangerLevel1
, 	DROP First5TWGBTicketCount
, 	DROP SportGroupID_arc
, 	DROP CategoryID_arc
, 	DROP FromCategoryID_arc
, 	DROP ToCategoryID_arc
, 	DROP SportGroupID_bk
, 	DROP CategoryID_bk
, 	DROP FromCategoryID_bk
, 	DROP ToCategoryID_bk;

	ALTER TABLE CTSCustomerClassification_History
	MODIFY COLUMN RobotCounter INT UNSIGNED;

	ALTER TABLE CTSCustomerClassification_History 
	MODIFY ParentID INT UNSIGNED AFTER CTSCustID;
	
	ALTER TABLE CTSCustomerClassification_History 
	MODIFY CategoryID INT UNSIGNED AFTER ParentID;

/************************* 4. Tables CTSCustomerClassification_BySport_History ******************************/
	ALTER TABLE CTSCustomerClassification_BySport_History 
	DROP CategoryID_arc
, 	DROP CategoryID_bk;

	ALTER TABLE CTSCustomerClassification_BySport_History 
	MODIFY CategoryID INT UNSIGNED AFTER ParentID;

/************************* 5. Tables CTSCustomerClassificationQueue ******************************/
	ALTER TABLE CTSCustomerClassificationQueue 
	DROP CategoryGroupID_new
, 	DROP CategoryID_new
, 	DROP CategoryGroup_bk
, 	DROP CategoryID_bk;
	
/************************* 6. Tables ArchiveCustomer_CTSCustomer ******************************/
	ALTER TABLE ArchiveCustomer_CTSCustomer 
	DROP CategoryID_arc
, 	DROP CategoryID_bk;
	
/************************* 7. Tables CTSCustomerClassification_Log ******************************/
	SELECT `AUTO_INCREMENT`
	INTO @lv_MAXID_CCLog_General
	FROM  INFORMATION_SCHEMA.TABLES
	WHERE TABLE_SCHEMA = 'CTS_DataCenter'
	AND   TABLE_NAME   = 'CTSCustomerClassification_Log';

	RENAME TABLE CTSCustomerClassification_Log TO CTSCustomerClassification_Log_Arc;

	CREATE TABLE CTSCustomerClassification_Log (
			ID 							bigint unsigned NOT NULL AUTO_INCREMENT
		,	CustID 						bigint unsigned DEFAULT NULL
		,	CTSCustID 					bigint unsigned DEFAULT NULL
		,	ParentID 					int unsigned DEFAULT NULL
		,	CategoryID 					int DEFAULT NULL
		,	TurnoverRM 					decimal(20,4) DEFAULT NULL
		,	WinlossRM 					decimal(20,4) DEFAULT NULL
		,	BetCount 					bigint DEFAULT NULL
		,	ActiveDays 					int DEFAULT NULL
		,	RobotCounter 				int DEFAULT NULL
		,	TargetCC 					int DEFAULT NULL
		,	SourceTypeID 				smallint unsigned DEFAULT NULL
		,	OldCategoryID 				int unsigned DEFAULT NULL
		,	DWCategoryID 				int unsigned DEFAULT NULL
		,	IsDataChanged 				bit(1) DEFAULT b'0'
		,	ActionType 					tinyint DEFAULT NULL
		,	IsAuto 						bit(1) DEFAULT NULL
		,	LastModifiedDate 			datetime DEFAULT NULL
		,	LastModifiedBy 				int unsigned DEFAULT NULL
		,	InsertDate 					datetime NOT NULL
		,	TaggingType 				smallint DEFAULT '1'
		,	TargetDangerLevel1 			smallint DEFAULT NULL
		,	TWGroupBettingRate 			decimal(10,4) DEFAULT NULL
		,	TWTicketRejectRate 			decimal(10,4) DEFAULT NULL
		,	TWBetCount 					bigint DEFAULT NULL
		,	TWDesktopUsageRate 			decimal(10,4) DEFAULT NULL
		,	Remark 						varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL
		,	IsMarkedDirectly			bit(1) DEFAULT NULL
		,	TVSRequestID 				bigint unsigned DEFAULT NULL
		,	IsFromTVS 					bit(1) DEFAULT b'0'
		,	IsFromTW 					bit(1) DEFAULT b'0'
		,	IsFromCTS 					bit(1) DEFAULT b'0'
		,	IsFromAI 					bit(1) DEFAULT b'0'
		,	IsFromImperva 				bit(1) DEFAULT b'0'
		,	IsParlay 					bit(1) DEFAULT NULL
		,	SportType 					smallint DEFAULT NULL
		,	IssueTypeID 				tinyint DEFAULT NULL
		,	PerformanceTime 			datetime DEFAULT NULL
		,	PRIMARY KEY (ID,InsertDate)
		,	KEY IX_CTSCustomerClassification_Log_CustID (CustID)
	) ROW_FORMAT=COMPRESSED
	/*!50100 PARTITION BY RANGE (extract(year_month from InsertDate))
	(	 PARTITION pm202410 VALUES LESS THAN (202411) ENGINE = InnoDB
	,	 PARTITION pm202411 VALUES LESS THAN (202412) ENGINE = InnoDB
	,	 PARTITION pm202412 VALUES LESS THAN (202501) ENGINE = InnoDB
	,	 PARTITION pm202501 VALUES LESS THAN (202502) ENGINE = InnoDB
	,	 PARTITION pm202502 VALUES LESS THAN (202503) ENGINE = InnoDB
	,	 PARTITION pm202503 VALUES LESS THAN (202504) ENGINE = InnoDB
	,	 PARTITION pm202504 VALUES LESS THAN (202505) ENGINE = InnoDB
	,	 PARTITION pm202505 VALUES LESS THAN (202506) ENGINE = InnoDB
	,	 PARTITION pm202506 VALUES LESS THAN (202507) ENGINE = InnoDB
	,	 PARTITION pm202507 VALUES LESS THAN (202508) ENGINE = InnoDB
	,	 PARTITION pm202508 VALUES LESS THAN (202509) ENGINE = InnoDB
	,	 PARTITION pm202509 VALUES LESS THAN (202510) ENGINE = InnoDB
	,	 PARTITION pm202510 VALUES LESS THAN (202511) ENGINE = InnoDB
	,	 PARTITION pm202511 VALUES LESS THAN (202512) ENGINE = InnoDB
	,	 PARTITION pm999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */
	;

	SET @SQL = CONCAT('ALTER TABLE `CTSCustomerClassification_Log` AUTO_INCREMENT = ', @lv_MAXID_CCLog_General);
	PREPARE st FROM @SQL;
	EXECUTE st;
	
/************************* 8. Tables TWRobotUser ******************************/
	ALTER TABLE TWRobotUser
	MODIFY COLUMN RobotCounter INT UNSIGNED;	
	
/************************* 9. Tables SystemParameter ******************************/
	DELETE FROM SystemParameter WHERE ParameterID >= 774 AND ParameterID <= 999;
	
/************************* 10. Tables SystemEventStatus ******************************/
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_Renovate_Phase1_Clean_History';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_Redundant';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_InitCCHistory';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_RenovatePhase2CleanBySportHistory';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_MatchMonitor_Wrapper';
