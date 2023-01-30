/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20230118@Jonas.Huynh
    Task:	 	Fix issue missing rule for inactive to new category [Redmine ID: #182997]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount) 
VALUES (1, 201, 'New', 6, 1001, 10);

INSERT INTO [dbo].[CustomerClassification_Rule] (RuleGroupId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount) 
VALUES (1, 201, 'New', 6, 1002, 10);

GO