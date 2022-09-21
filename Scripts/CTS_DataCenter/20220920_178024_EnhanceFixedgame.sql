/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	202200830@Casey.Huynh
Task:	 	Enhance Fixed Game
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 202200830@Casey.Huynh: Created [Redmine ID: #178024]
Reviewer:
*/

USE CTS_DataCenter;
#======================================================
ALTER TABLE MatchMonitor
ADD COLUMN InsertTime DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3);

ALTER TABLE MatchMonitorDetails
ADD COLUMN InsertTime DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3);

#======================================================
# SELECT ParameterValue FROM SystemParameter WHERE ParameterID = 110; # 0.5
UPDATE SystemParameter
SET ParameterValue = 0.35
WHERE ParameterID = 110;
