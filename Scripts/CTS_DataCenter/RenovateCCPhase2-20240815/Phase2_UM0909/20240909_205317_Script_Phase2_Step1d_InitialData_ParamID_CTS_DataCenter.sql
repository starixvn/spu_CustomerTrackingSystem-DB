/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240829@Victoria.Le
Task:	 	Initial data - ParamID 
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240829@Victoria.Le: 		Initial Writing - Initial Data - Setting [Redmine ID: #205317]
										
*/

USE CTS_DataCenter;

INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES 	(992, 'CTS_DC_CustClassification', 'CTS_DC_CustClassification Batchsize','BIGINT', 1000)
-- ,		(993, 'Backup_Initial_History_BySport', 'Backup_Initial_History_BySport_Batchsize','INT',1000)
;
