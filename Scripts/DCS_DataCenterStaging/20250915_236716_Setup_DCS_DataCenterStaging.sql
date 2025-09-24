/*<info serverAlias="CTSMain-DCS_DataCenterStaging" databaseType="2"></info>*/
/*
Creator:	20250915@Casey.Huynh
Task:	 	AI Power Device Fingerprint
Server:  	Master
DBName:		DCS_DataCenterStaging

Revisions: 
		- 20250915@Casey.Huynh: Created [Redmine ID: #236716]
Reviewer:
*/
/**********************************************************/
CREATE DATABASE DCS_DataCenterStaging /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
/***********************************************************/

USE DCS_DataCenterStaging;

# ---------------------NEW TABLES--------------------------------------

CREATE TABLE WebRTCIP(
		WebRTCIPID		BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	WebRTCIPCode 	VARCHAR(32) NOT NULL   
	,	WebRTCIPDetails	LONGTEXT NULL   
	,	CreatedDate		DATE NOT NULL    
	,	LastUsedDate	DATE NOT NULL
    
	,	UNIQUE KEY UX_FPDetailsWebRTCIP_FPDetailsCode(WebRTCIPID)
    ,	INDEX IX_FPDetailsWebRTCIP_LastUsedDate(LastUsedDate)
);

CREATE TABLE FPPattern(
		FPPatternID 	BIGINT UNSIGNED	AUTO_INCREMENT PRIMARY KEY
	,	FPPatternType	TINYINT NOT NULL COMMENT 'Pattern Group Combinition'
    ,	FPPatternCode 	VARCHAR(32) NOT NULL    
    ,	CreatedDate		DATE NOT NULL    
	,	LastUsedDate	DATE NOT NULL
	
    ,	UNIQUE KEY UX_FPPattern_FPCode(FPPatternType, FPPatternCode)
    ,	INDEX IX_FPPattern_LastUsedDate(LastUsedDate)
);

CREATE TABLE RawFingerprintQueue(
		ID					BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	FPPatternID01		BIGINT UNSIGNED
	,	FPPatternID02		BIGINT UNSIGNED
	,	HardwareCode		VARCHAR(32)
	,	GraphicCode			VARCHAR(32)
	,	AudioCode			VARCHAR(32)
	,	BrowserCode			VARCHAR(32)
	,	PreferencesCode		VARCHAR(32)
	,	HardwareDetails		LONGTEXT
	,	GraphicDetails		LONGTEXT
	,	AudioDetails		LONGTEXT
	,	BrowserDetails		LONGTEXT
	,	PreferencesDetails	LONGTEXT
    ,	CreatedDate			DATE
);

#====================ALTER TABLE RawTransaction===================================
CREATE TABLE RawTransaction(
		LoginName VARCHAR(100)  NOT NULL
	,	SubscriberName VARCHAR(50)  NOT NULL
	,	TransTime TIMESTAMP(4) NOT NULL
	,	CreatedDate DATETIME NOT NULL COMMENT 'Date Only'
	,	DeviceCode VARCHAR(32)  DEFAULT NULL
	,	FingerprintCode VARCHAR(620)  DEFAULT NULL
	,	FingerprintMoreInfo VARCHAR(250)  DEFAULT NULL
	,	IP VARCHAR(50)  DEFAULT NULL
	,	IPID DECIMAL(50,0) DEFAULT NULL
	,	PluginID BIGINT DEFAULT NULL
	,	URL VARCHAR(500)  DEFAULT NULL
	,	Action VARCHAR(100)  DEFAULT NULL
	,	ActionResult VARCHAR(100)  DEFAULT NULL
	,	InvalidDevice VARCHAR(1000)  DEFAULT NULL
	,	TransStatus BIT(16) DEFAULT NULL COMMENT 'Refer Table TransStatus'
	,	FPSTransID BIGINT UNSIGNED DEFAULT NULL
	,	Flagged SMALLINT DEFAULT NULL
	,	IsProcessed TINYINT NOT NULL DEFAULT '0'
	,	TransID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	InsertTime TIMESTAMP(4) NULL DEFAULT NULL
	,	BotDetectionValue BIT(32) DEFAULT NULL
	,	BotComponentID BIGINT UNSIGNED DEFAULT NULL
	,	FakeIP VARCHAR(100)  DEFAULT NULL
	,	IsIncognitoMode TINYINT(1) DEFAULT NULL
	,	ChallengeCode VARCHAR(50)  DEFAULT NULL
	,	FP_Tagging VARCHAR(32)  DEFAULT NULL
	,	FP_FingerprintCode VARCHAR(32)  DEFAULT NULL
	,	FP_FingerprintExtraCode 	VARCHAR(32)  DEFAULT NULL
	,	FP_FingerprintOldCode 	VARCHAR(32)  DEFAULT NULL
	,	UserAgent 				VARCHAR(1000)  DEFAULT NULL
	,	FP_UserAgentCode		VARCHAR(32)  DEFAULT NULL
	,	WebRTCIPCode			VARCHAR(32)  DEFAULT NULL
	,	FPPatternCode01 	VARCHAR(32)  DEFAULT NULL 
	,	FPPatternCode02		VARCHAR(32)  DEFAULT NULL 
    ,	FPVersion		VARCHAR(10) 
	,	TransFlow		TINYINT(1) NOT NULL
	,	PRIMARY KEY(TransID) 
	,	KEY IX_RawTransaction_IsProcessed(IsProcessed) 
	,	KEY IX_RawTransaction_SubscriberName(SubscriberName,CreatedDate) 
	,	KEY IX_RawTransaction_CreatedDate(CreatedDate) 
) ENGINE=InnoDB;

