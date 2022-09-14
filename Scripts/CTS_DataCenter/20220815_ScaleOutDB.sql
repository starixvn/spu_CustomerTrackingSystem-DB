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
ADD COLUMN SequenceID BIGINT UNSIGNED;

UPDATE MatchMonitorStagingLive
SET SequenceID = TransID;

ALTER TABLE MatchMonitorStagingLive
DROP PRIMARY KEY
, ADD PRIMARY KEY PK_MatchMonitorStagingLive_SequenceID(SequenceID)
, MODIFY COLUMN TransID BIGINT UNSIGNED
, ADD INDEX IX_MatchMonitorStagingLive_TransID(TransID);

#=============MatchMonitorStagingNonLive 
ALTER TABLE MatchMonitorStagingNonLive
ADD COLUMN SequenceID BIGINT UNSIGNED;

UPDATE MatchMonitorStagingNonLive
SET SequenceID = TransID;

ALTER TABLE MatchMonitorStagingNonLive
DROP PRIMARY KEY
, ADD PRIMARY KEY PK_MatchMonitorStagingNonLive_SequenceID(SequenceID)
, MODIFY COLUMN TransID BIGINT UNSIGNED
, ADD INDEX IX_MatchMonitorStagingNonLive_TransID(TransID);

#=============MatchMonitorTransLive 
ALTER TABLE MatchMonitorTransLive
ADD COLUMN SequenceID BIGINT UNSIGNED;

UPDATE MatchMonitorTransLive
SET SequenceID = TransID;


ALTER TABLE MatchMonitorTransLive
DROP PRIMARY KEY
, ADD PRIMARY KEY PK_MatchMonitorTransLive_SequenceID(SequenceID)
, ADD INDEX IX_MatchMonitorTransLive_TransID(TransID);

#=============MatchMonitorTransNonLive 
ALTER TABLE MatchMonitorTransNonLive
ADD COLUMN SequenceID BIGINT UNSIGNED;

UPDATE MatchMonitorTransNonLive
SET SequenceID = TransID;

ALTER TABLE MatchMonitorTransNonLive
DROP PRIMARY KEY
, ADD PRIMARY KEY PK_MatchMonitorTransNonLive_SequenceID(SequenceID)
, ADD INDEX IX_MatchMonitorTransNonLive_TransID(TransID);

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







