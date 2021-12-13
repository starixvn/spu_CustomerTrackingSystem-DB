/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20211126@Aries.Nguyen 
	Task:	 	Tuning archive device code [Redmine ID: #165165]
	Server:  	Master
	DBName:		DCS_DataCenter

	Revisions: 
			- 20211126@Aries.Nguyen: Created [Redmine ID: #165165]
	Reviewer:
*/
USE DCS_DataCenter;
ALTER TABLE DCS_DataCenter.Account ADD INDEX IXF_Account_LastLoginTime((DATE(LastLoginTime)));

SELECT DATE(LastLoginTime)
INTO @date_scan
FROM DCS_DataCenter.Account
ORDER BY DATE(LastLoginTime) ASC
LIMIT 1;
 
INSERT IGNORE INTO DCS_DataCenter.SystemSetting(ID,VGroup,VName,VValue,UpdatedTime)
VALUES(14,"ArchiveDeviceByAccountLastLoginTime", 'Date Scan', @date_scan, NOW())
	, (15,"ArchiveDeviceByAccountLastLoginTime", 'Last AccountID', 0, NOW())
    , (16,"ArchiveDeviceByAccountLastLoginTime", 'Table Deleting', 'DCS_DataCenter.DeviceFingerprint', NOW())
	, (17,"ArchiveDeviceByAccountLastLoginTime", 'Archive Device Batch Size Account', 100, NOW())
    , (18,"ArchiveDeviceByAccountLastLoginTime", 'Archive Device Batch Size Delete', 500, NOW());


CREATE TABLE `ArchiveAccountInactive_Device` (
   `DeviceID` bigint unsigned NOT NULL  PRIMARY KEY 
 ) ENGINE=InnoDB;

USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.SystemEventStatus(EventName,Status,LastExecTime)
VALUES('EV_DCS_DataCenter_ArchiveAccountInactive_Device','Stop', NOW());


USE DCS_DataCenter;

delimiter |
CREATE EVENT EV_DCS_DataCenter_ArchiveAccountInactive_Device
    ON SCHEDULE
      EVERY 60 SECOND
    DO
      BEGIN
 	IF EXISTS(SELECT 1 FROM CTS_DataCenter.SystemEventStatus WHERE EventName = 'EV_DCS_DataCenter_ArchiveAccountInactive_Device' AND Status = 'Stop') THEN
  				UPDATE CTS_DataCenter.SystemEventStatus 
  				SET Status = 'Start' 
  				WHERE EventName = 'EV_DCS_DataCenter_ArchiveAccountInactive_Device';
  
  				CAll DCS_DataCenter.CTS_DC_ArchiveData_AccountInactive_Device(); 
  
  				UPDATE CTS_DataCenter.SystemEventStatus 
  				SET Status = 'Stop' 
  				WHERE EventName = 'EV_DCS_DataCenter_ArchiveAccountInactive_Device';
  	END IF;
 END |

delimiter ;