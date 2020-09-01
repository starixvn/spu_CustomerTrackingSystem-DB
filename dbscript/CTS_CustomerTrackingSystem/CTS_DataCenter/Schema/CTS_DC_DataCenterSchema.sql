/*
Creator: 20191106@CaseyHuynh + Harvey.Nguyen
Task:	 	CTS_Schema
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
		- [20191217@CaseyHuynh][125530]: Add Column LastLoginDate column to table CTSCustomer.  	(#125530)
        - [20200117@HarveyNguyen][127352]: Add table CustRetractEvidence							(#127352)
        - [202002130@Casey.Huynh][130109]: Add INDEX (SubscriberID, CTSCustID) on TABLE CustDCSAcount.
        - [20200416@Long.Luu][131506]: Manage Association_Create tables(AssociationByManual, AssociationRemove)
        - [20200416@Long.Luu][132623]: Customer Category_Create tables(SportGroup, CustomerCategory, CTSCustomerClassification)
        - [20200612@Casey.Huynh][135324]: 
			+ Alter Table CTSCustomerClassification, add column LastScannedDate
            + Alter table CTS_DataCenter.CustomerCategory: Add ScanIntervalInSecond
            + Re-Design Table CTS_DataCenter.CustomerCategory_History
            + Add table CTS_DataCenter.CTSCustomerClassification_ScanStatus
            
		- [20200706@Long.Luu][134652]: Associated Account Monitor	[Redmine ID: #134652]
        - [20200806@Casey.Huynh]: Add Index for table AssociationByDevice
        - [20200807@Casey.Huynh][138925]: Chagne CustEvidence Structure for Cross Subscriber
        - [20200820@Casey.Huynh][139061]: Update Index CTSCustomer Classification
Reviewer:
*/

