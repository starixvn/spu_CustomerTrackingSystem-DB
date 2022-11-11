/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20221027@Jonas.Huynh
    Task:	 	E-Sport - Add new Licensee and new rule [Redmine ID: #179501]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- PROBATION
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, CurrentCategory, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (19, 43, 206, 'Probation', 0, 3, 10, '>', 50, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, CurrentCategory, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (19, 43, 206, 'Probation', 201, 3, 10, '>', 50, '>');
