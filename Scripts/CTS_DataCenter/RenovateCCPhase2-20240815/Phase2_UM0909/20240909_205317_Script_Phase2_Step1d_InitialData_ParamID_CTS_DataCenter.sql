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
VALUES 	(992, 'CTS_DC_CustClassification_Probation', 'CTS_DC_CustClassification_Probation Batchsize','BIGINT', 1000)
,		(991, 'CTS_DC_CustClassification_Other', 'CTS_DC_CustClassification_Other Batchsize','BIGINT',1000)
,		(990, 'CTS_DC_CustClassification_Update', 'CTS_DC_CustClassification_Update Batchsize','BIGINT',1000)
;
