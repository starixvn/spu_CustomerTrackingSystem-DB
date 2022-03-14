/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220310@Long.Luu
Task:	 	Init Data for Reactivate Customer process [Redmine ID: 169761] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES	(76,'ReactivateCustomer_LastScannedTime', 'ReactivateCustomer_LastScannedTime', 'DATETIME', '2021-01-01 01:01:01');
