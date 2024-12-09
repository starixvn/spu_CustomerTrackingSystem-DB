/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20241127@Lando.Vu [Redmine ID: #213401]
	Task: Integrate Mobile/App-Android
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

DROP TABLE IF EXISTS MBRawTransaction;
CREATE TABLE MBRawTransaction (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    LoginName VARCHAR(100) NOT NULL,
    SubscriberName VARCHAR(50) NOT NULL,
    TransTime DATETIME(4) NOT NULL,
    IP VARCHAR(50),
    IPID DECIMAL(50,0),
    Action VARCHAR(100),
    ActionResult VARCHAR(100),
    Flagged SMALLINT,
    MBDeviceCodeMediaDRM VARCHAR(32),
    MBDeviceCodeMachine VARCHAR(32),
    MBDeviceCodeTagging VARCHAR(32),
    IsEmulator TINYINT,
    ModelName VARCHAR(32),
    Manufacturer VARCHAR(32),
    Brand VARCHAR(32),
    SDKVersion VARCHAR(32),
    OSName VARCHAR(32),
    CountryName VARCHAR(32),
    Timezone VARCHAR(32),
    Language VARCHAR(32),
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX IX_MBRawTransaction_SubscriberName (SubscriberName)
);

DROP TABLE IF EXISTS MBAccount;
CREATE TABLE MBAccount (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    SubscriberID INT NOT NULL,
    LoginName VARCHAR(100) NOT NULL,
    LastLoginTime DATETIME(4) NOT NULL,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY UX_MBAccount_SubscriberID_LoginName (SubscriberID, LoginName)
);

DROP TABLE IF EXISTS MBDeviceCodeMediaDRM;
CREATE TABLE MBDeviceCodeMediaDRM (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    Code VARCHAR(32) NOT NULL,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastAccessedDate DATE NOT NULL,
    UNIQUE KEY UX_MBDeviceCodeMediaDRM_Code (Code)
);

DROP TABLE IF EXISTS MBDeviceCodeMachine;
CREATE TABLE MBDeviceCodeMachine (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    Code VARCHAR(32) NOT NULL,
    MachineOSType SMALLINT NOT NULL,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastAccessedDate DATE NOT NULL,
    UNIQUE KEY UX_MBDeviceCodeMachine_Code (Code),
    KEY IX_MBDeviceCodeMachine_MachineOSType (MachineOSType)
);

DROP TABLE IF EXISTS MBDeviceCodeTagging;
CREATE TABLE MBDeviceCodeTagging (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    Code VARCHAR(32) NOT NULL,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastAccessedDate DATE NOT NULL,
    UNIQUE KEY UX_MBDeviceCodeTagging_Code (Code)
);

DROP TABLE IF EXISTS MBDeviceModel;
CREATE TABLE MBDeviceModel (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ModelName VARCHAR(32) NOT NULL,
    Manufacturer VARCHAR(32) NOT NULL,
    Brand VARCHAR(32) NOT NULL,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastAccessedDate DATE NOT NULL,
    UNIQUE KEY UX_MBModelDevice_ModelName_Manufacturer_Brand (ModelName, Manufacturer, Brand)
);

DROP TABLE IF EXISTS MBOS;
CREATE TABLE MBOS (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    OSName VARCHAR(32) NOT NULL,
    Version VARCHAR(32) NOT NULL,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastAccessedDate DATE NOT NULL,
    UNIQUE KEY UX_MBOS_OSName_Version (OSName, Version)
);

DROP TABLE IF EXISTS MBUserSetting;
CREATE TABLE MBUserSetting (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    CountryName VARCHAR(32) NOT NULL,
    TimeZone VARCHAR(32) NOT NULL,
    LanguageName VARCHAR(32) NOT NULL,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastAccessedDate DATE NOT NULL,
    UNIQUE KEY UX_MBUserSetting_CountryName_TimeZone_LanguageName (CountryName, TimeZone, LanguageName)
);

DROP TABLE IF EXISTS MBTransaction;
CREATE TABLE MBTransaction (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    MBRawTransactionID BIGINT UNSIGNED NOT NULL,
    TransTime DATETIME(4) NOT NULL,
    LoginName VARCHAR(100) NOT NULL,
    SubscriberID INT,
    MBAccountID BIGINT UNSIGNED,
    IP VARCHAR(50),
    IPID DECIMAL(50,0),
    ActionResultID INT,
    Flagged SMALLINT,
    MBDeviceCodeMediaDRMID BIGINT UNSIGNED,
    MBDeviceCodeMachineID BIGINT UNSIGNED,
    MBDeviceCodeTaggingID BIGINT UNSIGNED,
    MBDeviceModelID BIGINT UNSIGNED,
    MBOSID BIGINT UNSIGNED,
    MBUserSettingID BIGINT UNSIGNED,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY UX_MBTransaction_MBRawTransactionID (MBRawTransactionID)
);

DROP TABLE IF EXISTS MBProcessedTransaction;
CREATE TABLE MBProcessedTransaction (
    ID BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    CreatedDate DATETIME NOT NULL,
    LoginName VARCHAR(100) NOT NULL,
    SubscriberName VARCHAR(50) NOT NULL,
    TransTime DATETIME(4) NOT NULL,
    IP VARCHAR(50),
    IPID DECIMAL(50,0),
    Action VARCHAR(100),
    ActionResult VARCHAR(100),
    Flagged SMALLINT,
    MBDeviceCodeMediaDRM VARCHAR(32),
    MBDeviceCodeMachine VARCHAR(32),
    MBDeviceCodeTagging VARCHAR(32),
    IsEmulator TINYINT,
    ModelName VARCHAR(32),
    Manufacturer VARCHAR(32),
    Brand VARCHAR(32),
    SDKVersion VARCHAR(32),
    OSName VARCHAR(32),
    Timezone VARCHAR(32),
    Language VARCHAR(32),
    Country VARCHAR(32),
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY IX_MBProcessedTransaction_CreatedDate_SubscriberName (CreatedDate, SubscriberName),
    KEY IX_MBProcessedTransaction_SubscriberName_LoginName (SubscriberName, LoginName)
);

DROP TABLE IF EXISTS MBTransaction07;
CREATE TABLE MBTransaction07 (
    ID BIGINT UNSIGNED NOT NULL,
    CreatedDate DATETIME NOT NULL,
    MBRawTransactionID BIGINT UNSIGNED NOT NULL,
    TransTime DATETIME(4) NOT NULL,
    SubscriberID INT,
    MBAccountID BIGINT UNSIGNED,
    IP VARCHAR(50),
    IPID DECIMAL(50, 0),
    ActionResultID INT,
    Flagged SMALLINT,
    MBDeviceModelID BIGINT UNSIGNED,
    MBOSID BIGINT UNSIGNED,
    MBUserSettingID BIGINT UNSIGNED,
    MBDeviceMappingID BIGINT UNSIGNED,
    MBDeviceID BIGINT UNSIGNED,
    DeviceStatus TINYINT,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID, CreatedDate),
    UNIQUE KEY UX_MBTransaction07_MBRawTransactionID (MBRawTransactionID),
    KEY IX_MBTransaction07_CreatedDate_SubscriberID (CreatedDate, SubscriberID, MBAccountID),
    KEY IX_MBTransaction07_MBDeviceMappingID (MBDeviceMappingID)
);

