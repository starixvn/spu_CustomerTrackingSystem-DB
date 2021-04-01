/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210322@CaseyHuynh
Task:	 	Init New Association 'IP' [Redmine ID: 131662] 	
DBName:		CTS_DataCenter
*/
SELECT * FROM DCS_DataCenter.SystemSetting;
USE DCS_DataCenter;

INSERT INTO DCS_DataCenter.SystemSetting(ID,VGroup,VName,VValue,UpdatedTime)
VALUES(8,'DCS_Arvhive','DCSArc_DeviceCode_LastDeviceCodeID',0,NOW());

USE DCS_DataCenter;
CREATE TABLE ArchiveDeviceCode (
  DeviceCodeID 	BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
  ,	DeviceCode 	VARCHAR(32) COLLATE utf8_unicode_ci NOT NULL COMMENT ' DeviceCode Captured From DI'
  ,	DeviceID 		BIGINT UNSIGNED DEFAULT NULL
  ,	FirstTransID 	BIGINT DEFAULT NULL
  ,	CreatedTime 	TIMESTAMP(4) NOT NULL
  ,	CreatedDate 	DATETIME NOT NULL
  ,	InsertTime  	DATETIME NOT NULL
  ,	PRIMARY KEY (DeviceCodeID)
  ,	UNIQUE KEY UK_DeviceCode_DeviceID (DeviceCode,DeviceID)
  ,	INDEX IX_DeviceCode_CreatedDate (CreatedDate)
  ,	INDEX IX_DeviceCode_DeviceID (DeviceID)
)ENGINE=InnoDB;

