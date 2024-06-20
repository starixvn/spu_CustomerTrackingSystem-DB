/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240617@Thomas.Nguyen
Task:	 	add tables
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240617@Thomas.Nguyen: Created [Redmine ID: #205317]
Reviewer:
*/

USE CTS_DataCenter;

CREATE TABLE CustomerCategorySettings
(
	CategoryID INT UNSIGNED NOT NULL,
	CategoryGroupID INT UNSIGNED NOT NULL,
	CategoryTypeID TINYINT UNSIGNED COMMENT '1: VVIP, 2: Wrapper, 3: PA, 4: Potential PA, 5: Normal',
	IsParallelParentID BIT(1),
	IsMultiCateIDSameParentID BIT(1),
	IsKeepOldCateID BIT(1),
	PRIMARY KEY (CategoryID, CategoryGroupID),
	KEY IX_CustCateSettings_CategoryType (CategoryType)
);

CREATE TABLE CustomerClassification_Remark
(
	CategoryID INT UNSIGNED NOT NULL,
	RemarkID SMALLINT UNSIGNED,
	RemarkTemplate VARCHAR(MAX),
	UserComment VARCHAR(1000),
	Description VARCHAR(200),
	InsertedDate DATETIME,
	PRIMARY KEY (RemarkID),
	KEY IX_CustClass_Remark_CategoryID (CategoryID)
);

CREATE TABLE Customer_InitialGroupBetting
(
	CustID BIGINT UNSIGNED NOT NULL,
	GBTicketCount INT,
	SportType INT,
	DetectedDate DATETIME(3),
	ClassifiedDate DATETIME(3),
	InsertedDate DATETIME,
	PRIMARY KEY (CustID)
);

CREATE TABLE TVSVoidRequest
(
	ID BIGINT UNSIGNED NOT NULL,
    TVSRequestID BIGINT UNSIGNED,
    CustID BIGINT UNSIGNED NOT NULL,
    ReasonID INT,
    CreatedBy INT,
    IsParlay BIT(1),
    SportType SMALLINT,
	IsPA BIT(1),
	IsRobot BIT(1),
    IssueTypeID TINYINT,
	ClassifiedDate DATETIME(3),
    InsertedDate DATETIME,
    PRIMARY KEY (ID),
    KEY IX_TVSVoidRequest_ReasonID (ReasonID)
);

CREATE TABLE CTSRobotUser
(
	CustID BIGINT UNSIGNED NOT NULL,
	CategoryID INT UNSIGNED NOT NULL,
	Remark VARCHAR(500),
	ClassifiedDate DATETIME(3),
	InsertedDate DATETIME,
	PRIMARY KEY (CustID, CategoryID)
);

CREATE TABLE TWRobotUser
(
	CustID BIGINT UNSIGNED NOT NULL,
	CategoryID INT UNSIGNED NOT NULL,
	RobotCounter SMALLINT,
	ClassifiedDate DATETIME(3),
	InsertedDate DATETIME,
	PRIMARY KEY (CustID, CategoryID)
);


/*RENAME old table CustomerCategory before executing the script below*/
CREATE TABLE CustomerCategory 
( 
	CategoryID INT UNSIGNED NOT NULL AUTO_INCREMENT, 
	CategoryName VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci, 
	CategorySpec VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci, 
	ParentID INT unsigned, 
	CustomerClass SMALLINT UNSIGNED, 
	CustomerClassName VARCHAR(50) COLLATE utf8_unicode_ci, 
	CategoryGroupID INT UNSIGNED, 
	CategoryPriority SMALLINT UNSIGNED,
	CustomerClassPriority SMALLINT UNSIGNED,
	BussinessCategoryGroupID INT UNSIGNED,
	IsActive BIT(1) DEFAULT b'1', 
	ScanIntervalInSecond BIGINT, 
	ScanTaggingIntervalInSecond BIGINT, 
	RootTaggingID SMALLINT UNSIGNED, 
	RelevantCategoryID INT UNSIGNED, 
	ProblemCaseID SMALLINT UNSIGNED, 
	MMReasonID INT, 
	TVSReasonID INT, 
	IsPAProbation BIT(1), 
	IsDangerProbation TINYINT(1) DEFAULT '0', 
	AFCFraudID INT, 
	DataSource VARCHAR(50) COLLATE utf8_unicode_ci, 
	CreatedDate DATETIME,
	CategoryNameCN VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci, 
	CategoryNameCN3 VARCHAR(50) COLLATE utf8_unicode_ci, 
	CategoryNameTHB VARCHAR(50) COLLATE utf8_unicode_ci, 
	CategoryNameIND VARCHAR(50) COLLATE utf8_unicode_ci, 
	CustomerClassNameCN VARCHAR(50) COLLATE utf8_unicode_ci, 
	SabaSportType VARCHAR(50) COMMENT '1:Soccer or 2:Basketball', 
	TaggingID SMALLINT, 
	TaggingType SMALLINT, 
	ABIDangerLevel_Licensee SMALLINT UNSIGNED, 
	ABIDangerLevel_Credit SMALLINT UNSIGNED, 
	DangerLevelType SMALLINT, 
	OldCategoryID INT UNSIGNED,
	Ext_CategoryGroupID INT UNSIGNED,
	Ext_EvidenceID_Licensee SMALLINT, 
	Ext_EvidenceID_Credit SMALLINT, 
	Ext_SabaIntelligentRiskLevel VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci, 
	Ext_SabaIntelligentRiskLevelTCN VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci, 
	Ext_SabaIntelligentRiskLevelSCN VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci, 
	Ext_SabaIntelligentRiskLevelCN3 VARCHAR(50) COLLATE utf8_unicode_ci, 
	Ext_SabaIntelligentRiskLevelTHB VARCHAR(50) COLLATE utf8_unicode_ci, 
	Ext_SabaIntelligentRiskLevelIND VARCHAR(50) COLLATE utf8_unicode_ci, 
	PRIMARY KEY (CategoryID), 
	KEY IX_CustomerCategory_ParentID (ParentID), 
	KEY IX_CustomerCategory_IsActive (IsActive),
	KEY IX_CustomerCategory_CategoryGroup (CategoryGroup), 
	KEY IX_CustomerCategory_ReasonID (ReasonID) 
);

/*CTSCustomerClassification*/
ALTER TABLE CTSCustomerClassification
RENAME SportGroupID TO ParentID;

ALTER TABLE CTSCustomerClassification
MODIFY COLUMN ParentID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification
MODIFY COLUMN CategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification
ADD IsAffectToDownline BIT(1);

/*CTSCustomerClassification_History*/
ALTER TABLE CTSCustomerClassification_History
RENAME SportGroupID TO ParentID;

ALTER TABLE CTSCustomerClassification_History
MODIFY COLUMN ParentID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_History
MODIFY COLUMN CategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_History
RENAME FromCategoryID TO OldCategoryID;

ALTER TABLE CTSCustomerClassification_History
MODIFY COLUMN OldCategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_History
RENAME ToCategoryID TO DWCategoryID;

ALTER TABLE CTSCustomerClassification_History
MODIFY COLUMN DWCategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_History
RENAME IsDirect TO IsAffectedFromUpline;

/*CTSCustomerClassification_Log*/
ALTER TABLE CTSCustomerClassification_Log
RENAME SportGroupID TO ParentID;

ALTER TABLE CTSCustomerClassification_Log
MODIFY COLUMN ParentID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_Log
RENAME FromCategoryID TO OldCategoryID;

ALTER TABLE CTSCustomerClassification_Log
MODIFY COLUMN OldCategoryID INT UNSIGNED;

ALTER TABLE CTSCustomerClassification_Log
RENAME ToCategoryID TO DWCategoryID;

ALTER TABLE CTSCustomerClassification_Log
MODIFY COLUMN DWCategoryID INT UNSIGNED;