/*<info serverAlias="DBVR2-bodb_VR2Model" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
/*
Creator:	20250304@Casey.Huynh
Task:	 	Agent PA Losing
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250304@Casey.Huynh: Created [Redmine ID: #218588]
Reviewer:
*/

USE bodb_VR2Model;

ALTER TABLE CustomerClassificationAgency  
ALTER COLUMN LastXYDaysWinlossRatio DECIMAL(19,4) NULL;
