/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20221118@Jonas.Huynh
    Task:	 	Category by Sport - Support Non-Sport [Redmine ID: #179500]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

ALTER TABLE [dbo].[CustomerClassification_BySport_Rule]
ADD WinDaysRate DECIMAL(5,2) NULL;

GO

ALTER TABLE [dbo].[CustomerClassification_BySport_InputLog]
ADD WinDaysRate DECIMAL(5,2) NULL;
GO

ALTER TABLE [dbo].[CustomerClassification_BySport_LatestChanged]
ADD WinDaysRate DECIMAL(5,2) NULL;
GO

-- NEW
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Operator_BetCount) 
VALUES (1, 229, 201, 'New', 6, 0, 20, '<');

-- GOOD
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (3, 229, 205, 'Good', 5, 300, '>', -2, '<', 150000, '>', 10, '>=');

-- NORMAL
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (4, 229, 202, 'Normal', 4, NULL, 20, '>=', -2, '<=',  0, '<');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, BetCount2, Operator_BetCount2, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (5, 229, 202, 'Normal', 4, NULL, 20, '>=', 300, '>', -2, '<', 150000, '>', 10, '>=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (7, 229, 202, 'Normal', 4, 0, 20, '>=', 0, '>=', 10000, '<');

-- PROBATION
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (8, 229, 206, 'Probation', 3, 203, 0, '<=', 1, '<=', 20, '>=', 20000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (9, 229, 206, 'Probation', 3, 204, 0, '<=', 1, '<=', 20, '>=', 20000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 229, 206, 'Probation', 3, 0, 1, 20, '>=', 0, '>='); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 229, 206, 'Probation', 3, 201, 1, 20, '>=', 0, '>='); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 229, 206, 'Probation', 3, 202, 1, 20, '>=', 0, '>='); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (10, 229, 206, 'Probation', 3, 205, 1, 20, '>=', 0, '>='); --GOOD


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 229, 206, 'Probation', 3, 0, 0, 20, '>=', 0, '>=', 10000, '>='); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 229, 206, 'Probation', 3, 201, 0, 20, '>=', 0, '>=', 10000, '>='); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 229, 206, 'Probation', 3, 202, 0, 20, '>=', 0, '>=', 10000, '>='); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (11, 229, 206, 'Probation', 3, 205, 0, 20, '>=', 0, '>=', 10000, '>='); --GOOD


-- SMART
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate)  
VALUES (20, 229, 203, 'Smart', 2, 0, 0, '<=', 1, '<=', 20, '>=', 20000, '>', 50); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate)  
VALUES (20, 229, 203, 'Smart', 2, 201, 0, '<=', 1, '<=', 20, '>=', 20000, '>', 50); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate)  
VALUES (20, 229, 203, 'Smart', 2, 202, 0, '<=', 1, '<=', 20, '>=', 20000, '>', 50); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate)  
VALUES (20, 229, 203, 'Smart', 2, 205, 0, '<=', 1, '<=', 20, '>=', 20000, '>', 50); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate)  
VALUES (20, 229, 203, 'Smart', 2, 206, 0, '<=', 1, '<=', 20, '>=', 20000, '>', 50); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate)  
VALUES (20, 229, 203, 'Smart', 2, 204, 0, '<=', 1, '<=', 20, '>=', 20000, '>', 50); --RISKY


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate) 
VALUES (21, 229, 203, 'Smart', 2, 204, 1, '>', 20, '>=', 30000, '<=', 80);


--RISKY
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate) 
VALUES (22, 229, 204, 'Risky', 1, 0, 1, '>', 20, '>=', 30000, '>', 80); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate) 
VALUES (22, 229, 204, 'Risky', 1, 201, 1, '>', 20, '>=', 30000, '>', 80); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate) 
VALUES (22, 229, 204, 'Risky', 1, 202, 1, '>', 20, '>=', 30000, '>', 80); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate) 
VALUES (22, 229, 204, 'Risky', 1, 205, 1, '>', 20, '>=', 30000, '>', 80); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate) 
VALUES (22, 229, 204, 'Risky', 1, 206, 1, '>', 20, '>=', 30000, '>', 80); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinDaysRate) 
VALUES (22, 229, 204, 'Risky', 1, 203, 1, '>', 20, '>=', 30000, '>', 80); --SMART 