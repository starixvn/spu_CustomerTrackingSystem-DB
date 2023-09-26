/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20230926@Casey.Huynh
Task:	 	Enhance Update Username2 NULL for Main Account
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230926@Casey.Huynh: Created [Redmine ID: #193049]
Reviewer:
*/
USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(146, 'CTSCustomer_LastCTSCustID_NullUserName2','CTSCustomer_LastCTSCustID_NullUserName2_MainAccount', 'BIGINT UNSIGNED', 0);
