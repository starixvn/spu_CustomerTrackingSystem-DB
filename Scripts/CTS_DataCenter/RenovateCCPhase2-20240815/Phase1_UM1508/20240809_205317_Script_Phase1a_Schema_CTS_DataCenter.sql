/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240809@Victoria.Le
Task:	 	Add/Edit Schema
Server:  	
DBName:		CTS_DataCenter

Revisions: 
		- 20240809@Victoria.Le: 		Initial Writing - Phase 1-a: Schema [Redmine ID: #205317]
										I. Create table:
											1. [Existing] 	CustomerCategory_new 
											2. [New] 		CustomerCategorySettings 
											3. [New] 		CustomerClassification_Remark 
											4. [New] 		Customer_InitialGroupBetting - 2600/2601 
											5. [New] 		TVSVoidRequest - Replace TVSVoidRequest_History & CTSCustomerClassificationOldCategory
											6. [New] 		CTSRobotUser - Replace CTSCustomerClassificationOldCategory
											7. [New] 		TWRobotUser
										II. Alter table:
											1. CTSCustomerClassification
											2. CTSCustomerClassification_History
											3. CTSCustomerClassification_Log
											4. CTSCustomerClassificationQueue
											5. CTSCustomerClassification_BySport
											6. CTSCustomerClassification_BySport_History
											7. CTSCustomerClassification_BySport_Log
											8. ArchiveCustomer_CTSCustomer
*/

USE CTS_DataCenter;
/************************* I. Create table ******************************/
/* 1. [Existing] 	CustomerCategory_new */
CREATE TABLE CustomerCategory_new
( 
		CategoryID 							INT UNSIGNED NOT NULL AUTO_INCREMENT
	,	CategoryName 						VARCHAR(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
	,	CategorySpec 						VARCHAR(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
	,	ParentID 							INT UNSIGNED
	,	CustomerClass 						INT UNSIGNED
	,	CustomerClassName 					VARCHAR(50) COLLATE utf8_unicode_ci
	,	CategoryGroupID 					INT UNSIGNED
	,	CategoryPriority 					SMALLINT UNSIGNED
	,	CustomerClassPriority 				SMALLINT UNSIGNED
	,	BusinessCategoryGroupID 			INT UNSIGNED
	,	IsActive 							BIT(1) DEFAULT b'1'
	,	ScanIntervalInSecond 				BIGINT
	,	ScanTaggingIntervalInSecond 		BIGINT
	,	RelevantCategoryID 					INT UNSIGNED
	,	IsHedgingReasonMM 					BIT(1)
	,	TVSReasonID 						INT
	,	IsPAProbation 						BIT(1)
	,	IsDangerProbation 					BIT(1) DEFAULT 0
	,	AFCFraudID 							INT
	,	DataSource 							VARCHAR(50) COLLATE utf8_unicode_ci
	,	CreatedDate 						DATETIME
	,	CategoryNameCN 						VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_general_ci
	,	CategoryNameCN3 					VARCHAR(50) COLLATE utf8_unicode_ci
	,	CategoryNameTHB 					VARCHAR(50) COLLATE utf8_unicode_ci
	,	CategoryNameIND 					VARCHAR(50) COLLATE utf8_unicode_ci
	,	CustomerClassNameCN 				VARCHAR(50) COLLATE utf8_unicode_ci
	,	SabaSportType 						VARCHAR(50) COMMENT '1:Soccer or 2:Basketball'
	,	TaggingID 							SMALLINT
	,	TaggingType 						SMALLINT
	,	RootTaggingID 						SMALLINT UNSIGNED
	,	OldCategoryID 						INT UNSIGNED
	,	ColorTypeID 						TINYINT UNSIGNED
	,	Ext_ABIDangerLevel_Licensee 		SMALLINT UNSIGNED
	,	Ext_ABIDangerLevel_Credit 			SMALLINT UNSIGNED
	,	Ext_DangerLevelType 				SMALLINT
	,	Ext_CategoryGroupID 				INT UNSIGNED
	,	Ext_EvidenceID_Licensee 			SMALLINT
	,	Ext_EvidenceID_Credit 				SMALLINT
	,	Ext_SabaIntelligentRiskLevel 		VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci
	,	Ext_SabaIntelligentRiskLevelTCN 	VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci
	,	Ext_SabaIntelligentRiskLevelSCN 	VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci
	,	Ext_SabaIntelligentRiskLevelCN3 	VARCHAR(50) COLLATE utf8_unicode_ci
	,	Ext_SabaIntelligentRiskLevelTHB 	VARCHAR(50) COLLATE utf8_unicode_ci
	,	Ext_SabaIntelligentRiskLevelIND 	VARCHAR(50) COLLATE utf8_unicode_ci
	,	PRIMARY KEY (CategoryID)
	,	KEY IX_CustomerCategory_ParentID (ParentID)
	,	KEY IX_CustomerCategory_IsActive (IsActive)
	,	KEY IX_CustomerCategory_CategoryGroupID (CategoryGroupID)
	,	KEY IX_CustomerCategory_TVSReasonID (TVSReasonID)
);


/* 2. [New] 		CustomerCategorySettings */
CREATE TABLE CustomerCategorySettings
(
		CategoryID 						INT UNSIGNED NOT NULL
	,	CategoryGroupID 				INT UNSIGNED NOT NULL
	,	ParentID 						INT UNSIGNED
	,	IsParallelParentID 				BIT(1)
	,	IsMultiCateIDSameParentID 		BIT(1)
	,	IsKeepOldCateID 				BIT(1)
	,	RemarkTemplateID 				INT
	,	PRIMARY KEY (CategoryID, CategoryGroupID)
	,	KEY IX_CustCateSettings_ParentID (ParentID)
);


/* 3. [New] 		CustomerClassification_Remark */
CREATE TABLE CustomerClassification_Remark
(
		RemarkID 			INT UNSIGNED NOT NULL
	,	RemarkTemplate 		TEXT
	,	Description 		VARCHAR(200)
	,	CreatedDate 		DATETIME DEFAULT NOW()
	,	PRIMARY KEY (RemarkID)
);

/* 4. [New] 		Customer_InitialGroupBetting - 2600/2601 */
CREATE TABLE Customer_InitialGroupBetting
(
		CustID 				BIGINT UNSIGNED NOT NULL
	,	GBTicketCount 		INT
	,	SportType 			INT
	,	SourceCreatedDate 	DATETIME(3)
	,	CreatedDate 		DATETIME
	,	PRIMARY KEY (CustID)
);

/* 5. [New] 		TVSVoidRequest - Replace TVSVoidRequest_History & CTSCustomerClassificationOldCategory */
CREATE TABLE TVSVoidRequest
(
		ID BIGINT 				UNSIGNED NOT NULL AUTO_INCREMENT
	,	TVSRequestID 			BIGINT UNSIGNED
    ,	CustID 					BIGINT UNSIGNED NOT NULL
	,	CategoryID 				INT UNSIGNED NOT NULL
    ,	TVSReasonID 			INT
	,	IssueTypeID 			TINYINT
    ,	CreatedBy 				INT
    ,	IsParlay 				BIT(1)
    ,	SportType 				INT
	,	RequestTypeID 			TINYINT COMMENT '1: PA, 2: Robot'
	,	IsDisabled 				BIT(1) DEFAULT 0
    ,	CreatedDate 			DATETIME
	,	InsertedTime 			DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3)
	,	ArchivedDate			DATETIME
    ,	PRIMARY KEY (ID)
    ,	KEY IX_TVSVoidRequest_CustID_CateID_IsDisabled (CustID, CategoryID, IsDisabled)
	,	KEY IX_TVSVoidRequest_TVSReasonID (TVSReasonID)
	,	KEY IX_TVSVoidRequest_IssueTypeID_CreatedDate (IssueTypeID, CreatedDate)
);

/* 6. [New] 		CTSRobotUser - Replace CTSCustomerClassificationOldCategory */
CREATE TABLE CTSRobotUser
(
		ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	CustID 					BIGINT UNSIGNED NOT NULL
	,	CategoryID 				INT UNSIGNED NOT NULL
	,	Remark 					VARCHAR(500)
	,	IsDisabled 				BIT(1) DEFAULT 0
	,	CreatedDate 			DATETIME
	,	InsertedTime 			DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3)
	,	ArchivedDate 			DATETIME
	,	PRIMARY KEY (ID)
	,	KEY IX_CTSRobotUser_CustID_CateID_IsDisabled (CustID, CategoryID, IsDisabled)
);

/* 7. [New] 		TWRobotUser */
CREATE TABLE TWRobotUser
(
		ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	CustID 					BIGINT UNSIGNED NOT NULL
	,	CategoryID 				INT UNSIGNED NOT NULL
	,	RobotCounter 			SMALLINT
	,	IsDisabled 				BIT(1) DEFAULT 0
	,	CreatedDate 			DATETIME
	,	InsertedTime 			DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3)
	,	ArchivedDate 			DATETIME
	,	PRIMARY KEY (ID)
	,	KEY IX_TWRobotUser_CustID_CateID_IsDisabled (CustID, CategoryID, IsDisabled)
);

