/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20221027@Jonas.Huynh
    Task:	 	E-Sport - Add new Licensee and new rule [Redmine ID: #179501]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- NEW
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (19, 43, 201, 'New', 6, 10, '<', 0, '>', 50, '<=');

-- PROBATION
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (20, 43, 206, 'Probation', 3, 10, '>', 50, '>');

