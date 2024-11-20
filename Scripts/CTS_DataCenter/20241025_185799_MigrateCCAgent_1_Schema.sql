/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241025@Casey.Huynh
Task:	 	Migrate Data SCHEMA
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241025@Casey.Huynh: Created [Redmine ID: #185799]
Reviewer:
*/

/*****************SCHEMA AND SYSTEMPARAMTER********************************/
USE CTS_DataCenter;
#DROP TABLE Adhoc_F185799Mig_CTSCustomerClassification;
CREATE TABLE Adhoc_F185799Mig_CTSCustomerClassification(
		Migrate_IsMove BIT 
	,	Migrate_Set	TINYINT
	,	Migrate_Source INT #1: CTSCustomer, 2: ArchiveCustomer_CTSCustomer
	,	Migrate_IsLicensee BIT 
    ,	Migrate_Currency VARCHAR(10)
	,	Migrate_IsInternal BIT 
    ,	Migrate_SubscriberID INT UNSIGNED
	,	Migrate_IsJoinArchiveCust BIT
	,	Migrate_IsReactivated BIT
	,	Migrate_ToCategoryID INT
	,	Migrate_ToParentID INT
    ,	Migrate_ToRoleID TINYINT # CTSCustomer
    ,	Migrate_ToSubscriberID INT UNSIGNED # CTSCustomer
	,	CustID BIGINT UNSIGNED NOT NULL
	,	CTSCustID BIGINT UNSIGNED DEFAULT NULL
	,	SubscriberID INT UNSIGNED DEFAULT NULL
	,	RoleID TINYINT DEFAULT NULL
	,	IsAffectToDownline BIT(1) DEFAULT NULL
	,	ParentID INT UNSIGNED NOT NULL
	,	CategoryID INT UNSIGNED NOT NULL
	,	Remark VARCHAR(500)
	,	CreatedDate DATETIME DEFAULT NULL
	,	CreatedBy INT DEFAULT NULL
	,	LastModifiedDate DATETIME DEFAULT NULL
	,	LastModifiedBy INT UNSIGNED DEFAULT NULL
	,	LastScannedDate DATETIME DEFAULT NULL
	,	IsFromTVS BIT(1)  
	,	IsFromTW BIT(1)  
	,	IsFromCTS BIT(1)  
	,	IsMarkedDirectly BIT(1) DEFAULT NULL
	,	TVSRequestID BIGINT UNSIGNED DEFAULT NULL
	,	IsFromAI BIT(1) 
	,	IsFromImperva BIT(1)
	,	IsParlay BIT(1) DEFAULT NULL
	,	SportType SMALLINT DEFAULT NULL
	,	IssueTypeID TINYINT DEFAULT NULL
    
	,	PRIMARY KEY(CustID, ParentID, CategoryID) 
    ,	INDEX IX_Adhoc_F185799Migrate_CTSCustClass(Migrate_IsMove,Migrate_Set)
) ENGINE=InnoDB;
#=============Adhoc_F185799Mig_CTSCustomerClassification_History========================
USE CTS_DataCenter; 
#DROP TABLE IF EXISTS Adhoc_F185799Mig_CTSCustomerClassification_History;
CREATE TABLE Adhoc_F185799Mig_CTSCustomerClassification_History(
		Migrate_IsMove BIT DEFAULT 0
	,	Migrate_Set	TINYINT	
    ,	Migrate_Source INT #1: CTSCustomer, 2: ArchiveCustomer_CTSCustomer
	,	Migrate_ToCategoryID INT
	,	Migrate_ToDWCategoryID INT
	,	Migrate_ToOldCategoryID INT
	,	Migrate_ToParentID INT
	,	Migrate_ToTargetCC INT
    ,	Migrate_ToRoleID INT  
    ,	Migrate_ToID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
	,	ID BIGINT UNSIGNED
	,	CustID BIGINT UNSIGNED DEFAULT NULL
	,	CTSCustID BIGINT UNSIGNED DEFAULT NULL
	,	ParentID INT UNSIGNED DEFAULT NULL
	,	TurnoverRM DECIMAL(20,4) DEFAULT NULL
	,	WinlossRM DECIMAL(20,4) DEFAULT NULL
	,	BetCount BIGINT DEFAULT NULL
	,	ActiveDays INT DEFAULT NULL
	,	TargetCC INT DEFAULT NULL
	,	SourceTypeID SMALLINT UNSIGNED DEFAULT NULL
	,	IsDataChanged bit(1)
	,	ActionType TINYINT DEFAULT NULL
	,	IsAuto bit(1) DEFAULT NULL
	,	LastModifiedDate DATETIME DEFAULT NULL
	,	LastModifiedBy INT UNSIGNED DEFAULT NULL
	,	InsertDate DATETIME DEFAULT NULL
	,	TaggingType SMALLINT
	,	TargetDangerLevel1 SMALLINT DEFAULT NULL
	,	TWGroupBettingRate DECIMAL(10,4) DEFAULT NULL
	,	TWTicketRejectRate DECIMAL(10,4) DEFAULT NULL
	,	TWDesktopUsageRate DECIMAL(10,4) DEFAULT NULL
	,	TWBetCount BIGINT DEFAULT NULL
	,	RobotCounter INT UNSIGNED DEFAULT NULL
	,	Remark VARCHAR(500) DEFAULT NULL
	,	IsMarkedDirectly bit(1) DEFAULT NULL
	,	TVSRequestID BIGINT UNSIGNED DEFAULT NULL
	,	IsFromTVS bit(1)
	,	IsFromTW bit(1)
	,	IsFromCTS bit(1)
	,	IsFromAI bit(1)
	,	IsFromImperva bit(1)
	,	IsParlay bit(1) DEFAULT NULL
	,	SportType SMALLINT DEFAULT NULL
	,	IssueTypeID TINYINT DEFAULT NULL
	,	PerformanceTime DATETIME DEFAULT NULL
	,	CategoryID INT DEFAULT NULL
	,	OldCategoryID INT UNSIGNED DEFAULT NULL
	,	DWCategoryID INT UNSIGNED DEFAULT NULL
	,	UNIQUE KEY Adhoc_F185799Mig_CTSCustClassHistory(ID) 
	,	KEY IX_CTSCustomerClassification_History_CustID(CustID) 
		) ENGINE=InnoDB;
#===============Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer=============
USE CTS_DataCenter; 
#DROP TABLE IF EXISTS Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer;
CREATE TABLE Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer(
		Migrate_ToCategoryID INT
	,	Migrate_ToParentID INT
	,	ID BIGINT UNSIGNED NOT NULL
	,	ArchivedDate DATETIME(3) NOT NULL
	,	CTSCustID BIGINT UNSIGNED NOT NULL
	,	AccountID BIGINT UNSIGNED DEFAULT NULL
	,	SubscriberID INT UNSIGNED DEFAULT NULL
	,	CustID INT UNSIGNED DEFAULT NULL
	,	CustSubID INT UNSIGNED DEFAULT NULL
	,	UserName VARCHAR(50) DEFAULT NULL
	,	UserName2 VARCHAR(50) DEFAULT NULL
	,	RoleID TINYINT DEFAULT NULL
	,	ParentID INT UNSIGNED DEFAULT NULL
	,	InsertTime DATETIME(3) DEFAULT NULL
	,	IsReactivated BIT(1) 
	,	ReactivateDate DATETIME DEFAULT NULL
	,	ProcessedDate DATETIME DEFAULT NULL
	,	CategoryID INT DEFAULT NULL
	,	PRIMARY KEY(ID,ArchivedDate) 
	,	KEY IX_ArchiveCustomer_CTSCustomer_CustID(CustID) 
) ENGINE=InnoDB;
#===============Adhoc_F185799Mig_CTSCustomerClassificationQueue=============
USE CTS_DataCenter; 
#DROP TABLE IF EXISTS Adhoc_F185799Mig_CTSCustomerClassificationQueue;
CREATE TABLE Adhoc_F185799Mig_CTSCustomerClassificationQueue(
		Migrate_ToCategoryGroupID INT
	,	Migrate_ToCategoryID INT
    ,   ID BIGINT UNSIGNED NOT NULL
	,	CTSCustID BIGINT UNSIGNED DEFAULT NULL
	,	CustID BIGINT UNSIGNED DEFAULT NULL
	,	RoleID TINYINT DEFAULT NULL
	,	SubscriberID INT UNSIGNED DEFAULT NULL
	,	CreatedBy BIGINT UNSIGNED DEFAULT NULL
	,	Remark VARCHAR(500)DEFAULT NULL
	,	CategoryGroupID INT DEFAULT NULL
	,	CategoryID INT UNSIGNED DEFAULT NULL
	,	LastDownlineCTSCustID BIGINT UNSIGNED DEFAULT NULL
	,	ActionType TINYINT DEFAULT NULL COMMENT '1: INSERT VVIP,2:Remove VVIP,3:INSERT PA,4: UNMARK PA'
	,	InsertTime DATETIME(3) DEFAULT NULL
	,	IsExceptDirectDownline TINYINT(1) DEFAULT NULL
	,	IsFromTVS TINYINT(1)
	,	IsFromTW TINYINT(1) 
	,	IsFromCTS TINYINT(1) 
	,	IsMarkedDirectly TINYINT(1) DEFAULT NULL
	,	TVSRequestID BIGINT UNSIGNED DEFAULT NULL
	,	PRIMARY KEY(ID) 
	,	KEY IX_CTSCustomerClassificationQueue_CustID(CustID) 
) ENGINE=InnoDB;

#===============Adhoc_F185799Mig_TWRobotUser=============
USE CTS_DataCenter; 
#DROP TABLE IF EXISTS Adhoc_F185799Mig_TWRobotUser;
CREATE TABLE Adhoc_F185799Mig_TWRobotUser (
		Migrate_ToCategoryID INT
	,	ID bigint unsigned NOT NULL
	,	CustID bigint unsigned NOT NULL
	,	CategoryID int unsigned NOT NULL
	,	RobotCounter int unsigned DEFAULT NULL
	,	IsDisabled bit(1) DEFAULT 0
	,	CreatedDate datetime DEFAULT NULL
	,	InsertedTime datetime(3) DEFAULT CURRENT_TIMESTAMP(3)
	,	ArchivedDate datetime DEFAULT NULL
	,	PRIMARY KEY (ID)
	,	KEY IX_AdhocTWRobotUser_CustID_CateID_IsDisabled (CustID,CategoryID,IsDisabled) ) ENGINE=InnoDB;

#===============Adhoc_F185799Mig_CTSRobotUser=============
USE CTS_DataCenter; 
#DROP TABLE IF EXISTS Adhoc_F185799Mig_CTSRobotUser;
CREATE TABLE Adhoc_F185799Mig_CTSRobotUser (
		Migrate_ToCategoryID INT
	,	ID bigint unsigned NOT NULL
	,	CustID bigint unsigned NOT NULL
	,	CategoryID int unsigned NOT NULL
	,	Remark varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL
	,	IsDisabled bit(1) DEFAULT 0
	,	CreatedDate datetime DEFAULT NULL
	,	InsertedTime datetime(3) DEFAULT CURRENT_TIMESTAMP(3)
	,	ArchivedDate datetime DEFAULT NULL
	,	PRIMARY KEY (ID)
	,	KEY IX_AdhocCTSRobotUser_CustID_CateID_IsDisabled (CustID,CategoryID,IsDisabled) ) ENGINE=InnoDB;
