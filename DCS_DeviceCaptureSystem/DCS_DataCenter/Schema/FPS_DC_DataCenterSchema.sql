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
        , DeviceKey				BIGINT 			NOT NULL		COMMENT 'CRC32(FirstDeviceCode)'
		, FirstDeviceCode		VARCHAR(32)		NULL
        , UserAgentKey			BIGINT			NULL
        , FirstTransID			BIGINT			NULL
        , DeviceStatus			TINYINT			NULL			COMMENT 'New Device, Old Device'
        , CreatedDate			DATETIME		NULL        	COMMENT 'Date Only, Date of First Transaction'
        , InsertTime			TIMESTAMP(4)	NULL			COMMENT 'DateTime, the time that data Insert to Table'
        
        , PRIMARY KEY	PK_Device_DeviceKey(DeviceKey)
        , UNIQUE KEY	UK_Device_ID(DeviceID)
        , INDEX			IX_Device_CreatedDate(CreatedDate)        
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
# ======Device=============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.DeviceCode(
		DeviceCodeID			BIGINT	UNSIGNED	AUTO_INCREMENT
		, DeviceCodeKey			BIGINT			NOT NULL		COMMENT '= CRC32(DeviceCode)'
		, DeviceCode			VARCHAR(32) 	NOT NULL		COMMENT ' DeviceCode Captured From DI'
        , DeviceID				BIGINT			NULL        
        , FirstDeviceCode		VARCHAR(32)		NULL			COMMENT 'DeviceCode Of Device. Defferent with DeviceCode Field'
        , LastStatus			TINYINT			NULL			
		, FirstTransID	BIGINT			NULL
        , FirstStatus			TINYINT			NULL
        , CreatedDate			DATETIME		NULL
        , InsertTime			TIMESTAMP(4)	NULL
        
        , PRIMARY KEY	PK_DeviceCode_DeviceCodeKey(DeviceCodeKey)
        , UNIQUE KEY	UK_DeviceCode_ID(DeviceCodeID)
        , INDEX			IX_DeviceCode_CreatedDate(CreatedDate)
        , INDEX			IX_DeviceCode_DeviceID(DeviceID)
        
        
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
     
# ======DeviceDetail=============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.DeviceFingerprint(
		FingerprintID			BIGINT	UNSIGNED	AUTO_INCREMENT
		, FingerprintKey		BIGINT 			UNSIGNED NOT NULL
        , FingerprintCode		VARCHAR(620)	NOT NULL
		, FingerprintMoreInfo	TEXT			NULL
        , UserAgentKey			BIGINT			NULL
		, PluginID				BIGINT			NULL
        , DeviceID				BIGINT			NULL
        , CreatedDate			DATETIME		NULL
        , InsertTime			TIMESTAMP(4)	NULL
        
        , PRIMARY KEY	PK_Fingerprint_FingerprintKey(FingerprintKey)
		, UNIQUE KEY	UK_DeviceFingerprint_FingerprintID(FingerprintID)
        , INDEX			IX_Fingerprint_FingerprintCode(DeviceID)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
    
# =======Association============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.Association(
		AssociationID		BIGINT	UNSIGNED	AUTO_INCREMENT					
		, AssociationKey	BIGINT 		NOT NULL
		, DeviceID			BIGINT		NOT NULL
		, AccountID			BIGINT		NOT NULL
		, SubscriberID		INT			NOT NULL
		, CreatedDate		DATETIME	NOT NULL		
        , InsertTime		TIMESTAMP(4)	NULL
        
        , PRIMARY KEY	PK_Association_AssociationKey(AssociationKey)
        , UNIQUE KEY	UK_Association_AssociationID(AssociationID)
        , INDEX	IX_Association_SubscriberID_AccountID_DeviceID(SubscriberID, AccountID, DeviceID)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

# =======Account============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.`Account`(
		AccountID			BIGINT		UNSIGNED	AUTO_INCREMENT	NOT NULL        
        , LoginName			VARCHAR(100)							NOT NULL
        , LoginNameKey		BIGINT		UNSIGNED					NOT NULL	COMMENT 'CRC32(LOWER(LoginName))'
        , SubscriberID		INT										NOT NULL
        , SubscriberType	TINYINT									NULL
		, CreatedDate		DATETIME								NULL
        , LastArchivedDate	DATETIME								NULL			
        , InsertTime		TIMESTAMP(4)							NULL
        
        , PRIMARY KEY	PK_Account_AccountID(AccountID)
        , UNIQUE KEY	UK_Account_SubscriberIDLoginName(SubscriberID, LoginNameKey)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

