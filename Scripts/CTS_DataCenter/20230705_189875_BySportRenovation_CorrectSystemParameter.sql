/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230725@Jonas.Huynh
	Task:	 	Normal BySport Renovation 
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230705@Jonas.Huynh: Create Schema [Redmine ID: #189875]

*/

UPDATE CTS_DataCenter.SystemParameter
SET ParameterValue = 5000
WHERE ParameterID = 113;