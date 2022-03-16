/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20220207@Harvey.Nguyen
    Task:	 	Create table and init data for calculate TW Groupbeting  [Redmine ID: 169334]
    DBName:		CTS_DataCenter
*/

USE [bodb02]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[SPU_GroupBettingTicket](
	CustId		INT		NOT NULL,
	TransId		BIGINT	NOT NULL
 CONSTRAINT [PK_SPU_GroupBettingTicket] PRIMARY KEY CLUSTERED 
(
	TransId ASC
))
GO

CREATE TABLE [dbo].[SPU_GroupBettingCustomer](
	CustId				INT			NOT NULL,
	GBTicketCount		INT			NULL,
	TicketCount			INT			NULL,
	LastModifiedDate	DATETIME	NULL
 CONSTRAINT [PK_SPU_GroupBettingCustomer] PRIMARY KEY CLUSTERED 
(
	CustId ASC
))

GO
CREATE NONCLUSTERED INDEX IX_SPU_GroupBettingCustomer_LastModifiedDate   
    ON dbo.[SPU_GroupBettingCustomer] (LastModifiedDate);  
GO

CREATE TABLE [dbo].[SPU_GroupBettingRule] (
  RuleId 				INT	IDENTITY(1,1)	NOT NULL,
  RuleName 				VARCHAR(100)		NULL,
  LimitSecond 			SMALLINT 	 		NULL,
  TicketCountLimit		SMALLINT 	 		NULL,
  RFMLimitValue 		SMALLINT 	 		NULL,
  RFMLimitPercent		TINYINT 	 		NULL,
  CustClassLimitValue	VARCHAR(50)			NULL,
  CustClassLimitPercent	TINYINT 	 		NULL,
  BetFromLimitValue		VARCHAR(50) 		NULL,
  BetFromLimitPercent	TINYINT 			NULL
   CONSTRAINT [PK_SPU_GroupBettingRule] PRIMARY KEY CLUSTERED 
(
	RuleId ASC
));

CREATE TABLE [dbo].[SPU_GroupBettingGroupingRule] (
  RuleId 		INT 		NOT NULL,
  IsBigLeague	BIT			NULL,
  Bettype		SMALLINT	NULL,
  IsLive		BIT			NULL,
  Sporttype		TINYINT		NULL
);



-- Init data [SPU_GroupBettingRule]--
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType1', '5', '13', '8', '70', '1,2', '50', 'x,z', '70');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType2', '5', '13', '8', '70', '1,2', '50', 'x,z', '70');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType3', '5', '7', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType4', '5', '8', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType5', '5', '11', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType6', '5', '12', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType7', '5', '6', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType8', '5', '7', '8', '60', '1,2', '50', 'x,z', '70');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType9', '5', '12', '8', '50', '1,2', '50', 'x,z', '50');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType10', '5', '7', '8', '50', '1,2', '50', 'x,z', '50');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType11', '5', '8', '8', '50', '1,2', '50', 'x,z', '50');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType12', '5', '10', '8', '50', '1,2', '50', 'x,z', '60');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType13', '5', '11', '8', '50', '1,2', '50', 'x,z', '50');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType14', '5', '5', '8', '50', '1,2', '50', 'x,z', '60');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType15', '5', '6', '8', '50', '1,2', '50', 'x,z', '50');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType16', '5', '5', '8', '50', '1,2', '50', 'x,z', '60');
INSERT INTO dbo.SPU_GroupBettingRule (RuleName, LimitSecond, TicketCountLimit, RFMLimitValue, RFMLimitPercent, CustClassLimitValue, CustClassLimitPercent, BetFromLimitValue, BetFromLimitPercent) VALUES ('RuleType17', '5', '6', '8', '50', '1,2', '50', 'x,z', '50');


-- Init data [SPU_GroupBettingGroupingRule]--
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (1,1,1,0,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (1,1,3,0,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (2,1,1,1,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (2,1,3,1,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (3,1,7,0,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (3,1,8,0,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (4,1,7,1,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (4,1,8,1,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (5,0,1,0,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (5,0,3,0,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (6,0,1,1,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (6,0,3,1,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (7,0,7,0,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (7,0,8,0,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (8,0,7,1,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (8,0,8,1,1)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (9,1,1,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (9,1,3,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (10,1,7,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (10,1,8,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (11,1,609,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (11,1,610,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (12,0,1,0,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (12,0,3,0,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (13,0,1,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (13,0,3,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (14,0,7,0,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (14,0,8,0,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (15,0,7,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (15,0,8,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (16,0,609,0,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (16,0,610,0,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (17,0,609,1,2)
INSERT INTO dbo.SPU_GroupBettingGroupingRule (RuleId, IsBigLeague, Bettype, IsLive, Sporttype) VALUES (17,0,610,1,2)