/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator: 	20210827@Aries.Nguyen
	Task:	 	Init data for TW suggested Categories [Redmine ID: #160758]
	DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc,ParameterDataType,ParameterValue)
VALUES (35, 'Classification_History_DataChanged_LastestID', 'Classification History DataChanged LastestID', 'BIGINT UNSIGNED', '0');

INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc,ParameterDataType,ParameterValue)
VALUES (40, 'Classification_History_CleanUp_BatchSize', 'Classification History CleanUp BatchSize', 'INT', '1000');

INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc,ParameterDataType,ParameterValue)
VALUES (41, 'Classification_History_CleanUp_TakeDays', 'Classification History CleanUp Take Days', 'INT', '30');