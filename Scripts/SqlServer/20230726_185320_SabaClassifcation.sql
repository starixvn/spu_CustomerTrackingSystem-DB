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
						WHEN 5 THEN 201
						WHEN 6 THEN 202
						WHEN 7 THEN 203
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
VALUES (102, 145, 205, 'Good', 5, 200, -20000, 8);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, WinlossRM, ActiveDays) 
VALUES (102, 912, 205, 'Good', 5, 150, -5000, 8);

-- NORMAL
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, BetCount2, Margin, ActiveDays) 
VALUES (204, 145, 202, 'Normal', 4, 20, 200, -2, 8);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, BetCount2, Margin, ActiveDays) 
VALUES (204, 912, 202, 'Normal', 4, 15, 150, -3, 8);


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, BetCount2, WinlossRM, ActiveDays) 
VALUES (205, 145, 202, 'Normal', 4, 20, 200, -20000, 8);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, BetCount2, WinlossRM, ActiveDays) 
VALUES (205, 912, 202, 'Normal', 4, 15, 150, -5000, 8);

-- PROBATION
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (301, 145, 206, 'Probation', 3, 203, 30, 50000, 0, 2);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2)
VALUES (301, 912, 206, 'Probation', 3, 203, 25, 1500, 0, 3);


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (303, 145, 206, 'Probation', 3, 204, 30, 100000, 2);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin)
VALUES (303, 912, 206, 'Probation', 3, 204, 25, 3000, 3);


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Margin) 
VALUES (307, 145, 206, 'Probation', 3, 20, 0);

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Margin) 
VALUES (307, 912, 206, 'Probation', 3, 15, 0);


-- SMART
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 145, 203, 'Smart', 2, 0, 30, 50000, 0, 2, NULL); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 145, 203, 'Smart', 2, 201, 30, 50000, 0, 2, NULL); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 145, 203, 'Smart', 2, 202, 30, 50000, 0, 2, NULL); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 145, 203, 'Smart', 2, 205, 30, 50000, 0, 2, NULL); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 145, 203, 'Smart', 2, 206, 30, 50000, 0, 2, 1); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 145, 203, 'Smart', 2, 203, 30, 50000, 0, 2, NULL); --SMART

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 145, 203, 'Smart', 2, 204, 30, 50000, 0, 2, NULL); --RISKY


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 912, 203, 'Smart', 2, 0, 25, 1500, 0, 3, NULL); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 912, 203, 'Smart', 2, 201, 25, 1500, 0, 3, NULL); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 912, 203, 'Smart', 2, 202, 25, 1500, 0, 3, NULL); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 912, 203, 'Smart', 2, 205, 25, 1500, 0, 3, NULL); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 912, 203, 'Smart', 2, 206, 25, 1500, 0, 3, 1); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 912, 203, 'Smart', 2, 203, 25, 1500, 0, 3, NULL); --SMART

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, Margin2, IsProbationLastDay)
VALUES (402, 912, 203, 'Smart', 2, 204, 25, 1500, 0, 3, NULL); --RISKY


--RISKY
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay) 
VALUES (502, 145, 204, 'Risky', 1, 0, 30, 100000, 2, NULL); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay) 
VALUES (502, 145, 204, 'Risky', 1, 201, 30, 100000, 2, NULL); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (502, 145, 204, 'Risky', 1, 202, 30, 100000, 2, NULL); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (502, 145, 204, 'Risky', 1, 205, 30, 100000, 2, NULL); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (502, 145, 204, 'Risky', 1, 206, 30, 100000, 2, 1); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (502, 145, 204, 'Risky', 1, 203, 30, 100000, 2, NULL); --SMART 

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (502, 145, 204, 'Risky', 1, 204, 30, 100000, 2, NULL); --RISKY 


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay) 
VALUES (502, 912, 204, 'Risky', 1, 0, 25, 3000, 3, NULL); --NULL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay) 
VALUES (502, 912, 204, 'Risky', 1, 201, 25, 3000, 3, NULL); --NEW

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (502, 912, 204, 'Risky', 1, 202, 25, 3000, 3, NULL); --NORMAL

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (502, 912, 204, 'Risky', 1, 205, 25, 3000, 3, NULL); --GOOD

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (502, 912, 204, 'Risky', 1, 206, 25, 3000, 3, 1); --PROBATION

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (502, 912, 204, 'Risky', 1, 203, 25, 3000, 3, NULL); --SMART 

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, BetCount, WinlossRM, Margin, IsProbationLastDay)
VALUES (502, 912, 204, 'Risky', 1, 204, 25, 3000, 3, NULL); --RISKY 
GO

GRANT SELECT ON [dbo].[CustomerClassification_BySport_LatestActiveDay] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_LatestActiveDay] TO [bodbSPUNet]
GO


UPDATE t WITH(ROWLOCK, UPDLOCK)
SET t.IsProbationLastDay = 1
FROM [dbo].[CustomerClassification_BySport_Rule] AS t WHERE RuleId IN (162, 169) AND SportId = 229;
GO