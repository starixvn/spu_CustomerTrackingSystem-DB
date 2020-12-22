/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20201218@Aries.Nguyen
	Task: Remove table unuse. Add primary key for tables [Redmine ID: #147425] 
	DB: MonDB, DCS_DataCenter
*/
USE MonDB;
CREATE TABLE MonDB.dba_track_blocking_issue LIKE DCS_DataCenter.dba_track_blocking_issue;


USE DCS_DataCenter;
DROP EVENT IF EXISTS DCS_DataCenter.dba_blocking_issue;