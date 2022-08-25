DROP TABLE IF EXISTS BackupJob;
CREATE TABLE BackupJob (
   ID int unsigned NOT NULL AUTO_INCREMENT,
   ServerID int unsigned DEFAULT NULL,
   
   Type ENUM ('Full','Incremental'),
   
   FullSchedule TIME,
   IncInterval INT,
   
   Folder VARCHAR(200),
   DesServerID int unsigned,
   DesFolder VARCHAR(200),
   
   LastType VARCHAR(20),
   LastLSN BIGINT unsigned,
   LastFolder VARCHAR(200),
   LastTime TIME,
   LastDate DATE,
   
   
   
   NotificationChannelID int unsigned DEFAULT NULL,
   IsActive bit DEFAULT 1,
   Created datetime DEFAULT CURRENT_TIMESTAMP,
   Modified datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (ID)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;s

ALTER TABLE MysqlServer
ADD  COLUMN ContainerNetwork VARCHAR(200) AFTER ContainerName;

ALTER TABLE MysqlServer
ADD  COLUMN XtrabackupImageName VARCHAR(200) AFTER ContainerNetwork;



#sudo adduser dba_cts_master docker

#sudo chown dba_cts_master:dba_cts_master /tmp/bk


#sudo chown -R dba_cts_replicadba_cts_replica /tmp/bk