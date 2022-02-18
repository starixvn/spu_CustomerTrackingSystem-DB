USE MonDB;
CREATE TABLE `MonitorReport_MessageGroup` (
   MessageGroupID 		INT UNSIGNED NOT NULL,
   MessageGroupName		VARCHAR(50),
   `Description`  		VARCHAR(200),
   `Enable`  			BIT DEFAULT 1,
   Created 				DATETIME DEFAULT CURRENT_TIMESTAMP,
   Modified		 		DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY(MessageGroupID)
) ENGINE=InnoDB;
 
INSERT INTO MonitorReport_MessageGroup(MessageGroupID,MessageGroupName)
VALUES(1,'<b>Configuration Changed</b>'),
	  (2,'<b>Event Status</b>'),
      (3,'<b>Slow query</b>'),
      (4,'<b>Store Procedure Error</b>'),
      (5,'<b>Store Procedure Execution Count</b>'),
      (6,'<b>Store Procedure Row Affected</b>'),
      (7,'<b>Data growth</b>'),
      (8,'<b>Resource Usage</b>'),
      (9,'<b>Fragmented Table</b>'),
      (10,'<b>Replication Delay</b>');


CREATE TABLE `MonitorReport_MessageMetric` (
   MessageGroupID 		INT UNSIGNED NOT NULL,
   MessageMetricID  	INT UNSIGNED NOT NULL,
   MessageMetricName	VARCHAR(50),
   MessageMetricScript	VARCHAR(200),
   `Description`  		VARCHAR(200),
   `Enable`				BIT DEFAULT 1,
   `ServerName`			VARCHAR(50),
   `ScriptType`			VARCHAR(50),
   Created 				DATETIME DEFAULT CURRENT_TIMESTAMP,
   Modified		 		DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY(MessageGroupID,MessageMetricID)
 ) ENGINE=InnoDB;
 
 INSERT IGNORE INTO MonitorReport_MessageMetric(MessageGroupID,MessageMetricID,MessageMetricName,MessageMetricScript,`ServerName`,`ScriptType`)
 VALUES (1,1,'Get list config changed','MonDB.DBA_Monitor_ConfigChanged_Get();','Master','SQL'),
		(1,2,'Get list config changed','MonDB.DBA_Monitor_ConfigChanged_Get();','Replica','SQL'),
		(2,1,'Archive Customer Event','MonDB.DBA_Monitor_ArchiveCustomer_Status();','Master','SQL'),
        (2,2,'Account Transform Status','MonDB.DBA_Monitor_AccountTransform_Status();','Master','SQL'),
        (2,3,'Update Last Login Time','MonDB.DBA_Monitor_UpdateLastLoginTime_Status();','Master','SQL'),
        (2,4,'Archive Device Code','MonDB.DBA_Monitor_ArchiveDeviceCode_Status();','Master','SQL'),
        (2,5,'Archive Device','MonDB.DBA_Monitor_ArchiveDeviceByAccountInactive_Status();','Master','SQL'),
        (2,6,'Backup','MonDB.DBA_Monitor_BackupFull_Status();','Master','SQL'),
        (2,7,'Archive Transaction','MonDB.DBA_Monitor_ArchiveTransaction_Status();','Archive','SQL'),
        (3,1,'Slow Query','MonDB.DBA_Monitor_SlowQuery_Metric();','Master','SQL'),
        (4,1,'Store Procedure Error','MonDB.DBA_Monitor_ErrorQuery_Metric();','Master','SQL'),
        (6,1,'Store Procedure Row Affected','MonDB.DBA_Monitor_RowAffectedSP_Metric();','Master','SQL'),
        (7,1,'Data growth','MonDB.DBA_Monitor_DataGrowth_Metric();','Replica','SQL'),
        (8,1,'Master ','bash /var/cts/monitor_metric/resouce_usage.sh','Master','Bash'),
        (8,2,'Master ','bash /var/cts/monitor_metric/resouce_usage.sh','Replica','Bash');

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



/*
DBA_Monitor_ArchiveTransaction_Status

*/

CREATE ROLE 'CTSMonitor';
GRANT ALL PRIVILEGES ON `MonDB`.* TO `CTSMonitor`@`%`;
GRANT EVENT ON  *.* TO `CTSMonitor`@`%`;
GRANT PROCESS ON *.* TO `CTSMonitor`@`%`;
GRANT FLUSH_STATUS ON *.* TO `CTSMonitor`@`%`;
GRANT SELECT ON `sys`.* TO `CTSMonitor`@`%`;
GRANT SELECT ON `performance_schema`.* TO `CTSMonitor`@`%`;
GRANT SELECT ON `mysql`.`slow_log` TO `CTSMonitor`@`%`;

CREATE USER 'ctsMonitor'@'%' IDENTIFIED WITH mysql_native_password BY 'ctsMonitor@spu2022#';
GRANT `CTSMonitor` TO `ctsMonitor`@`%`;
FLUSH PRIVILEGES;