DROP TABLE IF EXISTS MBDeviceMapping;
CREATE TABLE MBDeviceMapping (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    MBDeviceCodeMediaDRMID BIGINT UNSIGNED,
    MBDeviceCodeMachineID BIGINT UNSIGNED,
    MBDeviceCodeTaggingID BIGINT UNSIGNED,
    MBDeviceID BIGINT UNSIGNED NOT NULL,
    FirstMBRawTransactionID BIGINT UNSIGNED NOT NULL,
    RecoverType SMALLINT NOT NULL,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY UX_MBDeviceMapping_Group (MBDeviceCodeMediaDRMID, MBDeviceCodeMachineID, MBDeviceCodeTaggingID),
	KEY IX_MBDeviceMapping_MBDeviceCodeMediaDRMID (MBDeviceCodeMediaDRMID),
	KEY IX_MBDeviceMapping_MBDeviceCodeMachineID (MBDeviceCodeMachineID),
    KEY IX_MBDeviceMapping_MBDeviceCodeTaggingID (MBDeviceCodeTaggingID)
);

DROP TABLE IF EXISTS MBDevice;
CREATE TABLE MBDevice (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    FirstMBRawTransactionID BIGINT UNSIGNED NOT NULL,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LastAccessedDate DATE NOT NULL,
    UNIQUE KEY UX_MBDevice_FirstMBRawTransactionID (FirstMBRawTransactionID)
);

DROP TABLE IF EXISTS MBAssociation;
CREATE TABLE MBAssociation (
    ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    MBAccountID BIGINT UNSIGNED NOT NULL,
    MBDeviceID BIGINT UNSIGNED NOT NULL,
    SubscriberID BIGINT UNSIGNED NOT NULL,
    InsertedTime DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY UX_MBAssociation_MBAccountID_MBDeviceID (MBAccountID, MBDeviceID),
    KEY IX_MBAssociation_MBDeviceID_MBAccountID (MBDeviceID, MBAccountID)
);
