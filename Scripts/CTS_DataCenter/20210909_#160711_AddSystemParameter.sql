/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator: 	20210909@Aries.Nguyen
	Task:	 	Update bet limit [Redmine ID: #160711]
	DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc,ParameterDataType,ParameterValue)
VALUES (42, 'CustEvidence_AffectedQueue_BatchSize', 'Cust Evidence Affected Queue Batch Size', 'INT', '500');

