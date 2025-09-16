/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250822@Casey.Huynh
Task:	 	AI Power Device Fingerprint
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20250822@Casey.Huynh: Created [Redmine ID: #236716]
Reviewer:
*/

USE DCS_DataCenter;

# ---------------------NEW TABLES--------------------------------------
DROP TABLE IF EXISTS WebRTCIP;
CREATE TABLE WebRTCIP(
		WebRTCIPID		BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	WebRTCIPCode 	VARCHAR(32) NOT NULL   
	,	WebRTCIPDetails	LONGTEXT NULL   
	,	CreatedDate		DATE NOT NULL    
	,	LastUsedDate	DATE NOT NULL
    
	,	UNIQUE KEY UX_FPDetailsWebRTCIP_FPDetailsCode(WebRTCIPID)
    ,	INDEX IX_FPDetailsWebRTCIP_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPGroupHardware;
CREATE TABLE FPGroupHardware(
		FPGroupHardwareID	BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	HardwareCode 		VARCHAR(32) NOT NULL   
	,	HardwareDetails		LONGTEXT NULL 
	,	CreatedDate			DATE NOT NULL    
	,	LastUsedDate		DATE NOT NULL
    
	,	UNIQUE KEY UX_FPGroupHardware_FPGroupCode(HardwareCode)
    ,	INDEX IX_FPGroupHardware_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPGroupGraphic;
CREATE TABLE FPGroupGraphic(
		FPGroupGraphicID		BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	GraphicCode 			VARCHAR(32) NOT NULL   
	,	GraphicDetails			LONGTEXT NULL 
	,	CreatedDate				DATE NOT NULL    
	,	LastUsedDate			DATE NOT NULL
    
	,	UNIQUE KEY UX_FPGroupGraphic_FPGroupCode(GraphicCode)
    ,	INDEX IX_FPGroupGraphic_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPGroupAudio;
CREATE TABLE FPGroupAudio(
		FPGroupAudioID	BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	AudioCode 		VARCHAR(32) NOT NULL   
	,	AudioDetails	LONGTEXT NULL  
	,	CreatedDate		DATE NOT NULL    
	,	LastUsedDate	DATE NOT NULL
    
	,	UNIQUE KEY UX_FPGroupAudio_FPGroupCode(AudioCode)
    ,	INDEX IX_FPGroupAudio_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPGroupBrowser;
CREATE TABLE FPGroupBrowser(
		FPGroupBrowserID		BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	BrowserCode 			VARCHAR(32) NOT NULL   
	,	BrowserDetails			LONGTEXT NULL 
	,	CreatedDate				DATE NOT NULL    
	,	LastUsedDate			DATE NOT NULL
    
	,	UNIQUE KEY UX_FPGroupBrowser_FPGroupCode(BrowserCode)
    ,	INDEX IX_FPGroupBrowser_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPGroupPreferences;
CREATE TABLE FPGroupPreferences(
		FPGroupPreferencesID		BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	PreferencesCode 			VARCHAR(32) NOT NULL   
	,	PreferencesDetails			LONGTEXT NULL  
	,	CreatedDate					DATE NOT NULL    
	,	LastUsedDate				DATE NOT NULL
    
	,	UNIQUE KEY UX_FPGroupPreferences_FPGroupCode(PreferencesCode)
    ,	INDEX IX_FPGroupPreferences_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPPattern;
CREATE TABLE FPPattern(
		FPPatternID 	BIGINT UNSIGNED	AUTO_INCREMENT PRIMARY KEY
	,	FPPatternType	TINYINT NOT NULL COMMENT 'Pattern Group Combinition'
    ,	FPPatternCode 	VARCHAR(32) NOT NULL    
    ,	CreatedDate		DATE NOT NULL    
	,	LastUsedDate	DATE NOT NULL
	
    ,	UNIQUE KEY UX_FPPattern_FPCode(FPPatternType, FPPatternCode)
    ,	INDEX IX_FPPattern_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS RawFingerprintQueue;
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

DROP TABLE IF EXISTS FPPatternGroup;
CREATE TABLE FPPatternGroup(
		FPPatternID 	BIGINT UNSIGNED NOT NULL
	,	FPPatternType	TINYINT NOT NULL COMMENT 'Pattern Group Combinition'
    ,	FPGroupID 		BIGINT UNSIGNED	NOT NULL
    ,	FPGroupType 	TINYINT UNSIGNED NOT NULL COMMENT '1:Hardware, 2:Graphic, 3.Audio, 4. Browser, 5.Prereference'
	
    ,	PRIMARY KEY PK_FPPatternGroup_FPCode(FPPatternID, FPGroupType, FPGroupID)
);

DROP TABLE IF EXISTS DeviceFPPattern;
CREATE TABLE DeviceFPPattern(
		DeviceID		BIGINT UNSIGNED NOT NULL
    ,	FPPatternID		BIGINT UNSIGNED NOT NULL
    ,	FPPatternType	TINYINT NOT NULL
	,	InsertedTime	DATETIME(4) NOT NULL

    ,	PRIMARY KEY PK_FPPattern_FPCode(DeviceID, FPPatternID)
    ,	INDEX IX_FPPattern_FPPatternTypeFPPatternID(FPPatternType, FPPatternID)
);

DROP TABLE IF EXISTS FPIntegrateSubscriber;
CREATE TABLE FPIntegrateSubscriber(
		SubscriberID		INT
    ,   SubscriberName		VARCHAR(100) NOT NULL
    ,	InsertedTime		DATETIME(4) NOT NULL

    ,	PRIMARY KEY PK_FPIntegrateSubscriber_SubscriberID(SubscriberID)
); 

DROP TABLE IF EXISTS FPAttribute;
CREATE TABLE FPAttribute(
		FPAttributeID		INT NOT NULL
    ,   AttributeName		VARCHAR(100) NOT NULL
    ,	AttributeShortName  VARCHAR(4) NOT NULL
    ,	GroupName			VARCHAR(100) NOT NULL
	,	IsActive			BOOLEAN NOT NULL
    ,	CreatedTime			DATETIME(4) NOT NULL

    ,	PRIMARY KEY PK_FPAttribute(FPAttributeID)
    ,	INDEX IX_FPAttribute(GroupName,FPAttributeID)
); 
#==========================================================================

ALTER TABLE RawTransaction
		ADD COLUMN WebRTCIPCode 	VARCHAR(32)
	,	ADD COLUMN FPPatternCode01	VARCHAR(32) 
	,	ADD COLUMN FPPatternCode02	VARCHAR(32)
;

ALTER TABLE ProcessedTransaction
		ADD COLUMN WebRTCIPCode 	VARCHAR(32)
	,	ADD COLUMN FPPatternCode01	VARCHAR(32)
	,	ADD COLUMN FPPatternCode02	VARCHAR(32)
;

ALTER TABLE Transaction
		ADD COLUMN WebRTCIPID 		BIGINT UNSIGNED       
	,	ADD COLUMN FPPatternID01	BIGINT UNSIGNED 
	,	ADD COLUMN FPPatternID02	BIGINT UNSIGNED   
;

ALTER TABLE Transaction07
		ADD COLUMN WebRTCIPID     BIGINT UNSIGNED
	,	ADD COLUMN FPPatternID01  BIGINT UNSIGNED 
	,	ADD COLUMN FPPatternID02  BIGINT UNSIGNED  
;

#================================================================================================================

INSERT INTO FPIntegrateSubscriber(SubscriberID, SubscriberName, InsertedTime)
SELECT SubscriberID, SubscriberName, NOW() AS InsertedTime
FROM CTS_Admin.Subscriber
WHERE SubscriberName IN ('Alpha');

INSERT INTO FPAttribute(FPAttributeID, AttributeName, GroupName, AttributeShortName, IsActive, CreatedTime)
VALUES(1,'platform','Hardware','plf',1, NOW())
,(2,'cpuClass','Hardware','ccl',1, NOW())
,(3,'architecture','Hardware','arc',1, NOW())
,(4,'oscpu','Hardware','osc',1, NOW())
,(5,'hardwareConcurrency','Hardware','hwc',1, NOW())
,(6,'deviceMemory','Hardware','dvm',1, NOW())
,(7,'canvas','Graphics','cnv',1, NOW())
,(8,'webglBasics','Graphics','wgb',1, NOW())
,(9,'webglExtensions','Graphics','wgx',1, NOW())
,(10,'fonts','Graphics','fnt',1, NOW())
,(11,'fontPreferences','Graphics','fpr',1, NOW())
,(12,'screenResolution','Graphics','scr',1, NOW())
,(13,'screenFrame','Graphics','sfr',1, NOW())
,(14,'colorDepth','Graphics','cld',1, NOW())
,(15,'colorGamut','Graphics','clg',1, NOW())
,(16,'audio','Audio','aud',1, NOW())
,(17,'audioBaseLatency','Audio','abl',1, NOW())
,(18,'browserName','Browser','brn',1, NOW())
,(19,'osName','Browser','osn',1, NOW())
,(20,'userAgent','Browser','uag',1, NOW())
,(21,'vendor','Browser','vdr',1, NOW())
,(22,'vendorFlavors','Browser','vfl',1, NOW())
,(23,'plugins','Browser','plg',1, NOW())
,(24,'pdfViewerEnabled','Browser','pve',1, NOW())
,(25,'languages','Preference','lng',1, NOW())
,(26,'timezone','Preference','tze',1, NOW())
,(27,'touchSupport','Preference','tsp',1, NOW())
,(28,'sessionStorage','Preference','ssg',1, NOW())
,(29,'openDatabase','Preference','odb',1, NOW())
,(30,'localStorage','Preference','lst',1, NOW())
,(31,'indexedDB','Preference','idb',1, NOW())
,(32,'cookiesEnabled','Preference','cke',1, NOW())
,(33,'rtc','IP (WebRTC)','rtc',1, NOW());

SELECT * FROM FPAttribute;