/************************* II. Alter table ******************************/
/* 1. CTSCustomerClassification */
	ALTER TABLE CTSCustomerClassification
	ADD COLUMN IsAffectToDownline 		BIT(1) AFTER SubscriberID
,	ADD COLUMN RoleID 					TINYINT AFTER SubscriberID
,	ADD COLUMN ParentID_new 			INT UNSIGNED
,	ADD COLUMN CategoryID_new 			INT UNSIGNED 
,	ADD COLUMN CreatedDate_new 			DATETIME
,	ADD COLUMN SportGroupID_bk 			INT UNSIGNED
,	ADD COLUMN CategoryID_bk 			INT UNSIGNED
,	ADD COLUMN CreatedDate_bk 			DATETIME
;

	ALTER TABLE CTSCustomerClassification
	ADD COLUMN LastScannedDate_new 		DATETIME
,	ADD COLUMN LastScannedDate_bk 		DATETIME

	ALTER TABLE CTSCustomerClassification
	MODIFY COLUMN SportGroupID			INT UNSIGNED
,	MODIFY COLUMN CategoryID			INT UNSIGNED
;
	
/* 2. CTSCustomerClassification_History */
	ALTER TABLE CTSCustomerClassification_History
	ADD COLUMN ParentID_new 			INT UNSIGNED