CREATE DATABASE IF NOT EXISTS CTS_DataCenter;

	CREATE TABLE IF NOT EXISTS CTS_DataCenter.CTSCustomer (
		CTSCustID			BIGINT	UNSIGNED	AUTO_INCREMENT
		, SubscriberID		INT		UNSIGNED
		, CustID			INT		UNSIGNED
		, CustSubID			INT		UNSIGNED
		, UserName			VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		, UserName2			VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        , RegisterName 		VARCHAR(50)
        , SiteID			INT
		, Site				VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		, RoleID			TINYINT
		, Currency			VARCHAR(10)
		, CurrencyID		INT		
		, SRecommend		INT		UNSIGNED
		, MRecommend		INT		UNSIGNED	
		, Recommend			INT		UNSIGNED
        , LastLoginTime		TIMESTAMP(4)
        , CreatedDate		DATETIME
        , CustStatusID		TINYINT
        , Danger1			TINYINT
        , Danger2			TINYINT
        , Danger3			TINYINT
		, PRIMARY KEY	PK_CTSCustomer_CTSCustID(CTSCustID)    
		, UNIQUE KEY	UK_CTSCustomer_04062020_SubID_UserName_UserName2(SubscriberID, UserName, UserName2)
		, INDEX			IX_CTSCustomer_04062020_UserName(UserName)
		, INDEX			IX_CTSCustomer_04062020_UserName2(UserName2)
        , INDEX			IX_CTSCustomer_04062020_RegisterName(RegisterName)
		, INDEX			IX_CTSCustomer_04062020_CustID_CustSubID(CustID, CustSubID)
        
	) ENGINE=INNODB AUTO_INCREMENT=1;

	CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociationByDevice(
		CTSAssDevID		BIGINT	UNSIGNED AUTO_INCREMENT
		, CTSCustID		BIGINT	UNSIGNED
		, DCSDeviceID	BIGINT
		, SubscriberID	INT
		, CreatedTime	TIMESTAMP(4)
		, InsertTime	TIMESTAMP(4)
		, PRIMARY KEY	PK_AssociationByDevice_CTSAssDevID(CTSAssDevID)
        , UNIQUE KEY	IX_AssociationByDevice_CTSCustID_DCSDeviceID(CTSCustID, DCSDeviceID)
        , INDEX			IX_AssociationByDevice_SubscriberID_DeviceID(SubscriberID, DCSDeviceID)
        , INDEX			IX_AssociationByDevice_DCSDeviceID_CTSCustID( DCSDeviceID, CTSCustID)
	) ENGINE=INNODB AUTO_INCREMENT=1;

	CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociationByIP(
		CTSAssIPID			BIGINT	UNSIGNED	AUTO_INCREMENT
		, CTSCustID			BIGINT	UNSIGNED
		, IP				VARCHAR(50)
		, IPID				DECIMAL(50,0)
		, SubscriberID		INT
		, CreatedTime		TIMESTAMP(4)
		, LastLoginTime		TIMESTAMP(4)
		, InsertTime		TIMESTAMP(4)
		, PRIMARY KEY	PK_AssociationByIP_CTSAssID(CTSAssIPID)
		, UNIQUE KEY	UK_AssociationByIP_CTSCustID_IPID(CTSCustID,IPID)
		, INDEX			IX_AssociationByIP_LastLoginTime_CustID_IPID(LastLoginTime, CTSCustID, IPID)
	)ENGINE=INNODB  AUTO_INCREMENT=1;

	CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustDCSAccount(
		CTSCustID			BIGINT	UNSIGNED
		, AccountID			BIGINT	UNSIGNED
		, SubscriberID		INT
		, InsertTime		TIMESTAMP(4)
		, PRIMARY KEY		PK_CustDCSAccount_AccountID(AccountID)  
        
		, INDEX	IX_CustDCSAccount_SubscriberID_CTSCustID(SubscriberID,CTSCustID)
	) ENGINE=INNODB  AUTO_INCREMENT=1;
	
   CREATE TABLE IF NOT EXISTS CTS_DataCenter.MappingSubscriberSite(
		
		SubscriberID		INT
		, SubscriberName	VARCHAR(50)
        , RoleMapping		TINYINT
		, SubscriberType	TINYINT
        , SubscriberStatus	TINYINT
		, SubscriberGroupID SMALLINT UNSIGNED
        , SiteID			INT
        , SiteName			VARCHAR(50)
        , Comments			VARCHAR(200)
		, PRIMARY KEY	PK_MappingSubscriberSite_SubscriberID(SiteID, SubscriberID)    
	) ENGINE=INNODB;

	# ======SubscriberGroup=============================================
    CREATE TABLE IF NOT EXISTS CTS_DataCenter.SubscriberGroup (
		SubscriberGroupID			SMALLINT UNSIGNED AUTO_INCREMENT
	, 	SubscriberGroupName		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    , 	SubscriberGroupDesc		VARCHAR(200) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    ,	ParentID			SMALLINT UNSIGNED
	, 	DisplayOrder		TINYINT UNSIGNED
    ,	IsActive			BIT DEFAULT 1
	, 	CreatedDate			DATETIME
    ,	CreatedBy			INT UNSIGNED
    , 	LastModifiedDate	DATETIME
    ,	LastModifiedBy		INT UNSIGNED
	, 	PRIMARY KEY			PK_SubscriberGroup_SubscriberGroupDisplayOrder(SubscriberGroupID,DisplayOrder)
	, 	INDEX				IX_SubscriberGroup_ParentID(ParentID)
    , 	INDEX				IX_SubscriberGroup_IsActive(IsActive)
) ENGINE=INNODB AUTO_INCREMENT=1;

	# ======EvidenceGroup=============================================
	CREATE TABLE IF NOT EXISTS CTS_DataCenter.EvidenceGroup(
		EvidenceGroupID			TINYINT			AUTO_INCREMENT		NOT NULL
		, EvidenceGroupName		VARCHAR(50)							NOT NULL
		, EvidenceGroupDesc		VARCHAR(200)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	NULL
		, OrderNo				SMALLINT							NULL
		, CreatedDate			DATETIME							NOT NULL
		, CreatedBy				INT									NOT NULL
		, IsActive				TINYINT								NOT NULL
        
        , PRIMARY KEY	PK_EvidenceGroup_EvidenceGroupID(EvidenceGroupID)
	) ENGINE=INNODB AUTO_INCREMENT=1;

	# ========EvidenceType===========================================
	CREATE TABLE IF NOT EXISTS CTS_DataCenter.Evidence(
		EvidenceID			SMALLINT		AUTO_INCREMENT			NOT NULL
		, EvidenceGroupID	TINYINT									NOT NULL
		, EvidenceCode		VARCHAR(10)								NOT NULL
		, EvidenceName		VARCHAR(50)								NOT NULL
		, EvidenceDesc		VARCHAR(200)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	NULL
		, OrderNo			SMALLINT								NOT NULL
		, CreatedDate		DATETIME								NOT NULL
		, CreatedBy			INT										NOT NULL
		, IsActive			TINYINT									NOT NULL
        
        , PRIMARY KEY	PK_Evidence_EvidenceID(EvidenceID)
        , UNIQUE INDEX	UX_Evidence_EvidenceGroupID_EvidenceCode(EvidenceGroupID, EvidenceCode)
	) ENGINE=INNODB  AUTO_INCREMENT=1;

