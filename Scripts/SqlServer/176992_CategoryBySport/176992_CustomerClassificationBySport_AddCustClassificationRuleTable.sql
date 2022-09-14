/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220831@Jonas.Huynh
    Task:	 	Customer Classification by SportType [Redmine ID: #176992]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassification_BySport_Rule]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassification_BySport_Rule]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerClassification_BySport_Rule](
	[RuleId] [int] NOT NULL,
	[RuleGroupId] [int] NOT NULL,
	[SportId] [int]	NOT NULL,
	[CategoryId] [smallint]	NOT NULL,
	[CategoryName] varchar(50) NOT NULL,
	[Prioity] [smallint] NOT NULL,
	[CurrentCategory] [smallint] NULL,
	[IsSpecialSite]	BIT DEFAULT NULL,
	[IsDeposit]	BIT DEFAULT NULL,
	[BetCount] [bigint] NULL,	
	[Margin] [money] NULL,
	[Margin2] [money] NULL,
	[WinlossRM] [money] NULL,
	[WinlossRM2] [money] NULL,
	[TurnoverRM] [money] NULL,
	[ActiveDays] [int] NULL,
	[Operator_BetCount] varchar(5) NULL,
	[Operator_Margin] varchar(5) NULL,
	[Operator_Margin2] varchar(5) NULL,
	[Operator_Turnover] varchar(5) NULL,
	[Operator_ActiveDate] varchar(5) NULL,
	[Operator_Winloss] varchar(5) NULL,
	[Operator_Winloss2] varchar(5) NULL
PRIMARY KEY CLUSTERED 
(
	[RuleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

CREATE NONCLUSTERED INDEX [CIX_CustomerClassification_BySport_Rule_SportId] ON [dbo].[CustomerClassification_BySport_Rule]
(
	[SportId] ASC
)
GO
-- New
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount) 
VALUES (1, 1, 1, 201, 'New', 6, 10, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount) 
VALUES (2, 1, 2, 201, 'New', 6, 10, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount) 
VALUES (3, 1, 43, 201, 'New', 6, 20, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount) 
VALUES (4, 1, 99, 201, 'New', 6, 20, '<');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss)
VALUES (5, 2, 1, 201, 'New', 6, 1, 10, '>=', 0, '<', -5000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (6, 2, 2, 201, 'New', 6, 1, 10, '>=', 0, '<', -5000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss)
VALUES (7, 2, 43, 201, 'New', 6, 1, 20, '>=', 0, '<', -5000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (8, 2, 99, 201, 'New', 6, 1, 20, '>=', 0, '<', -5000, '>');

-- Good
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (9, 3, 1, 205, 'Good', 5, 300, '>', -2, '<', 150000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (10, 3, 2, 205, 'Good', 5, 200, '>', -2, '<', 100000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (11, 3, 43, 205, 'Good', 5, 200, '>', -2, '<', 100000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (12, 3, 99, 205, 'Good', 5, 200, '>', -2, '<', 75000, '>', 8, '>=');

-- Normal
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (13, 4, 1, 202, 'Normal', 4, 10, '>=', -2, '<=',  0, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (14, 4, 2, 202, 'Normal', 4, 10, '>=', -2, '<=',  0, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (15, 4, 43, 202, 'Normal', 4, 20, '>=', -2, '<=',  0, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (16, 4, 99, 202, 'Normal', 4, 20, '>=', -2, '<=',  0, '<');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (17, 5, 1, 202, 'Normal', 4, 10, '>=', -2, '<', 150000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (18, 5, 2, 202, 'Normal', 4, 10, '>=', -2, '<', 100000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (19, 5, 43, 202, 'Normal', 4, 20, '>=', -2, '<', 100000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate)
VALUES (20, 5, 99, 202, 'Normal', 4, 20, '>=', -2, '<', 75000, '>', 8, '>=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (21, 6, 1, 202, 'Normal', 4, 1, 10, '>=', 0, '<', -5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (22, 6, 2, 202, 'Normal', 4, 1, 10, '>=', 0, '<', -5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (23, 6, 43, 202, 'Normal', 4, 1, 20, '>=', 0, '<', -5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (24, 6, 99, 202, 'Normal', 4, 1, 20, '>=', 0, '<', -5000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (25, 7, 1, 202, 'Normal', 4, 0, 10, '>=', 0, '>=', 10000, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (26, 7, 2, 202, 'Normal', 4, 0, 10, '>=', 0, '>=', 10000, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (27, 7, 43, 202, 'Normal', 4, 0, 20, '>=', 0, '>=', 50000, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (28, 7, 99, 202, 'Normal', 4, 0, 20, '>=', 0, '>=', 50000, '<');

-- Probation
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (29, 8, 1, 206, 'Probation', 3, 0, '<=', 1, '<=', 20, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (30, 8, 2, 206, 'Probation', 3, 0, '<=', 1, '<=', 10, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (31, 8, 43, 206, 'Probation', 3, 0, '<=', 2, '<=', 30, '>=', 5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (32, 8, 99, 206, 'Probation', 3, 0, '<=', 2, '<=', 30, '>=', 5000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (33, 9, 1, 206, 'Probation', 3, 1, 10, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (34, 9, 2, 206, 'Probation', 3, 1, 10, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (35, 9, 43, 206, 'Probation', 3, 1, 20, '>=', 0, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin) 
VALUES (36, 9, 99, 206, 'Probation', 3, 1, 20, '>=', 0, '>=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (37, 10, 1, 206, 'Probation', 3, 0, 10, '>=', 0, '>=', 10000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (38, 10, 2, 206, 'Probation', 3, 0, 10, '>=', 0, '>=', 10000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (39, 10, 43, 206, 'Probation', 3, 0, 20, '>=', 0, '>=', 5000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (40, 10, 99, 206, 'Probation', 3, 0, 20, '>=', 0, '>=', 5000, '>=');

-- Smart
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (41, 11, 1, 203, 'Smart', 2, 0, '<=', 1, '<=', 20, '>=', 25000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (42, 11, 2, 203, 'Smart', 2, 0, '<=', 1, '<=', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (43, 11, 43, 203, 'Smart', 2, 0, '<=', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (44, 11, 99, 203, 'Smart', 2, 0, '<=', 2, '<=', 30, '>=', 10000, '>');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (45, 12, 43, 203, 'Smart', 2, 2, '>', 30, '>=', 0, '>', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2)  
VALUES (46, 12, 99, 203, 'Smart', 2, 2, '>', 30, '>=', 0, '>', 10000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss, WinlossRM2, Operator_Winloss2) 
VALUES (47, 13, 1, 203, 'Smart', 2, 1, '>', 20, '>=', 0, '>', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM2, Operator_Winloss2)  
VALUES (48, 13, 2, 203, 'Smart', 2, 1, '>', 10, '>=', 0, '>', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM2, Operator_Winloss2) 
VALUES (49, 13, 43, 203, 'Smart', 2, 2, '>', 30, '>=', 0, '>', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM2, Operator_Winloss2)   
VALUES (50, 13, 99, 203, 'Smart', 2, 2, '>', 30, '>=', 0, '>', 10000, '<=');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)   
VALUES (51, 14, 1, 203, 'Smart', 2, 203, 0, '>=', 1, '<=', 20, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)   
VALUES (52, 14, 1, 203, 'Smart', 2, 203, 0, '>=', 1, '<=', 20, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)   
VALUES (53, 14, 1, 203, 'Smart', 2, 203, 0, '>=', 2, '<=', 30, '>=', 5000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)   
VALUES (54, 14, 1, 203, 'Smart', 2, 203, 0, '>=', 2, '<=', 30, '>=', 5000, '>');

-- Risky
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (55, 15, 1, 204, 'Risky', 1, 1, '>', 20, '>=', 25000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (56, 15, 2, 204, 'Risky', 1, 1, '>', 10, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (57, 15, 43, 204, 'Risky', 1, 2, '>', 30, '>=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (58, 15, 99, 204, 'Risky', 1, 2, '>', 30, '>=', 20000, '>');


INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (59, 16, 1, 204, 'Risky', 1, 204, 1, '>', 20, '>=', 25000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (60, 16, 2, 204, 'Risky', 1, 204, 1, '>', 10, '<=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (61, 16, 43, 204, 'Risky', 1, 204, 2, '>', 30, '<=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, RuleGroupId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (62, 16, 99, 204, 'Risky', 1, 204, 2, '>', 30, '<=', 10000, '>');