,	ADD COLUMN CategoryID_new 			INT  
,	ADD COLUMN OldCategoryID_new		INT UNSIGNED 
,	ADD COLUMN DWCategoryID_new			INT UNSIGNED 
,	ADD COLUMN SportGroupID_bk 			INT UNSIGNED
,	ADD COLUMN CategoryID_bk 			INT
,	ADD COLUMN FromCategoryID_bk		INT UNSIGNED
,	ADD COLUMN ToCategoryID_bk 			INT UNSIGNED
;

	ALTER TABLE CTSCustomerClassification_History
	MODIFY COLUMN SportGroupID			INT UNSIGNED
,	MODIFY COLUMN CategoryID			INT
,	MODIFY COLUMN TargetCC				INT 
,	MODIFY COLUMN FromCategoryID		INT UNSIGNED
,	MODIFY COLUMN ToCategoryID			INT UNSIGNED
;

/* 3. CTSCustomerClassification_Log */
/*	ALTER TABLE CTSCustomerClassification_Log
	ADD COLUMN ParentID_new 			INT UNSIGNED
,	ADD COLUMN CategoryID_new 			INT  
,	ADD COLUMN OldCategoryID_new		INT UNSIGNED 
,	ADD COLUMN DWCategoryID_new			INT UNSIGNED 
,	ADD COLUMN SportGroupID_bk 			INT UNSIGNED
,	ADD COLUMN CategoryID_bk 			INT
,	ADD COLUMN FromCategoryID_bk		INT UNSIGNED
,	ADD COLUMN ToCategoryID_bk 			INT UNSIGNED
;


/*	ALTER TABLE CTSCustomerClassification_Log
	MODIFY COLUMN SportGroupID			INT UNSIGNED
,	MODIFY COLUMN CategoryID			INT
,	MODIFY COLUMN TargetCC				INT 
,	MODIFY COLUMN FromCategoryID		INT UNSIGNED
,	MODIFY COLUMN ToCategoryID			INT UNSIGNED
;
*/

