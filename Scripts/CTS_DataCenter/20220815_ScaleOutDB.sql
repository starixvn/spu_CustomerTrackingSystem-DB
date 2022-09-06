/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	202208150@Casey.Huynh
Task:	 	Scale Out DB
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 202208150@Casey.Huynh: Created [Redmine ID: #176472]
Reviewer:
*/

USE CTS_DataCenter;

#===========STOP Service MM=====================================

#=============MatchMonitorStagingLive 
ALTER TABLE MatchMonitorStagingLive
ADD COLUMN SequenceID BIGINT;

UPDATE MatchMonitorStagingLive
SET SequenceID = TransID;

ALTER TABLE MatchMonitorStagingLive
ADD INDEX IX_MatchMonitorStagingLive_TransID(TransID);

ALTER TABLE MatchMonitorStagingLive
DROP PRIMARY KEY;

ALTER TABLE MatchMonitorStagingLive
ADD PRIMARY KEY PK_MatchMonitorStagingLive_SequenceID(SequenceID);

ALTER TABLE MatchMonitorStagingLive
MODIFY COLUMN TransID BIGINT UNSIGNED;

#=============MatchMonitorStagingNonLive 
ALTER TABLE MatchMonitorStagingNonLive
ADD COLUMN SequenceID BIGINT;

UPDATE MatchMonitorStagingNonLive
SET SequenceID = TransID;

ALTER TABLE MatchMonitorStagingNonLive
ADD INDEX IX_MatchMonitorStagingNonLive_TransID(TransID);

ALTER TABLE MatchMonitorStagingNonLive
DROP PRIMARY KEY;

ALTER TABLE MatchMonitorStagingNonLive
ADD PRIMARY KEY PK_MatchMonitorStagingNonLive_SequenceID(SequenceID);

ALTER TABLE MatchMonitorStagingNonLive
MODIFY COLUMN TransID BIGINT UNSIGNED;

#=============MatchMonitorTransLive 
ALTER TABLE MatchMonitorTransLive
ADD COLUMN SequenceID BIGINT;

UPDATE MatchMonitorTransLive
SET SequenceID = TransID;

ALTER TABLE MatchMonitorTransLive
ADD INDEX IX_MatchMonitorTransLive_TransID(TransID);

ALTER TABLE MatchMonitorTransLive
DROP PRIMARY KEY;

ALTER TABLE MatchMonitorTransLive
ADD PRIMARY KEY PK_MatchMonitorTransLive_SequenceID(SequenceID);

#=============MatchMonitorTransNonLive 
ALTER TABLE MatchMonitorTransNonLive
ADD COLUMN SequenceID BIGINT;

UPDATE MatchMonitorTransNonLive
SET SequenceID = TransID;

ALTER TABLE MatchMonitorTransNonLive
ADD INDEX IX_MatchMonitorTransLive_TransID(TransID);

ALTER TABLE MatchMonitorTransNonLive
DROP PRIMARY KEY;

ALTER TABLE MatchMonitorTransNonLive
ADD PRIMARY KEY PK_MatchMonitorTransLive_SequenceID(SequenceID);
#===================================================================
#****************UPDATE Parameter Value by SequenceID*******************
SELECT * FROM SystemParameter WHERE ParameterID IN (20,29,100,101); #Long Luu: Get SequenceID From Main DB by ParamenterValue

UPDATE SystemParameter
SET ParameterName = 'MatchMonitor_StagingInsert_LiveLastSequenceID'
	, ParameterDesc = 'MatchMonitor_StagingInsert_LiveLastSequenceID'
    , ParameterValue = <SequenceIDForLive>
WHERE ParameterID = 20;

UPDATE SystemParameter
SET ParameterName = 'MatchMonitor_StagingInsert_NonliveLastSequenceID'
	, ParameterDesc = 'MatchMonitor_StagingInsert_NonliveLastSequenceID'
    , ParameterValue = <SequenceIDForNonLive>
WHERE ParameterID = 29;

UPDATE SystemParameter
SET ParameterDesc = 'MatchMonitorTransLive.SequenceID'
WHERE ParameterID = 100
	, ParameterValue = <SequenceIDForNonLive>;

UPDATE SystemParameter
SET ParameterDesc = 'MatchMonitorTransNonLive.SequenceID'
WHERE ParameterID = 101
	, ParameterValue = <SequenceIDForNonLive>;



UPDATE SystemParameter
SET ParameterName = 'MatchMonitor_RuleProcess_LiveLastSequenceID'
	, ParameterDesc = 'MatchMonitor_RuleProcess_LiveLastSequenceID'
WHERE ParameterID = 47;

UPDATE SystemParameter
SET ParameterName = 'MatchMonitor_RuleProcess_NonLiveLastSequenceID'
	, ParameterDesc = 'MatchMonitor_RuleProcess_NonLiveLastSequenceID'
WHERE ParameterID = 48;