/*	# =======CustEvidence============================================
	CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustEvidence(
		CustEvidID			BIGINT		UNSIGNED	AUTO_INCREMENT	NOT NULL
		, CTSCustID			BIGINT		UNSIGNED					NOT NULL
        , SubscriberID		INT										NOT NULL
		, EvidenceID		SMALLINT								NOT NULL
		, Remark			VARCHAR(500)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NULL
		, Level				TINYINT									NOT NULL	COMMENT 'Level 1 - 2'
		, FromCustID		BIGINT		UNSIGNED					NOT NULL
		, CreatedDate		DATETIME								NOT NULL
		, CreatedBy			INT										NOT NULL
		, IsCreatedByMaster	TINYINT									NOT NULL
        
        , PRIMARY KEY	PK_CustEvidence(SubscriberID, CTSCustID, FromCustID, EvidenceID, IsCreatedByMaster)
        , UNIQUE INDEX	UX_CustEvidence_CustEvidID(CustEvidID)
	) ENGINE=INNODB  AUTO_INCREMENT=1;
*/	
    # =======CustRetractEvidence============================================
	CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustRetractEvidence (
		CTSCustID 			BIGINT		UNSIGNED	NOT NULL
		, EvidenceID 		SMALLINT				 NOT NULL
		, Remark 			VARCHAR(500) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' DEFAULT NULL
		, CreatedDate 		DATETIME DEFAULT NULL
		, CreatedBy 		INT		 NOT NULL
		, PRIMARY KEY PK_CustRetractEvidence_CTSCustID_EvidenceID(CTSCustID, EvidenceID)
	) ENGINE=INNODB;
    
	# ========LogType===========================================
	CREATE TABLE  IF NOT EXISTS CTS_DataCenter.LogType(
		LogTypeID				SMALLINT		AUTO_INCREMENT		NOT NULL
		, LogTypeName			VARCHAR(50)							NULL
		, LogTypeDescription	VARCHAR(200)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	NULL
        
        , PRIMARY KEY	PK_LogType_LogTypeID(LogTypeID)
     ) ENGINE=INNODB  AUTO_INCREMENT=1;
     
	# ========IPLocation===========================================
	CREATE TABLE IF NOT EXISTS IPRangeLocation (
		IPRangeLocationID			INT 			NOT NULL 		AUTO_INCREMENT
		, IPRangeLocationCode		VARCHAR(64) 	DEFAULT NULL
		, FromIP					DECIMAL(50,0) 	NOT NULL
		, ToIP						DECIMAL(50,0) 	NOT NULL
		, CountryCode				VARCHAR(10) 	DEFAULT NULL
		, CountryName				VARCHAR(80) 	DEFAULT NULL
		, Region					VARCHAR(128) 	DEFAULT NULL
		, City						VARCHAR(100) 	DEFAULT NULL
		, ISPName					VARCHAR(256) 	DEFAULT NULL
		, Status					TINYINT		 	DEFAULT NULL 	COMMENT '0: Inactive; 1: Active'
		, CreatedDate				DATETIME 		DEFAULT NULL
		, PRIMARY KEY PK_IPRangeLocation_IPRangeLocationID(IPRangeLocationID)
		, UNIQUE KEY	UK_IPRangeLocation_FromIP_ToIP(FromIP,ToIP)
		, INDEX		IX_IPRangeLocation_IPRangeLocationCode(IPRangeLocationCode)
	) ENGINE=INNODB  AUTO_INCREMENT=1;

	CREATE TABLE IF NOT EXISTS IPRangeLocation_Initial (
		IPRangeLocationID 		INT				NOT NULL 		AUTO_INCREMENT
		, IPRangeLocationCode	VARCHAR(64) 	DEFAULT NULL
		, FromIP 				DECIMAL(50,0)	NOT NULL
		, ToIP 					DECIMAL(50,0)	NOT NULL
		, CountryCode			VARCHAR(10)		DEFAULT NULL
		, CountryName			VARCHAR(80)		DEFAULT NULL
		, Region				VARCHAR(128)	DEFAULT NULL
		, City					VARCHAR(100)	DEFAULT NULL
		, ISPName				VARCHAR(256)	DEFAULT NULL
		, Status				TINYINT			DEFAULT NULL COMMENT '0: Inactive; 1: Active'
		, CreatedDate 			DATETIME		DEFAULT NULL
		, PRIMARY KEY	PK_IPRangeLocation_Initial_IPRangeLocationID(IPRangeLocationID)
		, INDEX			IX_IPRangeLocation_Initial_FromIP_ToIP (FromIP,ToIP)
		, INDEX			IX_IPRangeLocation_Initial_IPRangeLocationCode (IPRangeLocationCode)
	) ENGINE=INNODB AUTO_INCREMENT=1;

	CREATE TABLE IF NOT EXISTS IPTableLog (
		IPTableLogID 			INT			NOT NULL 		AUTO_INCREMENT
		, UpdatedDate			DATETIME	DEFAULT NULL
		, IsNewUpdate			TINYINT		DEFAULT NULL	COMMENT '0: old, 1: New'
		, PRIMARY KEY	PK_IPTableLog_IPTableLogID(IPTableLogID)
		, INDEX 		IX_IPTableLog_IPType_Flag (IsNewUpdate)
	) ENGINE=INNODB AUTO_INCREMENT=1;

