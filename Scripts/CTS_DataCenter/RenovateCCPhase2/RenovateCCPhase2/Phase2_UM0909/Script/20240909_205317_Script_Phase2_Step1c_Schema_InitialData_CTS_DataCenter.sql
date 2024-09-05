/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240829@Victoria.Le
	Task :	Change schema
	DB:			
	
	Description: 

	Revisions:	
		- 20240829@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
									Tables:
										1. CTSCustomerClassification_Log
										2. CTSCustomerClassification_BySport_Log
										3. Customer_InitialSmart
										4. Customer_InitialSmart_Log
										5. CustomerLoginInfoDetection
										6. RobotImperva
										7. CustomerCategory
										8. AssociatedGroup
										9. CustomerCategorySettings
										10. Customer_InitialGroupBetting
										11. CTSCustomerClassificationQueue
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;

---------------------------------
/*1. CTSCustomerClassification_Log*/
---------------------------------
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
		,	RobotCounter 				smallint DEFAULT NULL
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
	(	 PARTITION pm202408 VALUES LESS THAN (202409) ENGINE = InnoDB
	,	 PARTITION pm202409 VALUES LESS THAN (202410) ENGINE = InnoDB
	,	 PARTITION pm202410 VALUES LESS THAN (202411) ENGINE = InnoDB
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

---------------------------------
/*2. CTSCustomerClassification_BySport_Log*/
---------------------------------
	SELECT `AUTO_INCREMENT`
	INTO @lv_MAXID_CCLog_BySport
	FROM  INFORMATION_SCHEMA.TABLES
	WHERE TABLE_SCHEMA = 'CTS_DataCenter'
	AND   TABLE_NAME   = 'CTSCustomerClassification_BySport_Log';

	RENAME TABLE CTSCustomerClassification_BySport_Log TO CTSCustomerClassification_BySport_Log_Arc;

	CREATE TABLE CTSCustomerClassification_BySport_Log (
			ID 					bigint unsigned NOT NULL AUTO_INCREMENT
		,	CustID 				bigint unsigned DEFAULT NULL
		,	CTSCustID 			bigint unsigned DEFAULT NULL
		,	SportID 			smallint unsigned DEFAULT NULL
		,	ParentID 			int unsigned DEFAULT NULL
		,	CategoryID 			int DEFAULT NULL
		,	TurnoverRM 			decimal(20,4) DEFAULT NULL
		,	WinlossRM 			decimal(20,4) DEFAULT NULL
		,	BetCount 			bigint DEFAULT NULL
		,	ActiveDays 			int DEFAULT NULL
		,	TargetCC 			int DEFAULT NULL
		,	OldCategoryID 		int unsigned DEFAULT NULL
		,	DWCategoryID 		int unsigned DEFAULT NULL
		,	IsDataChanged 		tinyint(1) DEFAULT '0'
		,	ActionType 			tinyint DEFAULT NULL
		,	LastModifiedDate 	datetime DEFAULT NULL
		,	LastModifiedBy 		int unsigned DEFAULT NULL
		,	InsertDate 			datetime NOT NULL
		,	PerformanceTime 	datetime DEFAULT NULL
		,	Remark 				varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL
		,	SourceTypeID 		smallint DEFAULT NULL
		,	PRIMARY KEY (ID,InsertDate)
		,	KEY IX_CTSCustomerClassification_BySport_Log_CustID (CustID)
	) ROW_FORMAT=COMPRESSED
	/*!50100 PARTITION BY RANGE (yearweek(InsertDate,0))
	(	 PARTITION pw202433 VALUES LESS THAN (202434) ENGINE = InnoDB
	,	 PARTITION pw202434 VALUES LESS THAN (202435) ENGINE = InnoDB
	,	 PARTITION pw202435 VALUES LESS THAN (202436) ENGINE = InnoDB
	,	 PARTITION pw202436 VALUES LESS THAN (202437) ENGINE = InnoDB
	,	 PARTITION pw202437 VALUES LESS THAN (202438) ENGINE = InnoDB
	,	 PARTITION pw202438 VALUES LESS THAN (202439) ENGINE = InnoDB
	,	 PARTITION pw202439 VALUES LESS THAN (202440) ENGINE = InnoDB
	,	 PARTITION pw202440 VALUES LESS THAN (202441) ENGINE = InnoDB
	,	 PARTITION pw202441 VALUES LESS THAN (202442) ENGINE = InnoDB
	,	 PARTITION pw202442 VALUES LESS THAN (202443) ENGINE = InnoDB
	,	 PARTITION pw202443 VALUES LESS THAN (202444) ENGINE = InnoDB
	,	 PARTITION pw202444 VALUES LESS THAN (202445) ENGINE = InnoDB
	,	 PARTITION pw202445 VALUES LESS THAN (202446) ENGINE = InnoDB
	,	 PARTITION pw202446 VALUES LESS THAN (202447) ENGINE = InnoDB
	,	 PARTITION pw202447 VALUES LESS THAN (202448) ENGINE = InnoDB
	,	 PARTITION pw202448 VALUES LESS THAN (202449) ENGINE = InnoDB
	,	 PARTITION pw202449 VALUES LESS THAN (202450) ENGINE = InnoDB
	,	 PARTITION pw202450 VALUES LESS THAN (202451) ENGINE = InnoDB
	,	 PARTITION pw202451 VALUES LESS THAN (202452) ENGINE = InnoDB
	,	 PARTITION pw202452 VALUES LESS THAN (202501) ENGINE = InnoDB
	,	 PARTITION pw202501 VALUES LESS THAN (202502) ENGINE = InnoDB
	,	 PARTITION pw202502 VALUES LESS THAN (202503) ENGINE = InnoDB
	,	 PARTITION pw202503 VALUES LESS THAN (202504) ENGINE = InnoDB
	,	 PARTITION pw202504 VALUES LESS THAN (202505) ENGINE = InnoDB
	,	 PARTITION pw202505 VALUES LESS THAN (202506) ENGINE = InnoDB
	,	 PARTITION pw202506 VALUES LESS THAN (202507) ENGINE = InnoDB
	,	 PARTITION pw202507 VALUES LESS THAN (202508) ENGINE = InnoDB
	,	 PARTITION pw202508 VALUES LESS THAN (202509) ENGINE = InnoDB
	,	 PARTITION pw202509 VALUES LESS THAN (202510) ENGINE = InnoDB
	,	 PARTITION pw202510 VALUES LESS THAN (202511) ENGINE = InnoDB
	,	 PARTITION pw202511 VALUES LESS THAN (202512) ENGINE = InnoDB
	,	 PARTITION pw202512 VALUES LESS THAN (202513) ENGINE = InnoDB
	,	 PARTITION pw202513 VALUES LESS THAN (202514) ENGINE = InnoDB
	,	 PARTITION pw202514 VALUES LESS THAN (202515) ENGINE = InnoDB
	,	 PARTITION pw202515 VALUES LESS THAN (202516) ENGINE = InnoDB
	,	 PARTITION pw202516 VALUES LESS THAN (202517) ENGINE = InnoDB
	,	 PARTITION pw202517 VALUES LESS THAN (202518) ENGINE = InnoDB
	,	 PARTITION pw202518 VALUES LESS THAN (202519) ENGINE = InnoDB
	,	 PARTITION pw202519 VALUES LESS THAN (202520) ENGINE = InnoDB
	,	 PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */
	;
	
	SET @SQL = CONCAT('ALTER TABLE `CTSCustomerClassification_BySport_Log` AUTO_INCREMENT = ', @lv_MAXID_CCLog_BySport);
	PREPARE st FROM @SQL;
	EXECUTE st;

---------------------------------
/*3. Customer_InitialSmart*/
---------------------------------
	ALTER TABLE Customer_InitialSmart
	RENAME COLUMN PredictTime TO SourceCreatedDate;

	ALTER TABLE Customer_InitialSmart
	MODIFY COLUMN Probability DECIMAL(8,2);

---------------------------------
/*4. Customer_InitialSmart_Log*/
---------------------------------
	ALTER TABLE Customer_InitialSmart_Log
	RENAME COLUMN PredictTime TO SourceCreatedDate;

	ALTER TABLE Customer_InitialSmart_Log
	MODIFY COLUMN Probability DECIMAL(8,2);

---------------------------------
/*5. CustomerLoginInfoDetection*/
---------------------------------
	ALTER TABLE CustomerLoginInfoDetection
	RENAME COLUMN DetectionDate TO SourceCreatedDate;

	ALTER TABLE CustomerLoginInfoDetection
	DROP PRIMARY KEY;

	ALTER TABLE CustomerLoginInfoDetection
	ADD COLUMN ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST
,	ADD COLUMN IsDisabled BIT(1) DEFAULT 0
,	ADD COLUMN InsertedTime DATETIME DEFAULT CURRENT_TIMESTAMP()
,	ADD COLUMN ArchivedDate DATETIME;

	ALTER TABLE CustomerLoginInfoDetection 
	ADD KEY IX_CustLoginInfoDetection_CustID_InsertedTime (CustID, InsertedTime);

---------------------------------
/*6. RobotImperva*/
---------------------------------
	ALTER TABLE RobotImperva
	ADD IsDisabled BIT(1) DEFAULT 0;

---------------------------------
/*7. CustomerCategory*/
---------------------------------
	RENAME TABLE CustomerCategory TO CustomerCategory_Arc;
	RENAME TABLE CustomerCategory_new TO CustomerCategory;

---------------------------------
/*8. AssociatedGroup*/
---------------------------------
	ALTER TABLE AssociatedGroup
	MODIFY COLUMN PACategoryID INT;
	
	UPDATE AssociatedGroup AS ag
		INNER JOIN CustomerCategory AS cate ON cate.OldCategoryID = ag.PACategoryID
	SET ag.PACategoryID = cate.CategoryID
	WHERE ag.PACategoryID IS NOT NULL;	

---------------------------------
/*9. CustomerCategorySettings*/
---------------------------------
	TRUNCATE TABLE CustomerCategorySettings;
	
	INSERT INTO CustomerCategorySettings(CategoryID,CategoryGroupID,ParentID,IsParallelParentID,IsMultiCateIDSameParentID,IsKeepOldCateID,RemarkTemplateID)
	VALUES(1010,1010,1000,0,0,0,NULL),
	(10100,10100,10000,1,1,1,NULL),
	(10200,10200,10000,1,1,1,NULL),
	(10201,10200,10000,1,1,1,NULL),
	(10300,10300,10000,1,1,0,NULL),
	(20100,20100,20000,0,1,1,NULL),
	(20101,20100,20000,0,1,1,NULL),
	(20102,20100,20000,0,1,1,NULL),
	(20103,20100,20000,0,1,1,NULL),
	(20200,20200,20000,0,1,1,NULL),
	(20201,20200,20000,0,1,1,NULL),
	(20202,20200,20000,0,1,1,NULL),
	(20203,20200,20000,0,1,1,NULL),
	(20300,20300,20000,0,1,1,NULL),
	(20301,20300,20000,0,1,1,NULL),
	(20302,20300,20000,0,1,1,NULL),
	(20303,20300,20000,0,1,1,NULL),
	(20400,20400,20000,0,1,1,NULL),
	(20401,20400,20000,0,1,1,NULL),
	(20402,20400,20000,0,1,1,NULL),
	(20403,20400,20000,0,1,1,NULL),
	(20500,20500,20000,0,1,1,NULL),
	(20501,20500,20000,0,1,1,NULL),
	(20502,20500,20000,0,1,1,NULL),
	(20503,20500,20000,0,1,1,NULL),
	(20600,20600,20000,0,1,1,NULL),
	(20601,20600,20000,0,1,1,NULL),
	(20602,20600,20000,0,1,1,NULL),
	(20603,20600,20000,0,1,1,NULL),
	(20700,20700,20000,0,1,1,NULL),
	(20701,20700,20000,0,1,1,NULL),
	(20800,20800,20000,0,1,1,NULL),
	(20801,20800,20000,0,1,1,NULL),
	(20802,20800,20000,0,1,1,NULL),
	(20900,20900,20000,0,1,1,NULL),
	(21000,21000,20000,0,1,1,39),
	(21100,21100,20000,0,1,1,NULL),
	(21101,21100,20000,0,1,1,NULL),
	(21103,21100,20000,0,1,1,NULL),
	(21200,21200,20000,0,1,1,NULL),
	(21300,21300,20000,0,1,1,NULL),
	(21302,21300,20000,0,1,1,NULL),
	(21303,21300,20000,0,1,1,NULL),
	(21402,21400,20000,0,1,1,NULL),
	(21500,21500,20000,0,1,1,NULL),
	(21501,21500,20000,0,1,1,NULL),
	(21502,21500,20000,0,1,1,NULL),
	(21503,21500,20000,0,1,1,NULL),
	(21600,21600,20000,0,1,1,NULL),
	(21602,21600,20000,0,1,1,NULL),
	(21700,21700,20000,0,1,1,NULL),
	(21701,21700,20000,0,1,1,NULL),
	(25100,25100,20000,0,1,1,NULL),
	(25101,25100,20000,0,1,1,NULL),
	(25102,25100,20000,0,1,1,NULL),
	(25103,25100,20000,0,1,1,NULL),
	(25200,25200,20000,0,1,1,NULL),
	(25201,25200,20000,0,1,1,NULL),
	(25202,25200,20000,0,1,1,NULL),
	(25203,25200,20000,0,1,1,NULL),
	(25300,25300,20000,0,1,1,NULL),
	(25301,25300,20000,0,1,1,NULL),
	(25302,25300,20000,0,1,1,NULL),
	(25303,25300,20000,0,1,1,NULL),
	(25400,25400,20000,0,1,1,NULL),
	(25401,25400,20000,0,1,1,NULL),
	(25402,25400,20000,0,1,1,NULL),
	(25403,25400,20000,0,1,1,NULL),
	(25500,25500,20000,0,1,1,NULL),
	(25501,25500,20000,0,1,1,NULL),
	(25502,25500,20000,0,1,1,NULL),
	(25503,25500,20000,0,1,1,NULL),
	(25600,25600,20000,0,1,1,NULL),
	(25601,25600,20000,0,1,1,NULL),
	(25602,25600,20000,0,1,1,NULL),
	(25603,25600,20000,0,1,1,NULL),
	(25700,25700,20000,0,1,1,NULL),
	(25701,25700,20000,0,1,1,NULL),
	(25800,25800,20000,0,1,1,NULL),
	(25801,25800,20000,0,1,1,NULL),
	(25802,25800,20000,0,1,1,NULL),
	(25900,25900,20000,0,1,1,NULL),
	(26000,26000,20000,0,1,1,39),
	(26100,26100,20000,0,1,1,NULL),
	(26200,26200,20000,0,1,1,NULL),
	(30100,30100,30000,0,0,0,48),
	(30200,30200,30000,0,0,0,47),
	(30300,30300,30000,0,0,0,46),
	(35100,35100,30000,0,0,0,48),
	(35200,35200,30000,0,0,0,47),
	(35300,35300,30000,0,0,0,46),
	(40100,40100,40000,0,0,0,42),
	(40101,40100,40000,0,0,0,42),
	(40102,40100,40000,0,0,0,42),
	(40103,40100,40000,0,0,0,42),
	(40104,40100,40000,0,0,0,NULL),
	(40106,40100,40000,0,0,0,NULL),
	(40200,40200,40000,0,0,0,43),
	(40201,40200,40000,0,0,0,43),
	(40202,40200,40000,0,0,0,43),
	(40203,40200,40000,0,0,0,43),
	(40300,40300,40000,0,0,0,42),
	(40301,40300,40000,0,0,0,42),
	(40302,40300,40000,0,0,0,42),
	(40303,40300,40000,0,0,0,42),
	(40400,40400,40000,0,0,0,42),
	(40401,40400,40000,0,0,0,42),
	(40402,40400,40000,0,0,0,42),
	(40403,40400,40000,0,0,0,42),
	(40404,40400,40000,0,0,0,44),
	(40405,40400,40000,0,0,0,45),
	(40406,40400,40000,0,0,0,NULL),
	(40500,40500,40000,0,0,1,42),
	(40501,40500,40000,0,0,1,42),
	(40502,40500,40000,0,0,1,42),
	(40503,40500,40000,0,0,1,42),
	(40504,40500,40000,0,0,1,44),
	(40505,40500,40000,0,0,1,45),
	(40506,40500,40000,0,0,1,NULL),
	(40600,40600,40000,0,0,1,42),
	(40601,40600,40000,0,0,1,42),
	(40602,40600,40000,0,0,1,42),
	(40603,40600,40000,0,0,1,42),
	(40604,40600,40000,0,0,1,44),
	(40605,40600,40000,0,0,1,45),
	(40606,40600,40000,0,0,1,NULL),
	(40700,40700,40000,0,0,0,18),
	(40701,40700,40000,0,0,0,19);

---------------------------------
/*10. Customer_InitialGroupBetting*/
---------------------------------
	TRUNCATE TABLE Customer_InitialGroupBetting;
	
	LOAD DATA LOCAL INFILE 'D:/Tasks/RenovationCC/ListCust_2600_2601_UM20240909.csv'
	INTO TABLE Customer_InitialGroupBetting
	FIELDS TERMINATED BY ',' 
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
	IGNORE 1 ROWS;
	
---------------------------------
/* 11. CTSCustomerClassificationQueue*/
---------------------------------
	ALTER TABLE CTSCustomerClassificationQueue
	RENAME COLUMN CategoryGroup TO CategoryGroupID
,	RENAME COLUMN IsDirect TO IsMarkedDirectly;

	UPDATE CTS_DataCenter.CTSCustomerClassificationQueue AS cc
		INNER JOIN CTS_DataCenter.CustomerCategory AS newcate ON newcate.OldCategoryID = cc.CategoryID
	SET 		cc.CategoryGroup_bk		= cc.CategoryGroupID
			,	cc.CategoryID_bk 		= cc.CategoryID
			,	cc.CategoryGroupID		= CASE WHEN cc.CategoryGroupID IS NOT NULL THEN newcate.CategoryGroupID ELSE cc.CategoryGroupID END
			,	cc.CategoryID 			= newcate.CategoryID
	;