/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
Creator:	20240314@Thomas.Nguyen
Task:	 	Add new priority for manual by sport
Server:  	Master
DBName:		bodb_VR2Model

Revisions: 
		- 20240314@Thomas.Nguyen: Created [Redmine ID: #201360]
Reviewer:
*/
USE [bodb_VR2Model]
GO
INSERT INTO CustomerClassification_BySport_Priority(GroupId,GroupName,FunctionId,FunctionName,Priority)
VALUES (1,'ByFlow',5,'Rescan From Manual Action',10) 