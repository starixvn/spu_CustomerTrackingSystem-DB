/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220316@Irena.Vo
Task:	 	Initialize Setting Parameters for Inactive New Member Scan [Redmine ID: 169960] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES	
(79,'InactiveNewMember_BatchSize', 'BatchSize Config for Inactive New Member Scan', 'INT', 500),
(80,'InactiveNewMember_LastCustID', 'LastCustID Config for Inactive New Member Scan', 'BIGINT UNSIGNED', 0),
(81,'InactiveNewMember_LastScannedTime', 'LastScannedTime Config for Inactive New Member Scan', 'DATETIME', '0001-01-01 00:00:00');