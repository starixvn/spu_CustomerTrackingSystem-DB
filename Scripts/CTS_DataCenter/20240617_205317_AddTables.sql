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
	CategoryType TINYINT UNSIGNED, /* 1: VVIP, 2: Wrapper, 3: PA, 4: Potential PA, 5: Normal */
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
	ID BIGINT UNSIGNED NOT NULL
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