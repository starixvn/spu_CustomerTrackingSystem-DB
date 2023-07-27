/*
    Creator: 	20230721@Jonas.Huynh
    Task:	 	Saba Classification [Redmine ID: #185320]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #1. New table [CustomerClassification_BySport_LatestActiveDay]
CREATE TABLE [dbo].[CustomerClassification_BySport_LatestActiveDay](
	CustId		  INT,
	SportGroup	  SMALLINT,	
	LastTransDate DATE	   NOT NULL,
	LastTransTime DATETIME NOT NULL,
	CreatedTime	  DATETIME NOT NULL,
	PRIMARY KEY(CustId, SportGroup)
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_LatestActiveDay_LastTransDate] ON [dbo].[CustomerClassification_BySport_LatestActiveDay]
(
	LastTransDate ASC
)
GO

-- #2. Add Priority
INSERT INTO [dbo].[CustomerClassification_BySport_Priority] (GroupId, GroupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 4, 'New Customer', 20)
GO

-- #3. Changes Rule GroupID
UPDATE r
SET r.RuleGroupId = CASE r.RuleGroupId
						WHEN 3 THEN 100
						WHEN 4 THEN 200
						WHEN 5 THEN 202
						WHEN 6 THEN 203
						WHEN 7 THEN 204
						WHEN 8 THEN 300
						WHEN 9 THEN 302
						WHEN 10 THEN 304
						WHEN 11 THEN 305
						WHEN 12 THEN 400
						WHEN 13 THEN 403
						WHEN 14 THEN 404
						WHEN 15 THEN 406
						WHEN 16 THEN 407
						WHEN 17 THEN 500
						WHEN 18 THEN 503
						WHEN 19 THEN 306
						WHEN 20 THEN 401
						WHEN 21 THEN 405
						WHEN 22 THEN 501
						ELSE r.RuleGroupId
				    END
FROM [dbo].[CustomerClassification_BySport_Rule] AS r;

-- #4. Add Rules
-- NEW
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount) 
VALUES (1, 145, 201, 'New', 6, 0, 20);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount) 
VALUES (1, 912, 201, 'New', 6, 0, 15);

-- GOOD
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Margin, ActiveDays) 
VALUES (101, 145, 205, 'Good', 5, 200, -2, 8);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Margin, ActiveDays) 
VALUES (101, 912, 205, 'Good', 5, 150, -3, 8);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, WinlossRM, ActiveDays) 
VALUES (102, 145, 205, 'Good', 5, 200, -20, 8);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, WinlossRM, ActiveDays) 
VALUES (102, 912, 205, 'Good', 5, 200, -5, 8);

-- NORMAL
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Margin, Margin2) 
VALUES (201, 145, 202, 'Normal', 4, NULL, 20, -2, 0);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Margin, Margin2) 
VALUES (201, 912, 202, 'Normal', 4, NULL, 15, -3, 0);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, WinlossRM) 
VALUES (205, 145, 202, 'Normal', 4, NULL, 20, -2, 0);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, WinlossRM) 
VALUES (205, 912, 202, 'Normal', 4, NULL, 15, -3, 0);

-- PROBATION
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (301, 145, 206, 'Probation', 3, 203, 30, 50000, 0, 2);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (301, 912, 206, 'Probation', 3, 203, 25, 1500, 0, 3);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (303, 145, 206, 'Probation', 3, 204, 30, 100000, 2);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (303, 912, 206, 'Probation', 3, 204, 25, 3000, 3);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (307, 145, 206, 'Probation', 3, 0, 20, 0, 50000); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (307, 145, 206, 'Probation', 3, 201, 20, 0, 50000); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (307, 145, 206, 'Probation', 3, 202, 20, 0, 50000); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (307, 145, 206, 'Probation', 3, 205, 20, 0, 50000); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (307, 145, 206, 'Probation', 3, 206, 20, 0, 50000); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (307, 912, 206, 'Probation', 3, 0, 15, 0, 1500); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (307, 912, 206, 'Probation', 3, 201, 15, 0, 1500); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (307, 912, 206, 'Probation', 3, 202, 15, 0, 1500); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (307, 912, 206, 'Probation', 3, 205, 15, 0, 1500); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, Margin, WinlossRM) 
VALUES (307, 912, 206, 'Probation', 3, 206, 15, 0, 1500); --PROBATION


-- SMART
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 145, 203, 'Smart', 2, 0, 30, 50000, 0, 2); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 145, 203, 'Smart', 2, 201, 30, 50000, 0, 2); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 145, 203, 'Smart', 2, 202, 30, 50000, 0, 2); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 145, 203, 'Smart', 2, 205, 30, 50000, 0, 2); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 145, 203, 'Smart', 2, 206, 30, 50000, 0, 2); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 145, 203, 'Smart', 2, 204, 30, 50000, 0, 2); --RISKY

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 912, 203, 'Smart', 2, 0, 25, 1500, 0, 3); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 912, 203, 'Smart', 2, 201, 25, 1500, 0, 3); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 912, 203, 'Smart', 2, 202, 25, 1500, 0, 3); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 912, 203, 'Smart', 2, 205, 25, 1500, 0, 3); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 912, 203, 'Smart', 2, 206, 25, 1500, 0, 3); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (402, 912, 203, 'Smart', 2, 204, 25, 1500, 0, 3); --RISKY


--RISKY
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin) 
VALUES (502, 145, 204, 'Risky', 1, 0, 30, 100000, 2); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin) 
VALUES (502, 145, 204, 'Risky', 1, 201, 30, 100000, 2); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (502, 145, 204, 'Risky', 1, 202, 30, 100000, 2); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (502, 145, 204, 'Risky', 1, 205, 30, 100000, 2); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (502, 145, 204, 'Risky', 1, 206, 30, 100000, 2); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (502, 145, 204, 'Risky', 1, 203, 30, 100000, 2); --SMART 

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin) 
VALUES (502, 912, 204, 'Risky', 1, 0, 25, 3000, 3); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin) 
VALUES (502, 912, 204, 'Risky', 1, 201, 25, 3000, 3); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (502, 912, 204, 'Risky', 1, 202, 25, 3000, 3); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (502, 912, 204, 'Risky', 1, 205, 25, 3000, 3); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (502, 912, 204, 'Risky', 1, 206, 25, 3000, 3); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (502, 912, 204, 'Risky', 1, 203, 25, 3000, 3); --SMART 
GO

GRANT SELECT ON [dbo].[CustomerClassification_BySport_LatestActiveDay] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_LatestActiveDay] TO [bodbSPUNet]
GO