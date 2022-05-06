USE `DCS_DataCenter`;
SET @yw = YEARWEEK(NOW());
DROP TABLE IF EXISTS Table_TestArchive_Source;
SET @sql = CONCAT("
CREATE TABLE Table_TestArchive_Source (
   ID bigint unsigned NOT NULL AUTO_INCREMENT,
   Name varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
   CreatedDate datetime NOT NULL,
   PRIMARY KEY (ID,CreatedDate),
   KEY IX_Table_TestArchive_Name (Name)
 ) ENGINE=InnoDB
 /*!50100 PARTITION BY RANGE (yearweek(CreatedDate,0))
 (PARTITION pw", @yw-2," VALUES LESS THAN (",@yw-1,") ENGINE = InnoDB,
  PARTITION pw", @yw-1," VALUES LESS THAN (",@yw,") ENGINE = InnoDB,
  PARTITION pw", @yw," VALUES LESS THAN (",@yw+1,") ENGINE = InnoDB,
  PARTITION pw", @yw+1," VALUES LESS THAN (",@yw+2,") ENGINE = InnoDB,
  PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */");

PREPARE stmt1 FROM @sql;
EXECUTE stmt1;

INSERT INTO Table_TestArchive_Source(Name, CreatedDate)
VALUE (CONCAT("Name_", YEARWEEK(DATE_SUB(NOW(),INTERVAL 14 DAY))), DATE_SUB(NOW(),INTERVAL 14 DAY)),
	  (CONCAT("Name_", YEARWEEK(DATE_SUB(NOW(),INTERVAL 7 DAY))), DATE_SUB(NOW(),INTERVAL 7 DAY)),
      (CONCAT("Name_", YEARWEEK(NOW())), NOW()),
      (CONCAT("Name_", YEARWEEK(DATE_ADD(NOW(),INTERVAL 7 DAY))), DATE_ADD(NOW(),INTERVAL 7 DAY));

select * from Table_TestArchive_Source;

/*************************************************************************************************/

USE `CTS_Archive`;
SET @yw = YEARWEEK(NOW());
DROP TABLE IF EXISTS Table_TestArchive_Des;
SET @sql = CONCAT("
CREATE TABLE Table_TestArchive_Des (
   ID bigint unsigned NOT NULL AUTO_INCREMENT,
   Name varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
   CreatedDate datetime NOT NULL,
   PRIMARY KEY (ID,CreatedDate),
   KEY IX_Table_TestArchive_Name (Name)
 ) ENGINE=InnoDB
 /*!50100 PARTITION BY RANGE (yearweek(CreatedDate,0))
 (PARTITION pw", @yw-6," VALUES LESS THAN (",@yw-5,") ENGINE = InnoDB,
  PARTITION pw", @yw-5," VALUES LESS THAN (",@yw-4,") ENGINE = InnoDB,
  PARTITION pw", @yw-4," VALUES LESS THAN (",@yw-3,") ENGINE = InnoDB,
  PARTITION pw", @yw-3," VALUES LESS THAN (",@yw-2,") ENGINE = InnoDB,
  PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */");

PREPARE stmt1 FROM @sql;
EXECUTE stmt1;

INSERT INTO Table_TestArchive_Des(Name, CreatedDate)
VALUE (CONCAT("Name_", YEARWEEK(DATE_SUB(NOW(),INTERVAL 42 DAY))), DATE_SUB(NOW(),INTERVAL 42 DAY)),
	  (CONCAT("Name_", YEARWEEK(DATE_SUB(NOW(),INTERVAL 35 DAY))), DATE_SUB(NOW(),INTERVAL 35 DAY)),
      (CONCAT("Name_", YEARWEEK(DATE_SUB(NOW(),INTERVAL 28 DAY))), DATE_SUB(NOW(),INTERVAL 28 DAY)),
      (CONCAT("Name_", YEARWEEK(DATE_SUB(NOW(),INTERVAL 21 DAY))), DATE_SUB(NOW(),INTERVAL 21 DAY));
  
  select * from  CTS_Archive.Table_TestArchive_Des ;
  
UPDATE `MonDB`.`MysqlServer` SET `DBATaskStatus` = 'None' WHERE (`ID` = '7');
UPDATE `MonDB`.`MysqlServer` SET `DBATaskStatus` = 'None' WHERE (`ID` = '8');
UPDATE `MonDB`.`ArchivePartitionJob` SET `LastExecuted` = '2022-04-22 00:00:00' WHERE (`ID` = '1');