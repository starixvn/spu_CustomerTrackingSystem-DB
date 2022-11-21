/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator:	20221121@Aries.Nguyen
    Task:	 	Match Monitor Irrigation
    Server:  	Master
    DBName:		CTS_DataCenter

    Revisions: 
		    - 20221121@Aries.Nguyen: Archive Partition [Redmine ID: #179499]
    Reviewer:
*/
/************************ Alter schema MatchMonitor  ****************************/
ALTER TABLE MatchMonitor 
DROP PRIMARY KEY,
ADD PRIMARY KEY(ID,InsertTime),
DROP INDEX UK_MatchMonitor_MatchGroup,
ADD UNIQUE UK_MatchMonitor_MatchGroup(EventDate,BettypeID,BetID,MatchID,LiveIndicator,Reason,InsertTime);

SELECT MIN(InsertTime)
INTO @min_InsertTime
FROM MatchMonitor;

SET @from_week = YEARWEEK(@min_InsertTime);
SET @to_week = YEARWEEK(NOW());
WITH RECURSIVE CTE (pw) AS
(
  SELECT @from_week
  UNION ALL
  SELECT pw + 1 FROM CTE WHERE pw < @to_week + 2
)
SELECT CONCAT("ALTER TABLE MatchMonitor \n PARTITION BY RANGE(yearweek(`InsertTime`,0)) \n (" 
		,GROUP_CONCAT(CONCAT("PARTITION pw", pw," VALUES LESS THAN (",pw+1,") ENGINE = InnoDB,") SEPARATOR  '\n')
        ,"\n PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) ;") AS script 
FROM CTE;


/************************ Alter schema MatchMonitorDetails  ****************************/

ALTER TABLE MatchMonitorDetails 
DROP PRIMARY KEY,
ADD PRIMARY KEY(ID,InsertTime),
DROP INDEX UK_MatchMonitorDetails_MatchRuleGroup,
ADD UNIQUE UK_MatchMonitorDetails_MatchRuleGroup(MatchID,LiveIndicator,TotalScore,BettypeID,BetID,Betteam,GroupID,InsertTime);

SELECT MIN(InsertTime)
INTO @min_InsertTime
FROM MatchMonitorDetails;

SET @from_week = YEARWEEK(@min_InsertTime);
SET @to_week = YEARWEEK(NOW());
WITH RECURSIVE CTE (pw) AS
(
  SELECT @from_week
  UNION ALL
  SELECT pw + 1 FROM CTE WHERE pw < @to_week + 2
)
SELECT CONCAT("ALTER TABLE MatchMonitorDetails \n PARTITION BY RANGE(yearweek(`InsertTime`,0)) \n (" 
		,GROUP_CONCAT(CONCAT("PARTITION pw", pw," VALUES LESS THAN (",pw+1,") ENGINE = InnoDB,") SEPARATOR  '\n')
        ,"\n PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) ;") AS script 
FROM CTE;


/************************ Alter schema MatchMonitorDetailsVerifiedTrans  ****************************/
ALTER TABLE MatchMonitorDetailsVerifiedTrans 
ADD COLUMN  InsertTime DATETIME DEFAULT CURRENT_TIMESTAMP,
DROP PRIMARY KEY,
ADD PRIMARY KEY(ID,InsertTime);

SELECT MIN(InsertTime)
INTO @min_InsertTime
FROM MatchMonitorDetailsVerifiedTrans;

SET @from_week = YEARWEEK(@min_InsertTime);
SET @to_week = YEARWEEK(NOW());
WITH RECURSIVE CTE (pw) AS
(
  SELECT @from_week
  UNION ALL
  SELECT pw + 1 FROM CTE WHERE pw < @to_week + 2
)
SELECT CONCAT("ALTER TABLE MatchMonitorDetailsVerifiedTrans \n PARTITION BY RANGE(yearweek(`InsertTime`,0)) \n (" 
		,GROUP_CONCAT(CONCAT("PARTITION pw", pw," VALUES LESS THAN (",pw+1,") ENGINE = InnoDB,") SEPARATOR  '\n')
        ,"\n PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) ;") AS script 
FROM CTE;

/************************Mysql Shell: Dump Data MatchMonitor,MatchMonitorDetails To Archive server   ****************************/

/*  
master159 = mysql.get_classic_session('user@ip', 'xxxx');
shell.set_session(master159);

util.dumpTables("CTS_DataCenter", [ "MatchMonitor", "MatchMonitorDetails" ], "C:/Users/aries.nguyen/Desktop/dump_table")

archive72 = mysql.get_classic_session('aries.vn@10.18.200.72:3307', 'password');
shell.set_session(archive72);


\sql Set global local_infile=ON;
util.load_dump("C:/Users/aries.nguyen/Desktop/dump_table",{"schema":"CTS_Archive"})
\sql Set global local_infile=OFF;
*/

/************************Add schema   MatchMonitorDetailsVerifiedTrans ****************************/
SHOW CREATE TABLE MatchMonitorDetailsVerifiedTrans;
#Only  "PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB"

/************************Rename table ****************************/
USE CTS_Archive;
RENAME TABLE MatchMonitor TO MatchMonitor_Archive;
RENAME TABLE MatchMonitorDetails TO MatchMonitorDetails_Archive;
RENAME TABLE MatchMonitorDetailsVerifiedTrans TO MatchMonitorDetailsVerifiedTrans_Archive;

/************************Check Data ****************************/


/************************Drop Partition MatchMonitor Unused****************************/
##MatchMonitor Master 159
SELECT CONCAT("ALTER TABLE MatchMonitor DROP PARTITION ", GROUP_CONCAT(PARTITION_NAME),";") AS script 
FROM information_schema.partitions
WHERE TABLE_CATALOG = 'def'
	AND TABLE_SCHEMA = 'CTS_DataCenter'
    AND TABLE_NAME = 'MatchMonitor'
    AND PARTITION_DESCRIPTION <= YEARWEEK(NOW()) - 5
    AND PARTITION_DESCRIPTION != 'MAXVALUE';


## MatchMonitor Archive 59
SELECT CONCAT("ALTER TABLE MatchMonitor_Archive DROP PARTITION ", GROUP_CONCAT(PARTITION_NAME),";") AS script 
FROM information_schema.partitions
WHERE TABLE_CATALOG = 'def'
	AND TABLE_SCHEMA = 'CTS_DataCenter'
    AND TABLE_NAME = 'MatchMonitor'
    AND PARTITION_DESCRIPTION > YEARWEEK(NOW()) - 5
    AND PARTITION_DESCRIPTION != 'MAXVALUE';



##MatchMonitorDetails Master 159
SELECT CONCAT("ALTER TABLE MatchMonitorDetails DROP PARTITION ", GROUP_CONCAT(PARTITION_NAME),";") AS script 
FROM information_schema.partitions
WHERE TABLE_CATALOG = 'def'
	AND TABLE_SCHEMA = 'CTS_DataCenter'
    AND TABLE_NAME = 'MatchMonitorDetails'
    AND PARTITION_DESCRIPTION <= YEARWEEK(NOW()) - 5
    AND PARTITION_DESCRIPTION != 'MAXVALUE';
	
## MatchMonitorDetails Archive 59	
SELECT CONCAT("ALTER TABLE MatchMonitorDetails_Archive DROP PARTITION ", GROUP_CONCAT(PARTITION_NAME),";") AS script 
FROM information_schema.partitions
WHERE TABLE_CATALOG = 'def'
	AND TABLE_SCHEMA = 'CTS_DataCenter'
    AND TABLE_NAME = 'MatchMonitorDetails'
    AND PARTITION_DESCRIPTION > YEARWEEK(NOW()) - 5
    AND PARTITION_DESCRIPTION != 'MAXVALUE';	
	
/************************ Add config ****************************/	
	
INSERT INTO `MonDB`.`ArchivePartitionJob` (`SourceServerID`, `SourceMasterServerID`, `SourceDatabase`, `SourceTable`, `DesServerID`, `DesDatabase`, `DesTable`, `PartitionType`, `PartitionPrefix`, `PartitionDelimiter`, `PartitionMax`, `KeepDataRange`, `DateExecute`, `TimeExecute`, `HasDropPartitionSourceTable`, `NotificationChannelID`, `HasAlert_Pre`, `IsAlerted_Pre`, `HasAlert_Done`, `RunType`) 
VALUES ('5', '9', 'CTS_DataCenter', 'MatchMonitor', '7', 'CTS_Archive', 'MatchMonitor_Archive', 'Weekly', 'pw', '#p#', 'pw999999', '30', '2', '08:00:00', '1', '3', '1', '1', '1', 'Job'),
	   ('5', '9', 'CTS_DataCenter', 'MatchMonitorDetails', '7', 'CTS_Archive', 'MatchMonitorDetails_Archive', 'Weekly', 'pw', '#p#', 'pw999999', '30', '2', '08:00:00', '1', '3', '1', '1', '1', 'Job'),
       ('5', '9', 'CTS_DataCenter', 'MatchMonitorDetailsVerifiedTrans', '7', 'CTS_Archive', 'MatchMonitorDetailsVerifiedTrans_Archive', 'Weekly', 'pw', '#p#', 'pw999999', '30', '2', '08:00:00', '1', '3', '1', '1', '1', 'Job');
