/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 20210820@Long.Luu
Task:	 	Adjust Match Monitor
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
		- 20210820@Long.Luu: Created [#159195]
Reviewer:
*/

#####################CTS_DataCenter.SportGroup
UPDATE CTS_DataCenter.SystemParameter
SET ParameterName = 'MatchMonitor_LastScannedLiveTransID', ParameterDesc = 'Match Monitor - Last Scanned Live TransID'
WHERE ParameterID = 20;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(29,'MatchMonitor_LastScannedNonliveTransID','Match Monitor - Last Scanned Nonlive TransID','BIGINT UNSIGNED','0');


