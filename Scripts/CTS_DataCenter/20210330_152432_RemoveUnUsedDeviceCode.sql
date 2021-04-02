/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	202104012@CaseyHuynh
Task:	 	Init for Archive Un-used Device Code [Redmine ID: #152454]
DBName:		CTS_DataCenter
*/

/*1 SCHEMA AND INIT*/
USE DCS_DataCenter;
CREATE TABLE zzArchiveDeviceCode (
  DeviceCodeID 	BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
  ,	DeviceCode 	VARCHAR(32) COLLATE utf8_unicode_ci NOT NULL COMMENT ' DeviceCode Captured From DI'
  ,	DeviceID 		BIGINT UNSIGNED DEFAULT NULL
  ,	FirstTransID 	BIGINT DEFAULT NULL
  ,	CreatedTime 	TIMESTAMP(4) NOT NULL
  ,	CreatedDate 	DATETIME NOT NULL
  ,	InsertTime  	DATETIME NOT NULL
  ,	PRIMARY KEY (DeviceCodeID)
  ,	INDEX IX_DeviceCode_DeviceID (DeviceID)
) ENGINE=InnoDB;

USE DCS_DataCenter;
INSERT INTO DCS_DataCenter.SystemSetting(ID,VGroup,VName,VValue,UpdatedTime)
VALUES(8,'DCS_Arvhive','DCSArc_DeviceCode_LastDeviceCodeID',0,NOW());

/*2. EXECUTE*/
USE DCS_DataCenter;
CALL DCS_DC_ArchiveData_DeviceCode(1000);