# ===================================================
CREATE TABLE IF NOT EXISTS CTS_DataCenter.StaticList
(
	ListID				INT
    , ItemID			SMALLINT
    , ListName			VARCHAR(100)
    , ListNameDisplay	VARCHAR(200)
    , ItemName			VARCHAR(100)
    , ItemNameDisplay	VARCHAR(200)
    , PriorityOrder		SMALLINT
    , Status			BOOL
    , Description		VARCHAR(200)    
    , CreatedDate		DATETIME
    
    , PRIMARY KEY PK_StaticList_ListID_ItemID(ListID, ItemID)
) ;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustRetractEvidence
(
	  CTSCustID			BIGINT		UNSIGNED	NOT NULL
    , EvidenceID		SMALLINT    NOT NULL
    , Remark			VARCHAR(500)
    , CreatedDate		DATETIME
    , CreatedBy			INT
    
    , PRIMARY KEY PK_CustRetractEvidence_CTSCustID_EvidenceID(CTSCustID,EvidenceID)
) ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustException
(	
	FromCTSCustID					BIGINT 	UNSIGNED	NOT NULL
    , ToCTSCustID					BIGINT	UNSIGNED	NOT NULL
	, LeastCTSCustID_Order			BIGINT	UNSIGNED	AS (LEAST(FromCTSCustID, ToCTSCustID)) 		STORED
    , GreatestCTSCustID_Order		BIGINT	UNSIGNED	AS (GREATEST(FromCTSCustID, ToCTSCustID))	STORED
    , CreatedDate		DATETIME	NULL
    , CreatedBy			BIGINT		NULL	
    , Comment			VARCHAR(500)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	NULL
	
    , PRIMARY KEY	PK_CustException_FromCTSCustID_ToCTSCustID(LeastCTSCustID_Order,GreatestCTSCustID_Order)
) ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.ProcessAffectedEvidence
(	
	LastCTSAssDevID		BIGINT	UNSIGNED
)  ENGINE=INNODB;


CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociationByManual (
	FromSubscriberID		INT		UNSIGNED
	, FromCTSCustID			BIGINT	UNSIGNED
	, ToSubscriberID		INT		UNSIGNED
	, ToCTSCustID			BIGINT	UNSIGNED
	, Remark				VARCHAR(500) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
	, CreatedDate			DATETIME
    , CreatedBy				BIGINT
	, PRIMARY KEY	PK_AssociationByManual_FromCustIDToCustID(FromCTSCustID, ToCTSCustID)
	, INDEX			IX_AssociationByManual_ToCTSCustID(ToCTSCustID)
    , INDEX			IX_AssociationByManual_FromSubscriberIDToSubscriberID(FromSubscriberID, ToSubscriberID)
	, INDEX			IX_AssociationByManual_CreatedDate(CreatedDate)
) ENGINE=INNODB AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociationRemove (
	FromSubscriberID		INT		UNSIGNED
	, FromCTSCustID			BIGINT	UNSIGNED
	, ToSubscriberID		INT		UNSIGNED
	, ToCTSCustID			BIGINT	UNSIGNED
	, Remark				VARCHAR(500) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
	, CreatedDate			DATETIME
    , CreatedBy				BIGINT
	, PRIMARY KEY	PK_AssociationRemove_FromCustIDToCustID(FromCTSCustID, ToCTSCustID)
	, INDEX			IX_AssociationRemove_ToCTSCustID(ToCTSCustID)
	, INDEX			IX_AssociationRemove_FromSubscriberIDToSubscriberID(FromSubscriberID, ToSubscriberID)
	, INDEX			IX_AssociationRemove_CreatedDate(CreatedDate)
) ENGINE=INNODB AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.SportGroup (
		SportGroupID		SMALLINT UNSIGNED AUTO_INCREMENT
	, 	SportGroupName		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    ,	MainDBSportID		SMALLINT UNSIGNED
	, 	DisplayOrder		TINYINT UNSIGNED
    ,	IsActive			BIT DEFAULT 1
	, 	CreatedDate			DATETIME
    ,	CreatedBy			INT UNSIGNED
	, 	PRIMARY KEY		PK_SportGroup_SportGroupIDDisplayOrder(SportGroupID,DisplayOrder)
	, 	INDEX			IX_SportGroup_MainDBSportID(MainDBSportID));

CREATE TABLE IF NOT EXISTS CTS_DataCenter.SmartGroup (
		GroupID				INT UNSIGNED NOT NULL
    ,   CustID				INT UNSIGNED NOT NULL
    ,	Username			VARCHAR(64) NOT NULL
    , 	Similarity			FLOAT NOT NULL DEFAULT '0'
    ,	Currency 			VARCHAR(8) NOT NULL
    ,	Site	 			VARCHAR(32) NOT NULL
    , 	AgentID				INT UNSIGNED NOT NULL 
    , 	AgentName			VARCHAR(64) NOT NULL
    , 	MasterID			INT UNSIGNED NOT NULL 
    , 	MasterName			VARCHAR(64) NOT NULL
    , 	SuperID				INT UNSIGNED NOT NULL 
    , 	SuperName			VARCHAR(64) NOT NULL
    , 	CreatedDate			DATETIME DEFAULT NULL
    , 	PRIMARY KEY			PK_SmartGroup_CustIDGroupID(CustID, GroupID)
    , 	INDEX				IX_SmartGroup_Username(Username)
) ENGINE=INNODB DEFAULT CHARSET='UTF8MB4' COLLATE='UTF8MB4_UNICODE_CI';

