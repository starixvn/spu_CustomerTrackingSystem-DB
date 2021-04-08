/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Creator: 	202104012@CaseyHuynh
	Task:	 	Delete DCSData By Unused Account [Redmine ID: #152454]
	DBName:		CTS_DataCenter

	Revisions:
				- 202104012@CaseyHuynh: Created [Redmine ID: #152454]
*/

/*1 SCHEMA AND INIT*/
USE CTS_Adhoc;
DROP TABLE IF EXISTS CS152454_DelUnuAccount_Account;
CREATE TABLE CS152454_DelUnuAccount_Account (
		AccountID			BIGINT	UNSIGNED NOT NULL
	,	LoginName			VARCHAR(100) CHARACTER	SET	utf8mb4	COLLATE	utf8mb4_unicode_ci	DEFAULT	NULL
	,	SubscriberID		INT	NOT	NULL
	,	SubscriberType		TINYINT	NOT	NULL
	,	CreatedTime			TIMESTAMP(4)	NOT	NULL
	,	LastLoginTime		TIMESTAMP(4)	NOT	NULL
	,	CreatedDate			DATETIME(4)	NOT	NULL
	,	InsertTime			TIMESTAMP(4)	NOT	NULL
	,	IsCTSTransformed	TINYINT	NOT	NULL	DEFAULT	'0'
    ,	CTSCustID			BIGINT	UNSIGNED
    ,	ActionType			TINYINT
	,	PRIMARY	KEY	(AccountID)
	,	INDEX IX_DelUnusedAccount_Account_LoginName(LoginName)
)	ENGINE=InnoDB;

USE CTS_Adhoc;
DROP TABLE IF EXISTS CS152454_DelUnuAccount_zzTrace;
CREATE TABLE CS152454_DelUnuAccount_zzTrace(
	ID	INT AUTO_INCREMENT PRIMARY KEY
    ,	SPName		VARCHAR(200)
    ,	Steps		INT
	,	StartTime	DATETIME(3)
    ,	EndTime		DATETIME(3)    
    ,	Notes		VARCHAR(100)
	,	INDEX IX_CS152454_DelUnuAccount_zzTrace(Steps)
);

USE CTS_Adhoc;
DROP TABLE IF EXISTS CS152454_DelUnuAccount_Account_Excluded; #Excluded the account exists in CTS_Adhoc.CustDCSAccount
CREATE TABLE CS152454_DelUnuAccount_Account_Excluded (
		AccountID 		BIGINT(20) UNSIGNED NOT NULL
    ,	SubscriberID 	INT(11) DEFAULT NULL
    ,	InsertTime 		TIMESTAMP(4) NULL DEFAULT NULL
    ,	cdaCTSCustID 	BIGINT(20) UNSIGNED DEFAULT NULL
,	PRIMARY KEY (AccountID)
) ENGINE=InnoDB;

USE CTS_Adhoc;
DROP TABLE IF EXISTS CS152454_DelUnuAccount_Association; 
CREATE TABLE CS152454_DelUnuAccount_Association (
		AssociationID BIGINT(20) UNSIGNED
	,	DeviceID BIGINT(20) UNSIGNED NOT NULL
	,	AccountID BIGINT(20) UNSIGNED NOT NULL
	,	SubscriberID INT(11) NOT NULL
	,	CreatedTime TIMESTAMP(4) NOT NULL
	,	CreatedDate TIMESTAMP(4) NOT NULL
	,	InsertTime TIMESTAMP(4) NOT NULL
	,	IsCTSTransformed TINYINT(4) NOT NULL DEFAULT '0'
	,	PRIMARY KEY (AccountID, DeviceID)
	,	INDEX IX_Association_CTSCustID_DeviceID_AccountID (DeviceID, AccountID)
) ENGINE=InnoDB;

USE CTS_Adhoc;
DROP TABLE IF EXISTS CS152454_DelUnuAccount_Device; 
CREATE TABLE CS152454_DelUnuAccount_Device (
		DeviceID BIGINT(20) UNSIGNED
	,	FirstDeviceCode VARCHAR(32) COLLATE utf8_unicode_ci NOT NULL
	,	UserAgentKey VARCHAR(32) COLLATE utf8_unicode_ci DEFAULT NULL
	,	FirstTransID BIGINT(20) DEFAULT NULL
	,	CreatedTime TIMESTAMP(4) NOT NULL COMMENT 'CreatedTime of First Transaction'
	,	CreatedDate DATETIME NOT NULL COMMENT 'Date Only, Date of First Transaction'
	,	InsertTime TIMESTAMP(4) NOT NULL COMMENT 'DATETIME, the time that data Insert to Table'
	,	PRIMARY KEY (DeviceID)
) ENGINE=InnoDB;

USE CTS_Adhoc;
DROP TABLE IF EXISTS CS152454_DelUnuAccount_DeviceCode; 
CREATE TABLE CS152454_DelUnuAccount_DeviceCode (
  DeviceCodeID BIGINT(20) UNSIGNED NOT NULL
,	DeviceCode VARCHAR(32) COLLATE utf8_unicode_ci NOT NULL COMMENT ' DeviceCode Captured From DI'
,	DeviceID BIGINT(20) UNSIGNED DEFAULT NULL
,	FirstTransID BIGINT(20) DEFAULT NULL
,	CreatedTime TIMESTAMP(4) NOT NULL
,	CreatedDate DATETIME NOT NULL
,	InsertTime TIMESTAMP(4) NOT NULL
,	PRIMARY KEY (DeviceCodeID)
,	INDEX IX_DeviceCode_DeviceID (DeviceID)
) ENGINE=InnoDB;

USE CTS_Adhoc;
DROP TABLE IF EXISTS CS152454_DelUnuAccount_DeviceFingerprint; 
CREATE TABLE CS152454_DelUnuAccount_DeviceFingerprint (
  DeviceFingerprintID BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT
,	DeviceID BIGINT(20) UNSIGNED NOT NULL
,	FingerprintCode VARCHAR(620) COLLATE utf8_unicode_ci NOT NULL
,	FingerprintMoreInfo TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
,	CreatedTime TIMESTAMP(4) NOT NULL
,	CreatedDate DATETIME NOT NULL
,	InsertTime TIMESTAMP(4) NOT NULL
,	PRIMARY KEY (DeviceID,FingerprintCode)
,	KEY KEY_DeviceFingerprintID (DeviceFingerprintID)
) ENGINE=InnoDB AUTO_INCREMENT=119613421 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;


