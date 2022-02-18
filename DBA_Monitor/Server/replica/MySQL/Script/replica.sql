USE MonDB;

CREATE TABLE `MonitorReport_Setting` (
   SettingID  				INT UNSIGNED NOT NULL PRIMARY KEY,
   SettingName				VARCHAR(50),
   SettingValue				VARCHAR(200),
   SettingGroupID  			INT UNSIGNED,
   SettingGroupNameID		VARCHAR(50),
   `Description`  			VARCHAR(200),
   `Enable`					BIT DEFAULT 1,
   Created 					DATETIME DEFAULT CURRENT_TIMESTAMP,
   Modified		 			DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   INDEX 					IX_MonitorReport_Setting_SettingGroupID(SettingGroupID)
 ) ENGINE=InnoDB;
 
 INSERT INTO MonitorReport_Setting(SettingID,SettingName,SettingValue,SettingGroupID,SettingGroupNameID)
 VALUES(1,'IgnoreConfigChanged','transaction_isolation',1,'SettingGroupNameID');
