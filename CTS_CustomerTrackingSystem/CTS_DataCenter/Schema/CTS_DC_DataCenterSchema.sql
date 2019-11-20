/*
Creator: 20191106@CaseyHuynh + Harvey.Nguyen
Task:	 
Server:  
DBName:	CTS_DataCenter

Revisions: 
Reviewer:
*/

CREATE DATABASE IF NOT EXISTS CTS_DataCenter;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.CTSCustomer (
	CTSCustID			BIGINT	UNSIGNED	AUTO_INCREMENT
    , SubscriberID		INT	UNSIGNED
    , CustID			BIGINT	UNSIGNED
    , CustSubID		BIGINT	UNSIGNED
    , UserName			VARCHAR(50)
    , UserName2			VARCHAR(50)
    , Site				VARCHAR(20)
    , RoleID			INT
    , Currency			VARCHAR(10)
    , CurrencyID		INT		
    , SRecommend		BIGINT
    , MRecommend		BIGINT
    , Recommend			BIGINT
    , PRIMARY KEY	PK_CTSCustomer_CTSCustID(CTSCustID)    
	, INDEX	UIX_CTSCustomer_SubscriberID_UserName_UserName2(SubscriberID, UserName,UserName2)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociationByDevice(
	CTSAssDevID		BIGINT	UNSIGNED AUTO_INCREMENT
	, CTSCustID		BIGINT	UNSIGNED
    , DCSDeviceID	BIGINT
    , SubscriberID	INT
    , CreatedTime	TIMESTAMP(4)
    , InsertTime	TIMESTAMP(4)
    , PRIMARY KEY	PK_AssociationByDevice_CTSAssDevID(CTSAssDevID)    
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociationByIP(
	CTSAssIPID		BIGINT	UNSIGNED	AUTO_INCREMENT
	, CTSCustID		BIGINT	UNSIGNED
    , IP			BIGINT
    , SubscriberID	INT
    , ExpiredDate	TIMESTAMP(4)
    , CreatedTime	TIMESTAMP(4)
    , InsertTime	TIMESTAMP(4)
    , PRIMARY KEY	PK_AssociationByIP_CTSAssID(CTSAssIPID)    
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociatedCustomer(
	CTSCustID				BIGINT	UNSIGNED
	, AssociatedCTSCustID	BIGINT	UNSIGNED
    , SubscriberID			INT
    , AssType				TINYINT
    , CreatedTime			TIMESTAMP(4)
    , InsertTime			TIMESTAMP(4)
    , PRIMARY KEY	PK_AssociatedCustomer_CTSCustID_AssociatedCTSCustID(CTSCustID, AssociatedCTSCustID)    
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.AssociationType(
	AssTypeID				BIGINT	UNSIGNED AUTO_INCREMENT
	, TypeName				BIGINT	UNSIGNED
    , Description			INT
    , CreatedTime			TIMESTAMP(4)
    , InsertTime			TIMESTAMP(4)
    , PRIMARY KEY	PK_AssociationType_AssTypeID(AssTypeID)    
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;

CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustDCSAccount(
	CTSCustID			BIGINT	UNSIGNED
    , AccountID			BIGINT	UNSIGNED
    , SubscriberID		INT
    , InsertTime	TIMESTAMP(4)
    , PRIMARY KEY	PK_CustDCSAccount_AccountID(AccountID)    
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;


# ======EvidenceGroup=============================================
CREATE TABLE IF NOT EXISTS CTS_DataCenter.EvidenceGroup(
		EvidenceGroupID			TINYINT			AUTO_INCREMENT		NOT NULL
		, EvidenceGroupName		VARCHAR(50)							NOT NULL
		, EvidenceGroupDesc		VARCHAR(200)	CHARACTER SET UTF8MB4	NULL
		, OrderNo				SMALLINT							NULL
		, CreatedDate			DATETIME							NOT NULL
		, CreatedBy				INT									NOT NULL
		, IsActive				TINYINT						NOT NULL
        
        , PRIMARY KEY	PK_EvidenceGroup_EvidenceGroupID(EvidenceGroupID)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

# ========EvidenceType===========================================
CREATE TABLE IF NOT EXISTS CTS_DataCenter.Evidence(
		EvidenceID			SMALLINT		AUTO_INCREMENT			NOT NULL
		, EvidenceGroupID	TINYINT									NOT NULL
		, EvidenceCode		VARCHAR(10)								NOT NULL
		, EvidenceName		VARCHAR(50)								NOT NULL
		, EvidenceDesc		VARCHAR(200)	CHARACTER SET UTF8MB4	NULL
		, OrderNo			SMALLINT								NOT NULL
		, CreatedDate		DATETIME								NOT NULL
		, CreatedBy			INT										NOT NULL
		, IsActive			TINYINT									NOT NULL
        
        , PRIMARY KEY	PK_Evidence_EvidenceID(EvidenceID)
        , UNIQUE INDEX	UIX_Evidence_EvidenceGroupID_EvidenceCode(EvidenceGroupID, EvidenceCode)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

# =======CustEvidence============================================
CREATE TABLE IF NOT EXISTS CTS_DataCenter.CustEvidence(
		CustEvidID			BIGINT		UNSIGNED	AUTO_INCREMENT	NOT NULL
		, CTSCustID			BIGINT		UNSIGNED					NOT NULL
        , SubscriberID		INT										NOT NULL
		, EvidenceID		SMALLINT								NOT NULL
		, Remark			VARCHAR(500)	CHARACTER SET UTF8MB4	NULL
		, `Level`			TINYINT									NOT NULL COMMENT 'Level 1 - 2'
		, FromCustID		BIGINT									NOT NULL
		, CreatedDate		DATETIME								NOT NULL
		, CreatedBy			INT										NOT NULL
		, IsCreatedByMaster	TINYINT									NOT NULL
		, IsRetracted		TINYINT									NOT NULL
        
        , PRIMARY KEY	PK_CustEvidence_CustEvidID(CustEvidID)
        , INDEX	IX_CustEvidence_EvidenceGroupID_EvidenceCode(SubscriberID, CTSCustID)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;


# ========LogType===========================================
	CREATE TABLE CTS_DataCenter.LogType(
		LogTypeID				SMALLINT		AUTO_INCREMENT		NOT NULL
		, LogTypeName			VARCHAR(50)							NULL
		, LogTypeDescription	VARCHAR(200)	CHARACTER SET UTF8MB4	NULL
        
        , PRIMARY KEY	PK_LogType_LogTypeID(LogTypeID)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;