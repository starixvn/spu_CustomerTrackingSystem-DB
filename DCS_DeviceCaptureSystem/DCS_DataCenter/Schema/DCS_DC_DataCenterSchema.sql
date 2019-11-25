/*
Creator: 20190521@Casey.Huynh
Task:    Create Schema FPS4.0 - Data Center
Server:  
DBName:	DCS_DataCenter

Reviewer: 
*/

CREATE DATABASE IF NOT EXISTS DCS_DataCenter;
CREATE TABLE IF NOT EXISTS DCS_DataCenter.Device(		
        DeviceID				BIGINT	UNSIGNED	AUTO_INCREMENT
		, FirstDeviceCode		VARCHAR(32)		NULL
        , UserAgentKey			VARCHAR(32)		NULL
        , FirstTransID			BIGINT			NULL
		, CreatedTime			TIMESTAMP(4)	NULL			COMMENT 'CreatedTime of First Transaction'
        , CreatedDate			DATETIME		NULL        	COMMENT 'Date Only, Date of First Transaction'
        , InsertTime			TIMESTAMP(4)	NULL			COMMENT 'DateTime, the time that data Insert to Table'
        
        , PRIMARY KEY	PK_Device_DeviceKey(DeviceID)
        , UNIQUE KEY	UK_Device_FirstDeviceCode(FirstDeviceCode)
        , INDEX			IX_Device_CreatedDate(CreatedDate)        
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
# ======Device=============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.DeviceCode(
		DeviceCodeID			BIGINT	UNSIGNED	AUTO_INCREMENT
		, DeviceCode			VARCHAR(32) 	NOT NULL		COMMENT ' DeviceCode Captured From DI'
        , DeviceID				BIGINT	UNSIGNED	NULL        			
		, FirstTransID			BIGINT			NULL
		, CreatedTime			TIMESTAMP(4)	NULL
        , CreatedDate			DATETIME		NULL
        , InsertTime			TIMESTAMP(4)	NULL
        
        , PRIMARY KEY	PK_DeviceCode_DeviceCodeID(DeviceCodeID)
        , UNIQUE KEY	UK_DeviceCode_DeviceCode(DeviceCode)
        , INDEX			IX_DeviceCode_CreatedDate(CreatedDate)
        , INDEX			IX_DeviceCode_DeviceID(DeviceID)      
        
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
     
# ======DeviceDetail=============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.DeviceFingerprint(
		DeviceFingerprintID		BIGINT	UNSIGNED	AUTO_INCREMENT
        , DeviceID				BIGINT	UNSIGNED	NULL
        , FingerprintCode		VARCHAR(620)	NOT NULL
		, FingerprintMoreInfo	TEXT			NULL
        , CreatedTime			TIMESTAMP(4)	NULL
        , CreatedDate			DATETIME		NULL
        , InsertTime			TIMESTAMP(4)	NULL
        
        , PRIMARY KEY	PK_Fingerprint_FingerprintKey(DeviceFingerprintID)
		, UNIQUE KEY	UK_DeviceFingerprint_FingerprintID(FingerprintCode,DeviceID)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
    
# =======Association============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.Association(
		AssociationID		BIGINT	UNSIGNED	AUTO_INCREMENT			
		, DeviceID			BIGINT	UNSIGNED	NOT NULL
		, AccountID			INT		UNSIGNED	NOT NULL
		, SubscriberID		INT				NOT NULL
        , CreatedTime		TIMESTAMP(4) 	NULL
        , CreatedDate		TIMESTAMP(4) 	NULL
        , InsertTime		TIMESTAMP(4)	NULL
        , IsCTSTransformed	TINYINT		DEFAULT 0
        , PRIMARY KEY	PK_Association_AssociationID(AssociationID)
        , INDEX	IX_Association_SubscriberID_AccountID_DeviceID(SubscriberID, AccountID, DeviceID)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
# =======IPAssociation============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.AssociationByIP(
		AssociationByIPID	BIGINT	UNSIGNED	AUTO_INCREMENT		
		, AccountID			INT		UNSIGNED	NOT NULL
		, SubscriberID		INT				NOT NULL
        , CreatedTime		TIMESTAMP(4) 	NULL
        , CreatedDate		TIMESTAMP(4) 	NULL
        , InsertTime		TIMESTAMP(4)	NULL
        , IsCTSTransformed	TINYINT		DEFAULT 0
        , PRIMARY KEY	PK_Association_AssociationID(AssociationID)
        , INDEX	IX_Association_SubscriberID_AccountID_DeviceID(SubscriberID, AccountID, DeviceID)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
# =======Account============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.`Account`(
		AccountID			INT		UNSIGNED	AUTO_INCREMENT	NOT NULL        
        , LoginName			VARCHAR(100)							NOT NULL
        , SubscriberID		INT										NOT NULL
        , SubscriberType	TINYINT									NULL
		, CreatedDate		DATETIME								NULL
        , LastArchivedDate	DATETIME								NULL			
        , InsertTime		TIMESTAMP(4)							NULL
        , IsCTSTransformed	TINYINT									DEFAULT 0
        
        , PRIMARY KEY	PK_Account_AccountID(AccountID)
        , UNIQUE KEY	UK_Account_SubscriberIDLoginName(SubscriberID, LoginName)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

# =======Transactions============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.`Transaction`(
		TransID				BIGINT	UNSIGNED					NOT NULL
		, LoginName			VARCHAR(100) 						NOT NULL
        , TransTime			TIMESTAMP(4)						NOT	NULL                
        , SubscriberID		INT									NULL
        , AccountID			INT				UNSIGNED			NULL
        , URLID				BIGINT			UNSIGNED			NULL
		, DeviceCodeID		BIGINT			UNSIGNED			NULL
		, DeviceID			BIGINT			UNSIGNED			NULL
        , FirstDeviceCode	VARCHAR(64)							NULL
        , DeviceStatus		TINYINT								NULL
        , DeviceFingerprintID	BIGINT			UNSIGNED		NULL
        , UserAgentKey		VARCHAR(32)							NULL
        , IP				VARCHAR(50)							NULL
        , IPID				BIGINT								NULL
        , ActionResultID 	BIGINT								NULL
		, Flagged			SMALLINT							NULL		COMMENT 'captcha & browserless'		
        , PluginID			BIGINT 								NULL
        , TransStatus		BIT(16)								NULL
        , CreatedDate		DATETIME							NULL		COMMENT 'Date Only'	NOT	NULL
        , InsertTime		TIMESTAMP(4)						NULL
        
        , PRIMARY KEY	PK_Transaction_TransID(TransID)
        , INDEX			IX_Transaction_SubscriberIDAccountID(SubscriberID, LoginName, AccountID)
        , INDEX			IX_Transaction_IPID_IP(IPID, IP)
        , INDEX			IX_Transaction_CreatedDate(CreatedDate)       
	 ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

# ===========================================================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.OS(
		OSID			SMALLINT		AUTO_INCREMENT	NOT NULL
		, OSName		VARCHAR(100)					NOT NULL
        , CreatedDate	DATETIME						NOT NULL
        
        , PRIMARY KEY 	PK_OS_ISID(OSID)
        , UNIQUE KEY	UK_OSName(OSName)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
     
# ===========================================================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.Browser(
		BrowserID			SMALLINT		AUTO_INCREMENT	NOT NULL
		, BrowserName		VARCHAR(100)					NOT NULL
        , CreatedDate		DATETIME						NOT NULL
        
        , PRIMARY KEY 	PK_Browser_BrowserID(BrowserID)
        , UNIQUE KEY	UK_BrowserName(BrowserName)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

# ===========================================================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.ActionResult(
		ActionResultID			INT				AUTO_INCREMENT
        , Action				VARCHAR(100)	NOT NULL
		, ActionResult			VARCHAR(100)	NOT NULL
        , ActionResultStatus	TINYINT			NOT NULL	COMMENT '0: Inactive; 1: Active; -1: Unhandled(Action has not defined in Intergrated Action List)'
        , CreatedDate			DATETIME		NOT NULL	COMMENT 'Date Only'
        
        , PRIMARY KEY 	PK_ActionResult_ActionResultID(ActionResultID)
        , UNIQUE KEY	UK_ActionResult_ActionResultDetails(Action, ActionResult)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

# ===========================================================================	
    CREATE TABLE IF NOT EXISTS DCS_DataCenter.URL(
		URLID				INT			AUTO_INCREMENT
        , SubscriberID		INT				NULL
		, URLDetails		VARCHAR(250)	NULL        
        , CreatedDate		DATETIME		NULL
        
        , PRIMARY KEY 	PK_URL_URLID(URLID)
        , UNIQUE KEY	UK_URL_URLDetails(URLDetails)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
     
# =======UserAgent============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.UserAgent(
		UserAgentKey	VARCHAR(32)		NOT NULL
		, UserAgent		TEXT			NOT NULL	
        , BrowserID		SMALLINT		NULL
        , OSID			SMALLINT		NULL
        , OS			VARCHAR(100)	NULL
        , Browser		VARCHAR(100)	NULL
        , CreatedDate	DATETIME		NULL
        
        , PRIMARY KEY 	PK_UserAgent_UserAgentKey(UserAgentKey)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
# ==========TransStatus============================================
CREATE TABLE IF NOT EXISTS DCS_DataCenter.TransStatus(
	 TransStatusName		VARCHAR(100)
     , StatusValue			BIT(16)
     , Notes				VARCHAR(200)
     , IsTransformed		BIT(1)
     , CreatedDate			DATETIME
     , PRIMARY KEY PK_TransStatus(StatusValue)
);
# ===================================================
CREATE TABLE IF NOT EXISTS DCS_DataCenter.zzTracePerformance (
	ID				BIGINT			AUTO_INCREMENT
    , ExecKey		BIGINT			NOT NULL
    , StepID		INT				NOT NULL
    , SPName		VARCHAR(200)	NOT NULL    
    , Notes			VARCHAR(200)	NULL
    , StartTime		TIMESTAMP(4)	NULL
    , EndTime		TIMESTAMP(4)	NULL
    , TotalRecord	INT				NULL
    , FromID		BIGINT			NULL
    , ToID			BIGINT			NULL
    , Duration		BIGINT			NULL
    
	, PRIMARY KEY PK_zzTracePerformance_ID(ID)
	, INDEX IX_zzTracePerformance_ExecKey_StepID(ExecKey,StepID)
) ENGINE=InnoDB ;