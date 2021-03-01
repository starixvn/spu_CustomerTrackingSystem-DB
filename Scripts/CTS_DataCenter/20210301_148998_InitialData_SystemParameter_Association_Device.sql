/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210301@Aries.Nguyen
Task:	 	Init Data for insert association device account [Redmine ID: 148998] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES	(13,'Last_CTSAssDevID', 'Keep the last CTSAssDevID for insert association', 'BIGINT UNSIGNED', '0')

    


