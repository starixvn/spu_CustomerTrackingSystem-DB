/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210716@Casey.Huynh
Task:	 	Add Insert Date
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		-20210716@Casey.Huynh: Created [Redmine: 158496]
Reviewer:
*/

USE CTS_DataCenter;
TRUNCATE TABLE CTS_DataCenter.MatchMonitor;
TRUNCATE TABLE CTS_DataCenter.MatchMonitorDetails;
TRUNCATE TABLE CTS_DataCenter.MatchMonitorStaging;

UPDATE SystemParameter
SET ParameterValue = 0
WHERE ParameterID = 20;

#===================
ALTER TABLE CTS_DataCenter.MatchMonitor
ADD COLUMN LastModifiedTime DATETIME(3); 

#===================
ALTER TABLE CTS_DataCenter.MatchMonitorDetails
ADD COLUMN LastModifiedTime DATETIME(3); 
