/*
    Creator: 	20230721@Jonas.Huynh
    Task:	 	Saba Classification [Redmine ID: #185320]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- NEW
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount) 
VALUES (1, 145, 201, 'New', 6, 0, 20);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount) 
VALUES (1, 912, 201, 'New', 6, 0, 15);

-- GOOD
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Margin, ActiveDays) 
VALUES (23, 145, 205, 'Good', 5, 200, -2, 8);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Margin, ActiveDays) 
VALUES (23, 912, 205, 'Good', 5, 150, -3, 8);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, WinlossRM, ActiveDays) 
VALUES (24, 145, 205, 'Good', 5, 200, -20, 8);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, WinlossRM, ActiveDays) 
VALUES (24, 912, 205, 'Good', 5, 200, -5, 8);

-- NORMAL
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 145, 202, 'Normal', 4, NULL, 20, -2, 0);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Margin, Margin2) 
VALUES (4, 912, 202, 'Normal', 4, NULL, 15, -3, 0);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, WinlossRM) 
VALUES (25, 145, 202, 'Normal', 4, NULL, 20, -2, 0);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, WinlossRM) 
VALUES (25, 912, 202, 'Normal', 4, NULL, 15, -3, 0);

-- PROBATION
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (26, 145, 206, 'Probation', 3, 203, 30, 50000, 0, 2);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (26, 912, 206, 'Probation', 3, 203, 25, 1500, 0, 3);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (27, 145, 206, 'Probation', 3, 204, 30, 100000, 2);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (27, 912, 206, 'Probation', 3, 204, 25, 3000, 3);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (28, 145, 206, 'Probation', 3, 0, 20, 0, 50000); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (28, 145, 206, 'Probation', 3, 201, 20, 0, 50000); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (28, 145, 206, 'Probation', 3, 202, 20, 0, 50000); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (28, 145, 206, 'Probation', 3, 205, 20, 0, 50000); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (28, 145, 206, 'Probation', 3, 206, 20, 0, 50000); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (28, 912, 206, 'Probation', 3, 0, 15, 0, 1500); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (28, 912, 206, 'Probation', 3, 201, 15, 0, 1500); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (28, 912, 206, 'Probation', 3, 202, 15, 0, 1500); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (28, 912, 206, 'Probation', 3, 205, 15, 0, 1500); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (28, 912, 206, 'Probation', 3, 206, 15, 0, 1500); --PROBATION


-- SMART
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 145, 203, 'Smart', 2, 0, 30, 50000, 0, 2); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 145, 203, 'Smart', 2, 201, 30, 50000, 0, 2); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 145, 203, 'Smart', 2, 202, 30, 50000, 0, 2); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 145, 203, 'Smart', 2, 205, 30, 50000, 0, 2); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 145, 203, 'Smart', 2, 206, 30, 50000, 0, 2); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 145, 203, 'Smart', 2, 204, 30, 50000, 0, 2); --RISKY

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 912, 203, 'Smart', 2, 0, 25, 1500, 0, 3); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 912, 203, 'Smart', 2, 201, 25, 1500, 0, 3); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 912, 203, 'Smart', 2, 202, 25, 1500, 0, 3); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 912, 203, 'Smart', 2, 205, 25, 1500, 0, 3); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 912, 203, 'Smart', 2, 206, 25, 1500, 0, 3); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (29, 912, 203, 'Smart', 2, 204, 25, 1500, 0, 3); --RISKY


--RISKY
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin) 
VALUES (30, 145, 204, 'Risky', 1, 0, 30, 100000, 2); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin) 
VALUES (30, 145, 204, 'Risky', 1, 201, 30, 100000, 2); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (30, 145, 204, 'Risky', 1, 202, 30, 100000, 2); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (30, 145, 204, 'Risky', 1, 205, 30, 100000, 2); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (30, 145, 204, 'Risky', 1, 206, 30, 100000, 2); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (30, 145, 204, 'Risky', 1, 203, 30, 100000, 2); --SMART 

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin) 
VALUES (30, 912, 204, 'Risky', 1, 0, 25, 3000, 3); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin) 
VALUES (30, 912, 204, 'Risky', 1, 201, 25, 3000, 3); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (30, 912, 204, 'Risky', 1, 202, 25, 3000, 3); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (30, 912, 204, 'Risky', 1, 205, 25, 3000, 3); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (30, 912, 204, 'Risky', 1, 206, 25, 3000, 3); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (30, 912, 204, 'Risky', 1, 203, 25, 3000, 3); --SMART 