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
,		(899, 'CTS_DC_CustClassification_BySport_Probation', 'CTS_DC_CustClassification_BySport_Probation Batchsize','BIGINT',1000)
,		(898, 'CTS_DC_CustClassification_BySport_Other', 'CTS_DC_CustClassification_BySport_Other Batchsize','BIGINT',1000)
,		(897, 'CTS_DC_CustClassification_BySport_Update', 'CTS_DC_CustClassification_BySport_Update Batchsize','BIGINT',1000)
,		(896, 'CTS_DC_CC_History_Init_Batchsize', 'CTS_DC_CC_History_Init_Batchsize','BIGINT',1000)
,		(895, 'CTS_DC_CC_History_Init_HistoryID', 'CTS_DC_CC_History_Init_HistoryID','BIGINT',8)
,		(894, 'CTS_DC_CC_BySport_History_Init_Batchsize', 'CTS_DC_CC_BySport_History_Init_Batchsize','BIGINT',1000)
,		(893, 'CTS_DC_CC_BySport_History_Init_HistoryID', 'CTS_DC_CC_BySport_History_Init_HistoryID','BIGINT',8)
,		(892, 'CTS_DC_CC_ArchiveCustomer_Init_Batchsize', 'CTS_DC_CC_ArchiveCustomer_Init_Batchsize','BIGINT',1000)
,		(891, 'CTS_DC_CC_ArchiveCustomer_Init_HistoryID', 'CTS_DC_CC_ArchiveCustomer_Init_HistoryID','BIGINT',8)
,		(890, 'CTS_DC_CC_History_RobotTW_MinID', 'CTS_DC_CC_History_RobotTW_MinID','BIGINT',246523005)
,		(889, 'CTS_DC_CC_History_RobotTW_MaxID', 'CTS_DC_CC_History_RobotTW_MaxID','BIGINT',1081037926)
,		(888, 'CTS_DC_CC_History_RobotTW_MinID', 'CTS_DC_CC_History_RobotCTS_MinID','BIGINT',248200688)
,		(887, 'CTS_DC_CC_History_RobotTW_MaxID', 'CTS_DC_CC_History_RobotCTS_MaxID','BIGINT',1075172195)
;
