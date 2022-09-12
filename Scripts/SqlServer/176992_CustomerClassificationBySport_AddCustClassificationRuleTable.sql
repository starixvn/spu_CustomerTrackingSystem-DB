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
	[TurnoverRM] [money] NULL,
	[ActiveDays] [int] NULL,
	[Operator_BetCount] varchar(5) NULL,
	[Operator_Margin] varchar(5) NULL,
	[Operator_Margin2] varchar(5) NULL,
	[Operator_Turnover] varchar(5) NULL,
	[Operator_ActiveDate] varchar(5) NULL,
	[Operator_Winloss] varchar(5) NULL
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
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount) 
VALUES (1, 1, 201, 'New', 1, 10, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount) 
VALUES (2, 2, 201, 'New', 1, 10, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount) 
VALUES (3, 43, 201, 'New', 1, 20, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount) 
VALUES (4, 99, 201, 'New', 1, 20, '<');

-- Good
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (5, 1, 205, 'Good', 2, 300, '>', -2, '<', 150000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (6, 2, 205, 'Good', 2, 200, '>', -2, '<', 100000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (7, 43, 205, 'Good', 2, 200, '>', -2, '<', 100000, '>', 8, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (8, 99, 205, 'Good', 2, 200, '>', -2, '<', 75000, '>', 8, '>=');

-- Normal
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (9, 1, 202, 'Normal', 3, 10, '>=', -2, '<=',  0, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (10, 2, 202, 'Normal', 3, 10, '>=', -2, '<=',  0, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (11, 43, 202, 'Normal', 3, 20, '>=', -2, '<=',  0, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, Margin2, Operator_Margin2) 
VALUES (12, 99, 202, 'Normal', 3, 20, '>=', -2, '<=',  0, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (13, 1, 202, 'Normal', 3, 10, '>=', -2, '<', 150000, '<=', 8, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (14, 2, 202, 'Normal', 3, 10, '>=', -2, '<', 150000, '<=', 8, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate) 
VALUES (15, 43, 202, 'Normal', 3, 20, '>=', -2, '<', 150000, '<=', 8, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, BetCount, Operator_BetCount, Margin, Operator_Margin, TurnoverRM, Operator_Turnover, ActiveDays, Operator_ActiveDate)
VALUES (16, 99, 202, 'Normal', 3, 20, '>=', -2, '<', 150000, '<=', 8, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (17, 1, 202, 'Normal', 3, 1, 10, '>=', 0, '<', -5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (18, 2, 202, 'Normal', 3, 1, 10, '>=', 0, '<', -5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (19, 43, 202, 'Normal', 3, 1, 20, '>=', 0, '<', -5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsSpecialSite, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (20, 99, 202, 'Normal', 3, 1, 20, '>=', 0, '<', -5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (21, 1, 202, 'Normal', 3, 0, 10, '>=', 0, '>', 10000, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (22, 2, 202, 'Normal', 3, 0, 10, '>=', 0, '>', -10000, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (23, 43, 202, 'Normal', 3, 0, 20, '>=', 0, '>', 50000, '<');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, BetCount, Operator_BetCount, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (24, 99, 202, 'Normal', 3, 0, 20, '>=', 0, '>', 50000, '<');

-- Probation
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, Margin, Operator_Margin, WinlossRM, Operator_Winloss)
VALUES (25, 1, 206, 'Probation', 4, 0, 0, '>', 10000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, Margin, Operator_Margin, WinlossRM, Operator_Winloss)
VALUES (26, 2, 206, 'Probation', 4, 0, 0, '>', 10000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, Margin, Operator_Margin, WinlossRM, Operator_Winloss) 
VALUES (27, 43, 206, 'Probation', 4, 0, 0, '>', 5000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, Margin, Operator_Margin, WinlossRM, Operator_Winloss)  
VALUES (28, 99, 206, 'Probation', 4, 0, 0, '>', 5000, '>=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, IsDeposit, Margin, Operator_Margin)
VALUES (29, 1, 206, 'Probation', 4, 1, 0, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (30, 1, 206, 'Probation', 4, 0, '<', 1, '<=', 20, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (31, 2, 206, 'Probation', 4, 0, '<', 1, '<=', 20, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (32, 43, 206, 'Probation', 4, 0, '<', 2, '<=', 30, '>=', 5000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)
VALUES (32, 99, 206, 'Probation', 4, 0, '<', 2, '<=', 30, '>=', 5000, '<=');

-- Smart
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (33, 1, 203, 'Smart', 5, 0, '<', 1, '<=', 20, '>=', 25000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (34, 2, 203, 'Smart', 5, 0, '<', 1, '<=', 20, '>=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (35, 43, 203, 'Smart', 5, 0, '<', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (36, 99, 203, 'Smart', 5, 0, '<', 2, '<=', 30, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (37, 1, 203, 'Smart', 5, 1, '>', 20, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (38, 2, 203, 'Smart', 5, 1, '>', 20, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (39, 43, 203, 'Smart', 5, 2, '>', 30, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (40, 99, 203, 'Smart', 5, 2, '>', 30, '>=', 10000, '<=');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (41, 1, 203, 'Smart', 5, 203, 0, '<', 1, '<=', 20, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (42, 2, 203, 'Smart', 5, 203, 0, '<', 1, '<=', 20, '>=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (43, 43, 203, 'Smart', 5, 203, 0, '<', 2, '<=', 30, '>=', 5000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, Margin2, Operator_Margin2, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss)  
VALUES (44, 99, 203, 'Smart', 5, 203, 0, '<', 2, '<=', 30, '>=', 5000, '>');

-- Risky
INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (45, 1, 204, 'Risky', 6, 1, '>', 20, '<=', 25000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (46, 2, 204, 'Risky', 6, 1, '>', 20, '<=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (47, 43, 204, 'Risky', 6, 2, '>', 30, '<=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (48, 99, 204, 'Risky', 6, 2, '>', 30, '<=', 20000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (49, 1, 204, 'Risky', 6, 204, 1, '>', 20, '>=', 25000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (50, 2, 204, 'Risky', 6, 204, 1, '>', 20, '<=', 15000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (51, 43, 204, 'Risky', 6, 204, 2, '>', 30, '<=', 10000, '>');

INSERT INTO [dbo].[CustomerClassification_BySport_Rule] (RuleId, SportId, CategoryId, CategoryName, Prioity, CurrentCategory, Margin, Operator_Margin, BetCount, Operator_BetCount, WinlossRM, Operator_Winloss) 
VALUES (52, 99, 204, 'Risky', 6, 204, 2, '>', 30, '<=', 10000, '>');