/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20211006@Aries.Nguyen
    Task:	 	Add System Parameter
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES(50, 'ProblemCase_Classification_BatchSize', 'ProblemCase Classification BatchSize', 'INT', '500'); 

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES(51, 'ProblemCase_AssIP_BatchSize', 'ProblemCase IP BatchSize', 'INT', '200'); 

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES(52, 'ProblemCase_AssDevice_BatchSize', 'ProblemCase Device BatchSize', 'INT', '50'); 
