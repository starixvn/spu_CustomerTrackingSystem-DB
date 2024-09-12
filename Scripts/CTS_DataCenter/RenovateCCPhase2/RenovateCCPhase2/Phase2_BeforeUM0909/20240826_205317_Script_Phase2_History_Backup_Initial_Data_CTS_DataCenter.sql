/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240826@Victoria.Le
	Task :	Initial Data - ParamID 
	DB:			
	
	Description: 

	Revisions:	
		- 20240826@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES (994, 'Backup_Initial_History_General', 'Backup_Initial_History_General_Batchsize','BIGINT',1000)
,	(993, 'Backup_Initial_History_BySport', 'Backup_Initial_History_BySport_Batchsize','INT',1000);
