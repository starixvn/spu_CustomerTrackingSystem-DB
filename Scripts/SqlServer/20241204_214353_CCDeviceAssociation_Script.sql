/*<info serverAlias="DBVR2-bodb_VR2Model" executers="DBCTS-WASAVerse" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20241204@Jonas.Huynh
    Task:	 	CC Device Association [Redmine ID: #214353]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

INSERT INTO dbo.CustomerClassification_Priority(GroupId, GroupName, FunctionId, FunctionName, Priority) VALUES 
(1, 'ByFlow', 8, 'Inactive New Customer', 1000),
(1, 'ByFlow', 9, 'Normal Links Dangerous Association', 100);