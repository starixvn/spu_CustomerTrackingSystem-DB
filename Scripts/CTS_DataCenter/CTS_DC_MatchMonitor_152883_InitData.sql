/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 20200423@Long.Luu
Task:	 	Customer Category
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
		- 20200423@Long.Luu: Created [#132623]
Reviewer:
*/

#####################CTS_DataCenter.SportGroup
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(20,'MatchMonitor_LastScannedTransID','Match Monitor - Last Scanned TransID','BIGINT UNSIGNED','0');
/*
#####################CTS_Admin.LogType
INSERT INTO CTS_Admin.LogType (LogTypeName,LogTypeDescription)
VALUE('Insert Customer Category','Insert Customer Category');

INSERT INTO CTS_Admin.LogType (LogTypeName,LogTypeDescription)
VALUE('Update Customer Category','Update Customer Category');

INSERT INTO CTS_Admin.LogType (LogTypeName,LogTypeDescription)
VALUE('Delete Customer Category','Delete Customer Category');
*/