#================================================================================

CREATE TABLE BotComponent(
		ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	Code VARCHAR(100)  NOT NULL
	,	Component LONGTEXT  NOT NULL
	,	CreatedDate DATETIME DEFAULT NULL
	,	IsHuman TINYINT(1) DEFAULT NULL
	,	ModifiedDate DATETIME DEFAULT NULL
	,	PRIMARY KEY(ID) 
	,	UNIQUE KEY UX_BotComponent_Code(Code) 
	,	KEY IX_BotComponent_ModifiedDate(ModifiedDate) 
) ENGINE=InnoDB;

CREATE TABLE BotDetection(
		Value bit(32) NOT NULL
	,	Name VARCHAR(100)  NOT NULL
	,	CreatedDate DATETIME DEFAULT NULL
	,	PRIMARY KEY(Value) 
	,	KEY IX_BotDetection_Name(Name) 
)ENGINE=InnoDB;

CREATE TABLE StaticList(
		ListID INT NOT NULL
	,	ItemID SMALLINT NOT NULL
	,	ListCode VARCHAR(100)  DEFAULT NULL
	,	ListName VARCHAR(200)  DEFAULT NULL
	,	ItemCode VARCHAR(100)  DEFAULT NULL
	,	ItemName VARCHAR(200)  DEFAULT NULL
	,	Status TINYINT(1) DEFAULT NULL
	,	Description VARCHAR(200)  DEFAULT NULL
	,	CreatedDate DATETIME DEFAULT NULL
	,	GroupID SMALLINT DEFAULT NULL
	,	GroupCode VARCHAR(100)  DEFAULT NULL
	,	GroupName VARCHAR(200)  DEFAULT NULL
	,	PRIMARY KEY(ListID,ItemID) 
	,	UNIQUE KEY UX_StaticList_ListCode_ItemCode(ListCode,ItemCode) 
)ENGINE=InnoDB;

CREATE TABLE MBRawTransactionIOS(
		ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	LoginName VARCHAR(100)  NOT NULL
	,	SubscriberName VARCHAR(50)  NOT NULL
	,	TransTime DATETIME(4) NOT NULL
	,	IP VARCHAR(50)  DEFAULT NULL
	,	IPID DECIMAL(50,0) DEFAULT NULL
	,	Action VARCHAR(100)  DEFAULT NULL
	,	ActionResult VARCHAR(100)  DEFAULT NULL
	,	Flagged SMALLINT DEFAULT NULL
	,	MBDeviceCodeMediaDRM VARCHAR(32)  DEFAULT NULL
	,	MBDeviceCodeMachine VARCHAR(32)  DEFAULT NULL
	,	MBDeviceCodeTagging VARCHAR(32)  DEFAULT NULL
	,	IsEmulator TINYINT DEFAULT NULL
	,	ModelName VARCHAR(32)  DEFAULT NULL
	,	Manufacturer VARCHAR(32)  DEFAULT NULL
	,	Brand VARCHAR(32)  DEFAULT NULL
	,	SDKVersion VARCHAR(32)  DEFAULT NULL
	,	OSName VARCHAR(32)  DEFAULT NULL
	,	CountryName VARCHAR(32)  DEFAULT NULL
	,	Timezone VARCHAR(32)  DEFAULT NULL
	,	Language VARCHAR(32)  DEFAULT NULL
	,	InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	,	DeviceDetails json DEFAULT NULL
	,	PRIMARY KEY(ID) 
	,	KEY IX_MBRawTransactionIOS_SubscriberName(SubscriberName) 
) ENGINE=InnoDB;

CREATE TABLE MBRawTransaction(
		ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	LoginName VARCHAR(100)  NOT NULL
	,	SubscriberName VARCHAR(50)  NOT NULL
	,	TransTime DATETIME(4) NOT NULL
	,	IP VARCHAR(50)  DEFAULT NULL
	,	IPID DECIMAL(50,0) DEFAULT NULL
	,	Action VARCHAR(100)  DEFAULT NULL
	,	ActionResult VARCHAR(100)  DEFAULT NULL
	,	Flagged SMALLINT DEFAULT NULL
	,	MBDeviceCodeMediaDRM VARCHAR(32)  DEFAULT NULL
	,	MBDeviceCodeMachine VARCHAR(32)  DEFAULT NULL
	,	MBDeviceCodeTagging VARCHAR(32)  DEFAULT NULL
	,	IsEmulator TINYINT DEFAULT NULL
	,	ModelName VARCHAR(32)  DEFAULT NULL
	,	Manufacturer VARCHAR(32)  DEFAULT NULL
	,	Brand VARCHAR(32)  DEFAULT NULL
	,	SDKVersion VARCHAR(32)  DEFAULT NULL
	,	OSName VARCHAR(32)  DEFAULT NULL
	,	CountryName VARCHAR(32)  DEFAULT NULL
	,	Timezone VARCHAR(32)  DEFAULT NULL
	,	Language VARCHAR(32)  DEFAULT NULL
	,	InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
	,	DeviceDetails json DEFAULT NULL
	,	PRIMARY KEY(ID) 
	,	KEY IX_MBRawTransaction_SubscriberName(SubscriberName) 
) ENGINE=InnoDB;

#============================================
INSERT INTO DCS_DataCenterStaging.StaticList(ListID,ItemID,ListCode,ListName,ItemCode,ItemName,Status,Description,CreatedDate,GroupID,GroupCode,GroupName)
SELECT ListID,ItemID,ListCode,ListName,ItemCode,ItemName,Status,Description,CreatedDate,GroupID,GroupCode,GroupName
FROM DCS_DataCenter.StaticList