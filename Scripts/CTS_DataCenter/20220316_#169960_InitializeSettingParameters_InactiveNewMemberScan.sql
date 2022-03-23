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
(80,'InactiveNewMember_LastCreatedDate', 'LastCreatedDate Config for Inactive New Member Scan', 'DATETIME', '2020-06-13 00:00:00'),
(81,'InactiveNewMember_LastCTSCustID', 'LastCTSCustID Config for Inactive New Member Scan', 'BIGINT UNSIGNED', '0'),
(82,'InactiveNewMember_LastScannedTime', 'LastScannedTime Config for Inactive New Member Scan', 'DATETIME', '2020-06-13 00:00:00');

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES(14,11, 'CTS Classification - Sending','CTS Classification - Sending','Inactivate New Member','Inactivate New Member',1,1,'Inactivate New Member (No bet within 30 last days)',CURRENT_TIME());