CREATE TABLE IF NOT EXISTS CTS_DataCenter.SmartGroupHistory (
		GroupID				INT UNSIGNED NOT NULL
    ,   CustID				INT UNSIGNED NOT NULL
    ,	Username			VARCHAR(64) NOT NULL
    , 	Similarity			FLOAT NOT NULL DEFAULT '0'
    ,	Currency 			VARCHAR(8) NOT NULL
    ,	Site	 			VARCHAR(32) NOT NULL
    , 	AgentID				INT UNSIGNED NOT NULL 
    , 	AgentName			VARCHAR(64) NOT NULL
    , 	MasterID			INT UNSIGNED NOT NULL 
    , 	MasterName			VARCHAR(64) NOT NULL
    , 	SuperID				INT UNSIGNED NOT NULL 
    , 	SuperName			VARCHAR(64) NOT NULL
    , 	CreatedDate			DATE NOT NULL
    , 	PRIMARY KEY			PK_SmartGroup_CustIDGroupID(CustID, CreatedDate)
    , 	INDEX				IX_SmartGroup_Username(Username)
) ENGINE=INNODB DEFAULT CHARSET='UTF8MB4' COLLATE='UTF8MB4_UNICODE_CI';
  
) ENGINE=INNODB AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS 	CTS_DataCenter.CustomerCategory (
		CategoryID			SMALLINT UNSIGNED AUTO_INCREMENT
	, 	CategoryName		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    , 	CategorySpec		VARCHAR(200) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    ,	ParentID			SMALLINT UNSIGNED
	, 	DisplayOrder		TINYINT UNSIGNED
    ,	IsActive			BIT DEFAULT 1
	, 	CreatedDate			DATETIME
    ,	CreatedBy			INT UNSIGNED
    , 	LastModifiedDate	DATETIME
    ,	LastModifiedBy		INT UNSIGNED
    ,	IsUsedManually		BIT	
    , 	ScanIntervalInSecond	BIGINT
	, 	PRIMARY KEY			PK_CustomerCategory_CategoryIDDisplayOrder(CategoryID,DisplayOrder)
	, 	INDEX				IX_CustomerCategory_ParentID(ParentID)
    , 	INDEX				IX_CustomerCategory_IsActive(IsActive)
) ENGINE=INNODB AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.CTSCustomerClassification (
		CustID				BIGINT UNSIGNED
	,	CTSCustID			BIGINT UNSIGNED
	, 	SubscriberID		INT	UNSIGNED
    ,	SportGroupID		SMALLINT UNSIGNED
	, 	CategoryID			SMALLINT UNSIGNED    
	, 	Remark				VARCHAR(500) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
	, 	CreatedDate			DATETIME
    ,	CreatedBy			INT
    , 	LastModifiedDate	DATETIME
    ,	LastModifiedBy		INT UNSIGNED
    ,	LastScannedDate		DATETIME
	, 	PRIMARY KEY			PK_CTSCustomerClassification_CustIDSportGroupIDCategoryID(CustID, SportGroupID, CategoryID)
    ,   INDEX				IX_CTSCustomerClassification_CategoryIDLastScannedDate(CategoryID, LastScannedDate, SportGroupID, CustID)
    , 	INDEX 				IX_CTSCustomerClassification_CTSCustID(CTSCustID)
) ENGINE=INNODB;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.CTSCustomerClassification_History (
		ID					BIGINT UNSIGNED AUTO_INCREMENT
	,	CustID				BIGINT UNSIGNED
    ,  	CTSCustID			BIGINT UNSIGNED
	, 	CategoryID			SMALLINT UNSIGNED
    ,	SportGroupID		SMALLINT UNSIGNED
    , 	LastModifiedDate	DATETIME
    ,	LastModifiedBy		INT UNSIGNED
    , 	TurnoverRM			DECIMAL(20,4)
    , 	WinlossRM			DECIMAL(20,4)
    , 	BetCount			BIGINT
	, 	ActiveDays			INT
    ,	ActionType			TINYINT
    ,	IsAuto				BIT
    , 	InsertDate			DATETIME
    , 	PRIMARY KEY			PK_CTSCustomerClassificationHistory_ID(ID)
	, 	INDEX				IX_CTSCustomerClassificationHistory_CustIDSportGroupID(CustID, SportGroupID)
    ,	INDEX				IX_CTSCustomerClassificationHistory_LastModifiedDate(LastModifiedDate)
) ENGINE=INNODB AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS  CTS_DataCenter.CTSCustomerClassification_ScanStatus
(
	ScanTime		DATETIME
    , LastCustID	BIGINT UNSIGNED
    , ScanStatus	TINYINT				# 0-Inprogress, 1-Done
    
    ,PRIMARY KEY	PK_CTSCustomerClassification_ScanStatus_ScannedTime(ScanTime)
);