# =======Transactions============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.`Transaction`(
		TransID				BIGINT	UNSIGNED					NOT NULL
		, LoginName			VARCHAR(100) 						NOT NULL
        , LoginNameKey		BIGINT				UNSIGNED		NOT NULL	COMMENT 'CRC32(LOWER(LoginName))'
        , TransTime			TIMESTAMP(4)						NOT	NULL                
        , SubscriberID		INT									NULL
        , AccountID			BIGINT				UNSIGNED		NULL
        , URLKey			BIGINT				UNSIGNED		NULL     
        , DeviceCode		VARCHAR(32)							NULL		COMMENT 'Trans Device Code'
		, DeviceCodeKey		BIGINT								NULL		
        , ReferDeviceID		BIGINT				UNSIGNED		NULL		
        , ReferDeviceCode	VARCHAR(32)							NULL
        , ReferDeviceStatus		TINYINT							NULL		COMMENT 'Trans Device Status at Insert Time'
        , FingerprintCodeKey	BIGINT			UNSIGNED		NULL
        , UserAgentKey		BIGINT				UNSIGNED		NULL
        , IP				VARCHAR(50)							NULL
        , ActionResultKey 	BIGINT								NULL
		, Flagged			SMALLINT							NULL		COMMENT 'captcha & browserless'		
        , PluginID			BIGINT 								NULL
        , TransStatus		BIT(16)								NULL
        , CreatedDate		DATETIME							NULL		COMMENT 'Date Only'	NOT	NULL
        , InsertTime		TIMESTAMP(4)						NULL
        
        , PRIMARY KEY	PK_Transaction_TransID(TransID)
        , INDEX			IX_Transaction_DeviceID(DeviceCode)
        , INDEX			IX_Transaction_SubscriberIDAccountID(SubscriberID, LoginNameKey)
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
		ActionResultID			BIGINT		
		, ActionResultKey		VARCHAR(200)	NOT NULL
        , ActionStatus			TINYINT			NOT NULL	COMMENT '0: Inactive; 1: Active; -1: Unhandled(Action has not defined in Intergrated Action List)'
        , CreatedDate			DATETIME		NOT NULL	COMMENT 'Date Only'
        
        , PRIMARY KEY 	PK_ActionResult_ActionResultID(ActionResultID)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;

# ===========================================================================	
    CREATE TABLE IF NOT EXISTS DCS_DataCenter.URL(
		URLKey				BIGINT			NOT NULL
		, URL				VARCHAR(250)	NULL
        , SubscriberID		INT				NULL
        , CreatedDate		DATETIME		NULL
        
        , PRIMARY KEY 	PK_URL_URLKey(URLKey)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
     
# =======UserAgent============================================
	CREATE TABLE IF NOT EXISTS DCS_DataCenter.UserAgent(
		UserAgentKey		BIGINT		UNSIGNED		NOT NULL
		, UserAgent		TEXT							NOT NULL	
        , BrowserID		SMALLINT						NULL
        , OSID			SMALLINT						NULL
        , OS			VARCHAR(100)					NULL
        , Browser		VARCHAR(100)					NULL
        , CreatedDate	DATETIME						NULL
        
        , PRIMARY KEY 	PK_UserAgent_UserAgentKey(UserAgentKey)
     ) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
# ==========TransStatus============================================
CREATE TABLE IF NOT EXISTS DCS_DataCenter.TransStatus(
	 TransStatusName VARCHAR(100)
     , StatusValue BIT(16)
     , Notes VARCHAR(200)
     , IsTransformed BIT(1)
     , CreatedDate DATETIME
     , PRIMARY KEY PK_TransStatus(StatusValue)
);
# ===================================================
CREATE TABLE IF NOT EXISTS DCS_DataCenter.zzTracePerformance (
	ID			BIGINT			AUTO_INCREMENT
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