/* 4. CTSCustomerClassificationQueue */
	ALTER TABLE CTSCustomerClassificationQueue
	ADD COLUMN CategoryGroupID_new		INT
,	ADD COLUMN CategoryID_new 			INT UNSIGNED
,	ADD COLUMN CategoryGroup_bk			INT  
,	ADD COLUMN CategoryID_bk 			INT UNSIGNED
;

	ALTER TABLE CTSCustomerClassificationQueue
	MODIFY COLUMN Remark				VARCHAR(500)
,	MODIFY COLUMN CategoryID			INT
;

	ALTER TABLE CTSCustomerClassificationQueue
	MODIFY COLUMN CategoryID			INT UNSIGNED
,	MODIFY COLUMN CategoryID_new		INT UNSIGNED
,	MODIFY COLUMN CategoryID_bk 		INT UNSIGNED

/* 5. CTSCustomerClassification_BySport */
	ALTER TABLE CTSCustomerClassification_BySport
	ADD COLUMN ParentID			 		INT UNSIGNED AFTER SportID
,	ADD COLUMN CategoryID_new 			INT UNSIGNED 
,	ADD COLUMN CreatedDate_new 			DATETIME
,	ADD COLUMN CategoryID_bk 			INT UNSIGNED
,	ADD COLUMN CreatedDate_bk 			DATETIME
;

	ALTER TABLE CTSCustomerClassification_BySport
	ADD COLUMN LastScannedDate_new 		DATETIME
,	ADD COLUMN LastScannedDate_bk 		DATETIME

	ALTER TABLE CTSCustomerClassification_BySport
	MODIFY COLUMN CategoryID			INT UNSIGNED
;

/* 6. CTSCustomerClassification_BySport_History */
	ALTER TABLE CTSCustomerClassification_BySport_History
	ADD COLUMN ParentID			 		INT UNSIGNED AFTER SportID
,	ADD COLUMN CategoryID_new 			INT  
,	ADD COLUMN CategoryID_bk 			INT
;

	ALTER TABLE CTSCustomerClassification_BySport_History
	MODIFY COLUMN CategoryID			INT UNSIGNED
,	MODIFY COLUMN TargetCC				INT
;

/* 7. CTSCustomerClassification_BySport_Log */
/*	ALTER TABLE CTSCustomerClassification_BySport_Log
	ADD COLUMN ParentID			 		INT UNSIGNED AFTER SportID
,	ADD COLUMN CategoryID_new 			INT  
,	ADD COLUMN CategoryID_bk 			INT
;


	ALTER TABLE CTSCustomerClassification_BySport_Log
	MODIFY COLUMN CategoryID			INT UNSIGNED
,	MODIFY COLUMN TargetCC				INT 
,	MODIFY COLUMN OldCategoryID			INT UNSIGNED
,	MODIFY COLUMN DWCategoryID			INT UNSIGNED
;
*/

/* 8. ArchiveCustomer_CTSCustomer */
	ALTER TABLE ArchiveCustomer_CTSCustomer
	ADD COLUMN ParentID			 		INT UNSIGNED AFTER RoleID
,	ADD COLUMN CategoryID_new 			INT  
,	ADD COLUMN CategoryID_bk 			INT
;

	ALTER TABLE ArchiveCustomer_CTSCustomer
	MODIFY COLUMN CategoryID			INT
;