CREATE TABLE IF NOT EXISTS CTS_DataCenter.SmartGroup (
		GroupID				INT UNSIGNED NOT NULL
    ,   CustID				INT UNSIGNED NOT NULL
	,	Username			VARCHAR(64) NOT NULL
	, 	Similarity			FLOAT NOT NULL DEFAULT '0'
    ,	Currency 			VARCHAR(8) NOT NULL
    ,	Site	 			VARCHAR(32) NOT NULL
	, 	AgentID				INT UNSIGNED NOT NULL 
	, 	AgentName			VARCHAR(64) NOT NULL
    , 	MasterID			INT UNSIGNED NOT NULL 
	, 	MasterName			VARCHAR(64) NOT NULL
    , 	SuperID				INT UNSIGNED NOT NULL 
	, 	SuperName			VARCHAR(64) NOT NULL
	, 	CreatedDate			DATETIME DEFAULT NULL
	, 	PRIMARY KEY			PK_SmartGroup_CustIDGroupID(CustID, GroupID)
	, 	INDEX				IX_SmartGroup_Username(Username)
) ENGINE=INNODB DEFAULT CHARSET='UTF8MB4' COLLATE='UTF8MB4_UNICODE_CI';

CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociatedAccountMonitor (
		CTSCustID			INT UNSIGNED NOT NULL
	,	Remark				VARCHAR(200) NOT NULL
	, 	CreatedBy			INT UNSIGNED NOT NULL
    , 	CreatedTime			DATETIME NOT NULL
	, 	PRIMARY KEY			PK_AssociatedAccountMonitor_CTSCustID(CTSCustID)
) ENGINE=INNODB DEFAULT CHARSET='UTF8MB4' COLLATE='UTF8MB4_UNICODE_CI';

CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociatedAccountNewAssociation (
		AccountNewAssID			BIGINT UNSIGNED AUTO_INCREMENT
    ,	CTSCustID				INT UNSIGNED NOT NULL
	,	UserName				VARCHAR(50) NOT NULL
	, 	NewAssCount				SMALLINT UNSIGNED NOT NULL DEFAULT 0
    , 	CreatedDate				DATE NOT NULL
    , 	CreatedTime				DATETIME NOT NULL
	, 	PRIMARY KEY				PK_AssociatedAccountNewAssociation_AccountNewAssID(AccountNewAssID)
    ,	INDEX					IX_AssociatedAccountNewAssociation_CTSCustID(CTSCustID)
    ,	INDEX					IX_AssociatedAccountNewAssociation_CreatedDate(CreatedDate)
) ENGINE=INNODB DEFAULT CHARSET='UTF8MB4' COLLATE='UTF8MB4_UNICODE_CI';

