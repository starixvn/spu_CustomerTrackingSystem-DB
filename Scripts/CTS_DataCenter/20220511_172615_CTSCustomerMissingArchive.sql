/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220511@Casey.Huynh
    Task:	 	20220511@Casey.Huynh: Missing ArchiveCust  [Redmine ID: #xxxx]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

CREATE TABLE CTSCustomerDuplicate (
		ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	SubscriberID INT UNSIGNED DEFAULT NULL
	,	CustID INT UNSIGNED DEFAULT NULL
	,	CustSubID INT UNSIGNED DEFAULT NULL
	,	UserName VARCHAR(50) 
	,	UserName2 VARCHAR(50) 
	,	RegisterName VARCHAR(50) 
	,	SiteID INT DEFAULT NULL
	,	Site VARCHAR(50) 
	,	RoleID TINYINT DEFAULT NULL
	,	Currency VARCHAR(10)
	,	CurrencyID INT DEFAULT NULL
	,	SRecommend INT UNSIGNED DEFAULT NULL
	,	MRecommend INT UNSIGNED DEFAULT NULL
	,	Recommend INT UNSIGNED DEFAULT NULL
	,	LastLogINTime timestamp(4) NULL DEFAULT NULL
	,	CreatedDate DATETIME DEFAULT NULL
	,	CustStatusID TINYINT DEFAULT '0'
	,	Danger1 TINYINT DEFAULT '0'
	,	Danger2 TINYINT DEFAULT '0'
	,	Danger3 TINYINT DEFAULT '0'
	,	InsertedTime DATETIME(4) DEFAULT NULL COMMENT 'When row inserted'
	,	ModifiedTime DATETIME(4) DEFAULT NULL COMMENT 'When row modified'
    ,	DuplicateType 	TINYINT
    ,	OldCTSCustID	BIGINT UNSIGNED
	,	PRIMARY KEY PK_CTSCustomerDuplicate_ID(ID)
	,	INDEX IX_CTSCustomerDuplicate_UserName (UserName)
) ENGINE=InnoDB ;


