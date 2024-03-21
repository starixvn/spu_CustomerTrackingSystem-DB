/*<info serverAlias="DBVR2-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20240314@Jonas.Huynh
    Task:	 	Renovate Non-Sport Rules [Redmine ID: #201359]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #1. Changes Rule GroupID
DELETE t
FROM [dbo].[CustomerClassification_BySport_Rule] AS t 
WHERE SportId = 229 AND RuleGroupId IN (100, 201, 203, 300, 302, 304, 305, 401, 405, 501);
GO

-- #4. Add Rules
-- GOOD
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Margin, IsProbationLastDay) 
VALUES (103, 229, 205, 'Good', 5, 20, 0, NULL);

-- NORMAL
UPDATE [dbo].[CustomerClassification_BySport_Rule]
SET	 [BetCount] = 20
    ,[Margin] = 0
    ,[Margin2] = 3
WHERE RuleGroupId = 200 AND SportId = 229;

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (206, 229, 202, 'Normal', 4, 20, 50000, 3, NULL);

-- PROBATION
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (308, 229, 206, 'Probation', 3, 20, 50000, 3, NULL);

-- SMART
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay)
VALUES (408, 229, 203, 'Smart', 2, 0, 20, 100000, 5, 60, NULL); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay)
VALUES (408, 229, 203, 'Smart', 2, 201, 20, 100000, 5, 60, NULL); --New

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay)
VALUES (408, 229, 203, 'Smart', 2, 202, 20, 100000, 5, 60, NULL); --Normal

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay)
VALUES (408, 229, 203, 'Smart', 2, 205, 20, 100000, 5, 60, NULL); --Good

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay)
VALUES (408, 229, 203, 'Smart', 2, 206, 20, 100000, 5, 60, 1); --Probation

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay)
VALUES (408, 229, 203, 'Smart', 2, 203, 20, 100000, 5, 60, NULL); --Smart

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay)
VALUES (408, 229, 203, 'Smart', 2, 204, 20, 100000, 5, 60, NULL); --Risky

--RISKY
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay) 
VALUES (504, 229, 204, 'Risky', 1, 0, 20, 200000, 7, 80, NULL); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay) 
VALUES (504, 229, 204, 'Risky', 1, 201, 20, 200000, 7, 80, NULL); --New

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay) 
VALUES (504, 229, 204, 'Risky', 1, 202, 20, 200000, 7, 80, NULL); --Normal

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay) 
VALUES (504, 229, 204, 'Risky', 1, 205, 20, 200000, 7, 80, NULL); --Good

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay) 
VALUES (504, 229, 204, 'Risky', 1, 206, 20, 200000, 7, 80, 1); --Probation

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay) 
VALUES (504, 229, 204, 'Risky', 1, 203, 20, 200000, 7, 80, NULL); --Smart

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, WinDaysRate, IsProbationLastDay) 
VALUES (504, 229, 204, 'Risky', 1, 204, 20, 200000, 7, 80, NULL); --Risky