CREATE TABLE IF NOT EXISTS CTS_DataCenter.CTSUserNotificationParameter (
		UserID					INT UNSIGNED PRIMARY KEY
    ,	FromNewAssID			BIGINT UNSIGNED DEFAULT 0
    ,	ToNewAssID				BIGINT UNSIGNED DEFAULT 0
) ENGINE=INNODB DEFAULT CHARSET='UTF8MB4' COLLATE='UTF8MB4_UNICODE_CI';

CREATE TABLE IF NOT EXISTS CTS_DataCenter.SystemParameter (
		ParameterID				SMALLINT UNSIGNED PRIMARY KEY
    ,	ParameterName			VARCHAR(50)
    ,	ParameterDesc			VARCHAR(200)
    ,	ParameterDataType		VARCHAR(50)
    ,	ParameterValue			VARCHAR(200)
) ENGINE=INNODB DEFAULT CHARSET='UTF8MB4' COLLATE='UTF8MB4_UNICODE_CI';

#- 20200807@Casey.Huynh: Chagne CustEvidence Structure

	# =======CustEvidence============================================
    DROP TABLE IF EXISTS CTS_DataCenter.CustEvidence;
	CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustEvidence(
		CustEvidID			BIGINT		UNSIGNED	AUTO_INCREMENT	NOT NULL
		, CTSCustID			BIGINT		UNSIGNED					NOT NULL
		, EvidenceID		SMALLINT								NOT NULL
		, Remark			VARCHAR(500)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NULL
		, Level				TINYINT									NOT NULL	COMMENT 'Level 1 - 2'
		, FromCustID		BIGINT		UNSIGNED					NOT NULL
		, CreatedDate		DATETIME								NOT NULL
		, CreatedBy			INT										NOT NULL
        
        , PRIMARY KEY	PK_CustEvidence(CTSCustID, FromCustID, EvidenceID)
        , INDEX			IX_CustEvidence(FromCustID, CTSCustID, EvidenceID)
        , UNIQUE INDEX	UX_CustEvidence_CustEvidID(CustEvidID)
	) ENGINE=INNODB  AUTO_INCREMENT=1;
	
# - 138575@Roger.Le: Enhance Associated Account Monitor by NAP Permission
DROP TABLE IF EXISTS CTS_DataCenter.CTSUserPermission;
CREATE TABLE IF NOT EXISTS CTS_DataCenter.CTSUserPermission (
		UserID					INT UNSIGNED
	,	FunctionName			VARCHAR(50)
    ,	GrantedFrom				DATETIME DEFAULT NULL
    ,	GrantedTo				DATETIME DEFAULT NULL
	, 	CreatedDate				DATETIME DEFAULT NULL
    , 	LastModifiedDate		DATETIME DEFAULT NULL
	,	INDEX					IX_CTSUserPermission(UserID, FunctionName)
) ENGINE=INNODB DEFAULT CHARSET='UTF8MB4' COLLATE='UTF8MB4_UNICODE_CI';


	DROP TABLE IF EXISTS CTS_DataCenter.CustEvidenceLog;
	CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustEvidenceLog(
		CustEvidID			BIGINT		UNSIGNED	AUTO_INCREMENT	NOT NULL
		, CTSCustID			BIGINT		UNSIGNED					NOT NULL
		, EvidenceID		SMALLINT								NOT NULL
		, Remark			VARCHAR(500)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' NULL
		, Level				TINYINT									NOT NULL	COMMENT 'Level 0 - 2'
		, FromCustID		BIGINT		UNSIGNED					NOT NULL
		, CreatedDate		DATETIME								NOT NULL
		, CreatedBy			INT										NOT NULL
		, SessionId			BIGINT									NOT NULL
        
        , PRIMARY KEY	CustEvidenceLog(CustEvidID)
		, INDEX			IX_CustEvidenceLog(SessionId)
	) ENGINE=INNODB  AUTO_INCREMENT=1;
	