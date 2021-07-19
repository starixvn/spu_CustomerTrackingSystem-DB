/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210716@Casey.Huynh
Task:	 	Fix Issue Rule Trans.StepTime and AssGroup [Redmine ID: 158946]
Server:  	Master
DBName:		CTS_DataCenter

*/

USE CTS_DataCenter;
TRUNCATE TABLE CTS_DataCenter.MatchMonitor;
TRUNCATE TABLE CTS_DataCenter.MatchMonitorDetails;
TRUNCATE TABLE CTS_DataCenter.MatchMonitorStaging;

UPDATE SystemParameter
SET ParameterValue = 0
WHERE ParameterID = 20;

#=======MatchMonitor============
ALTER TABLE CTS_DataCenter.MatchMonitor
ADD COLUMN LastModifiedTime DATETIME(3); 

#======MatchMonitorDetails=============
ALTER TABLE CTS_DataCenter.MatchMonitorDetails
ADD COLUMN LastModifiedTime DATETIME(3); 

#=====MatchMonitorStaging==============
ALTER TABLE CTS_DataCenter.MatchMonitorStaging
DROP INDEX IX_MatchMonitorStaging_OriginGroupIDMatchInfo;

ALTER TABLE CTS_DataCenter.MatchMonitorStaging
ADD INDEX IX_MatchMonitorStaging_OriginGroupIDMatchInfo(OriginGroupID);

ALTER TABLE CTS_DataCenter.MatchMonitorStaging
ADD INDEX IX_MatchMonitorDetailsStaging_MatchInfoGroup(MatchID,LiveIndicator,TotalScore,BettypeID); 
