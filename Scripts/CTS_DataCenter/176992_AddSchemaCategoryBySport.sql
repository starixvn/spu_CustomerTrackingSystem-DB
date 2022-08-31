/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator: 	20220830@Harvey.Nguyen
	Task:	 	Update sysparam [Redmine ID: 176992] 	
	DBName:		CTS_DataCenter
*/
CREATE TABLE CTSCustomerClassification_BySport (
		CustID BIGINT 		UNSIGNED NOT NULL
	,	CTSCustID BIGINT UNSIGNED DEFAULT NULL
	,	SportGroupID SMALLINT UNSIGNED NOT NULL
	,	CategoryID SMALLINT UNSIGNED NOT NULL
	,	Remark VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL
	,	CreatedDate DATETIME DEFAULT NULL
	,	CreatedBy INT DEFAULT NULL
	,	LastModifiedDate DATETIME DEFAULT NULL
	,	LastModifiedBy INT UNSIGNED DEFAULT NULL
	,	LastScannedDate DATE DEFAULT NULL
	,	PRIMARY KEY (CustID,SportGroupID,CategoryID)
	,	KEY IX_CTSCustomerClassification_BySport_CustSportGroup(CTSCustID, SportGroupID, LastModifiedDate)
	,	KEY IX_CTSCustomerClassification_BySport_SportGroupID_CreatedDate(SportGroupID, CreatedDate)
	,	KEY IX_CTSCustomerClassification_BySport_CategoryID_CustID(CategoryID, CustID, LastScannedDate)
	) ENGINE = InnoDB DEFAULT CHARSET = utf8mb3 COLLATE = utf8_unicode_ci;
    
CREATE TABLE CTSCustomerClassification_BySport_History (
		ID 					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	CustID 				BIGINT UNSIGNED DEFAULT NULL
	,	CTSCustID 			BIGINT UNSIGNED DEFAULT NULL
	,	SportGroupID 		SMALLINT UNSIGNED DEFAULT NULL
	,	CategoryID 			SMALLINT UNSIGNED DEFAULT NULL
	,	TurnoverRM 			DECIMAL(20, 4) DEFAULT NULL
	,	WinlossRM 			DECIMAL(20, 4) DEFAULT NULL
	,	BetCount 			BIGINT DEFAULT NULL
	,	ActiveDays 			INT DEFAULT NULL
	,	TargetCC 			SMALLINT DEFAULT NULL
	,	FromCategoryID 		SMALLINT UNSIGNED DEFAULT NULL
	,	ToCategoryID 		SMALLINT UNSIGNED DEFAULT NULL
	,	IsDataChanged 		BIT (1) DEFAULT b'0'
	,	ActionType 			TINYINT DEFAULT NULL
	,	IsAuto 				BIT (1) DEFAULT NULL
	,	LastModifiedDate	DATETIME DEFAULT NULL
	,	LastModifiedBy 		INT UNSIGNED DEFAULT NULL
	,	InsertDate 			DATETIME DEFAULT NULL
	,	PRIMARY KEY (ID)
	,	KEY IX_CTSCustomerClassification_BySport_History_InsertDate(InsertDate)
	,	KEY IX_CTSCustomerClassification_BySport_History_CTSCustID(CTSCustID)
	,	KEY IX_CTSCustomerClassification_BySport_History_CustID_Infor(CustID, SportGroupID, LastModifiedDate, IsDataChanged)
	) 	ENGINE = InnoDB DEFAULT CHARSET = utf8mb3 COLLATE = utf8_unicode_ci;
    
    
CREATE TABLE CTSCustomerClassification_BySport_Log (
	ID					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,CustID				BIGINT UNSIGNED DEFAULT NULL
	,CTSCustID			BIGINT UNSIGNED DEFAULT NULL
	,SportGroupID		SMALLINT UNSIGNED DEFAULT NULL
	,CategoryID			SMALLINT DEFAULT NULL
	,TurnoverRM			DECIMAL(20, 4) DEFAULT NULL
	,WinlossRM			DECIMAL(20, 4) DEFAULT NULL
	,BetCount			BIGINT DEFAULT NULL
	,ActiveDays			INT DEFAULT NULL
	,TargetCC 			SMALLINT DEFAULT NULL
	,FromCategoryID 	SMALLINT UNSIGNED DEFAULT NULL
	,ToCategoryID 		SMALLINT UNSIGNED DEFAULT NULL
	,IsDataChanged		BIT (1) DEFAULT b'0'
	,ActionType			TINYINT DEFAULT NULL
	,IsAuto				BIT (1) DEFAULT NULL
	,LastModifiedDate	DATETIME DEFAULT NULL
	,LastModifiedBy		INT UNSIGNED DEFAULT NULL
	,InsertDate			DATETIME NOT NULL
	,PRIMARY KEY (ID, InsertDate)
	,KEY IX_CTSCustomerClassification_BySport_Log_CustID(CustID)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb3 COLLATE = utf8_unicode_ci;

