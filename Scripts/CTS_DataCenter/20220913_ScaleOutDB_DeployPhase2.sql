/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20220913@Casey.Huynh
Task:	 	Scale Out DB
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20220913@Casey.Huynh: Created [Redmine ID: #176472]
Reviewer:
*/

USE CTS_DataCenter;

Step 1. Stop service MM 
Step 2. Deploy SERVICE/WEB/SP
Step 3. Update SequenceID By TransIDs for tables (MatchMonitorStagingLive, MatchMonitorStagingNonLive, MatchMonitorTransLive, MatchMonitorTransNonLive)

SELECT TransID FROM MatchMonitorStagingLive
UNION
SELECT TransID FROM MatchMonitorStagingNonLive
UNION
SELECT TransID FROM MatchMonitorTransLive
UNION
SELECT TransID FROM MatchMonitorTransNonLive;

Step 4. UPDATE SCHEMA 
	ALTER TABLE MatchMonitorStagingLive
	DROP PRIMARY KEY
	, ADD PRIMARY KEY PK_MatchMonitorStagingLive_SequenceID(SequenceID)
	, ADD INDEX IX_MatchMonitorStagingLive_TransID(TransID);
	
	ALTER TABLE MatchMonitorStagingNonLive
	DROP PRIMARY KEY
	, ADD PRIMARY KEY PK_MatchMonitorStagingNonLive_SequenceID(SequenceID)
	, ADD INDEX IX_MatchMonitorStagingNonLive_TransID(TransID);
	
	ALTER TABLE MatchMonitorTransLive
	DROP PRIMARY KEY
	, ADD PRIMARY KEY PK_MatchMonitorTransLive_SequenceID(SequenceID)
	, ADD INDEX IX_MatchMonitorTransLive_TransID(TransID);
	
	ALTER TABLE MatchMonitorTransNonLive
	DROP PRIMARY KEY
	, ADD PRIMARY KEY PK_MatchMonitorTransNonLive_SequenceID(SequenceID)
	, ADD INDEX IX_MatchMonitorTransNonLive_TransID(TransID);

Step 5. UPDATE SystemParameter

	UPDATE SystemParameter
	SET ParameterValue = (SELECT SequenceID FROM MatchMonitorStagingLive WHERE TransID = ParameterValue)
	WHERE ParameterID = 20;
	
	UPDATE SystemParameter
	SET ParameterValue = (SELECT SequenceID FROM MatchMonitorStagingNonLive WHERE TransID = ParameterValue)
	WHERE ParameterID = 29;
	
	UPDATE SystemParameter
	SET ParameterValue = (SELECT SequenceID FROM MatchMonitorStagingLive WHERE TransID = ParameterValue)
	WHERE ParameterID = 47;
	
	UPDATE SystemParameter
	SET ParameterValue = (SELECT SequenceID FROM MatchMonitorStagingNonLive WHERE TransID = ParameterValue)
	WHERE ParameterID = 48;
	
	UPDATE SystemParameter
	SET ParameterValue = (SELECT SequenceID FROM MatchMonitorTransLive WHERE TransID = ParameterValue)
	WHERE ParameterID = 100;
	
	UPDATE SystemParameter
	SET ParameterValue = (SELECT SequenceID FROM MatchMonitorTransNonLive WHERE TransID = ParameterValue)
	WHERE ParameterID = 101;
    
Step 6. START SERVICEs MM;