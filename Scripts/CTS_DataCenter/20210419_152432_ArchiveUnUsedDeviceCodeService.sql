/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	202104012@CaseyHuynh
Task:	 	Init for Archive Un-used Device Code [Redmine ID: #152454]
DBName:		CTS_DataCenter
*/

/*1 SCHEMA AND INIT*/
USE DCS_DataCenter;
UPDATE DCS_DataCenter.SystemSetting AS ss
SET VGroup = 'DCSArcDeviceCode'
	, VName = 'DCSArcDeviceCode_LastDeviceCodeID'
WHERE ID = 8;


SET @LastDate = DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);
SET @MaxDeviceCodeID = (SELECT DeviceCodeID FROM DCS_DataCenter.DeviceCode WHERE CreatedDate = @LastDate LIMIT 1);

INSERT INTO DCS_DataCenter.SystemSetting(ID,VGroup,VName,VValue,UpdatedTime)
VALUES (9,'DCS_ArchiveDeviceCode','DCSArcDeviceCode_LastDate', @LastDate, NOW())
		, (10,'DCS_ArchiveDeviceCode','DCSArcDeviceCode_MaxDeviceCodeID', @MaxDeviceCodeID, NOW());


 SELECT * FROM DCS_DataCenter.SystemSetting