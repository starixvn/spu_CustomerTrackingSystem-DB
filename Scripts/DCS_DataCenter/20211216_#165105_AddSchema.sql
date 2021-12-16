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
CREATE TABLE `SumAccountLogin` (
   `AccountID` bigint unsigned NOT NULL,
   `TransDate` date NOT NULL,
   `DeviceDesktop` int,
   `DeviceMobile` int,
   `DeviceOthers` int,
   `TotalLogin` int,
   `LastTransID` bigint unsigned NOT NULL,
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`AccountID`, `TransDate`)
 ) ENGINE=InnoDB
 PARTITION BY RANGE (extract(year_month from `TransDate`))
 (PARTITION pm202112 VALUES LESS THAN (202201) ENGINE = InnoDB,
  PARTITION pm202201 VALUES LESS THAN (202202) ENGINE = InnoDB,
  PARTITION pm202202 VALUES LESS THAN (202203) ENGINE = InnoDB,
  PARTITION pm202203 VALUES LESS THAN (202204) ENGINE = InnoDB,
  PARTITION pm202204 VALUES LESS THAN (202205) ENGINE = InnoDB,
  PARTITION pm202205 VALUES LESS THAN (202206) ENGINE = InnoDB,
  PARTITION pm202206 VALUES LESS THAN (202207) ENGINE = InnoDB,
  PARTITION pm202207 VALUES LESS THAN (202208) ENGINE = InnoDB,
  PARTITION pm202208 VALUES LESS THAN (202209) ENGINE = InnoDB,
  PARTITION pm202209 VALUES LESS THAN (202210) ENGINE = InnoDB,
  PARTITION pm202210 VALUES LESS THAN (202211) ENGINE = InnoDB,
  PARTITION pm202211 VALUES LESS THAN (202212) ENGINE = InnoDB,
  PARTITION pm999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB);

  CREATE TABLE `SumAccountLoginTotal` (
   `AccountID` bigint unsigned NOT NULL,
   `DeviceDesktop` int unsigned,
   `DeviceMobile` int unsigned,
   `DeviceOthers` int unsigned,
   `TotalLogin` int unsigned,
   `LastTransID` bigint unsigned NOT NULL,
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`AccountID`)
 ) ENGINE=InnoDB;

 CREATE TABLE `AccountIP` (
   `AccountID` bigint unsigned NOT NULL,
   `IP` VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
   `LastTransDate` date NOT NULL,
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`AccountID`, `IP`),
   INDEX IX_AccountIP_LastTransDate(LastTransDate)
 ) ENGINE=InnoDB;
 
 CREATE TABLE `AccountDevice` (
   `AccountID` bigint unsigned NOT NULL,
   `DeviceID` bigint unsigned NOT NULL,
   `LastTransDate` date NOT NULL,
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`AccountID`, `DeviceID`),
   INDEX IX_AccountDevice_LastTransDate(LastTransDate)
 ) ENGINE=InnoDB;

 CREATE TABLE `DeviceType` (
   `DeviceTypeID` int unsigned NOT NULL AUTO_INCREMENT,
   `DeviceTypeName` varchar(20) NOT NULL,
   `GroupName` varchar(20) NOT NULL,
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`DeviceTypeID`),
   UNIQUE KEY `UK_DeviceTypeName` (`DeviceTypeName`)
 ) ENGINE=InnoDB;

USE DCS_DataCenter;
ALTER TABLE DCS_DataCenter.UserAgent 
ADD COLUMN DeviceTypeID INT UNSIGNED,
ADD COLUMN Created DATETIME DEFAULT CURRENT_TIMESTAMP ,
ADD COLUMN Modified DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP;

ALTER TABLE DCS_DataCenter.UserAgent 
ADD INDEX IX_UserAgent_DeviceTypeID(DeviceTypeID);

 INSERT INTO DeviceType (DeviceTypeID,DeviceTypeName,GroupName,Created)
 VALUES(1, 'Mobile', 'Mobile', NOW()),
       (2, 'Tablet', 'Mobile', NOW()),
       (3, 'Desktop', 'Desktop', NOW()),
       (4, 'Unknown', 'Others', NOW()),
       (5, 'Spider', 'Others', NOW()),
       (6, 'TvOrConsole', 'Others', NOW());

SELECT * FROM DCS_DataCenter.SystemSetting;
INSERT IGNORE INTO DCS_DataCenter.SystemSetting(ID,VGroup,VName,VValue,UpdatedTime)
VALUES(19,"ArchiveData_Account_RemoveDeviceAndIP", '19 Batch Size Device', 500, NOW())
	, (20,"ArchiveData_Account_RemoveDeviceAndIP", '20 Batch Size IP', 500, NOW());

SET @lv_Now = NOW();
SET @lv_MonthDrop = DATE_SUB(@lv_Now, INTERVAL 4 MONTH);
SET @lv_MonthDropName = EXTRACT(YEAR_MONTH FROM @lv_MonthDrop);
SET @lv_PartitionDropName = concat('pm', @lv_MonthDropName);

SELECT @lv_Now, @lv_MonthDrop, @lv_MonthDropName, @lv_PartitionDropName;
#####################################
SET @lv_DropSt = CONCAT('ALTER TABLE DCS_DataCenter.SumAccountLogin DROP PARTITION ', @lv_PartitionDropName, ';');
PREPARE drop_statement from @lv_DropSt;
EXECUTE drop_statement;
DEALLOCATE PREPARE drop_statement;


USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.SystemEventStatus(EventName,Status,LastExecTime)
VALUES('EV_DCS_DataCenter_ArchiveData_Account_RemoveDeviceAndIP','Stop', NOW());


USE DCS_DataCenter;

delimiter |
CREATE EVENT EV_DCS_DataCenter_ArchiveData_Account_RemoveDeviceAndIP
    ON SCHEDULE
      EVERY 60 SECOND
    DO
      BEGIN
 	IF EXISTS(SELECT 1 FROM CTS_DataCenter.SystemEventStatus WHERE EventName = 'EV_DCS_DataCenter_ArchiveData_Account_RemoveDeviceAndIP' AND Status = 'Stop') THEN
  				UPDATE CTS_DataCenter.SystemEventStatus 
  				SET Status = 'Start' 
  				WHERE EventName = 'EV_DCS_DataCenter_ArchiveData_Account_RemoveDeviceAndIP';
  
  				CAll DCS_DataCenter.CTS_DC_ArchiveData_Account_RemoveDeviceAndIP(); 
  
  				UPDATE CTS_DataCenter.SystemEventStatus 
  				SET Status = 'Stop' 
  				WHERE EventName = 'EV_DCS_DataCenter_ArchiveData_Account_RemoveDeviceAndIP';
  	END IF;
 END |

delimiter ;