/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
	Creator:	20240130@Victoria.Le
	Task:		Initial Data for SystemParameter - Need to get the latest value of paramid before deploying
	Server:		DB061 & DB062 
	
	Revisions:
			- 20240130@Victoria.Le: Initial Writing - Step 4[Redmine: #191955]	
*/


USE	WASAVerse;
GO
INSERT INTO dbo.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue) VALUES 
	(1,'TWGroupBetting_LastScanTime','TWGroupBetting_LastScanTransSec','BIGINT','0')
,	(2,'TWGroupBetting_SkipTransCount','TWGroupBetting_SkipTransCount','INT','0')
,	(3,'TWGroupBetting_LastSequenceId','TWGroupBetting_LastSequenceId','BIGINT','0')
,	(4,'TWGroupBetting_CountTotalTicket_BatchSize','TWGroupBetting_CountTotalTicket_BatchSize','INT','5000')
,	(5,'TWGroupBetting_CountTotalTicket_LastSequenceId','TWGroupBetting_CountTotalTicket_LastSequenceId','BIGINT','0')
,	(6,'TWGroupBetting_CountTotalTicket_Interruptted','TWGroupBetting_CountTotalTicket_Interruptted','BIT','0')
;

/*
-- ONLY SIT
GO
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (1, 1, 1, 0, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (1, 1, 3, 0, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (2, 1, 1, 1, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (2, 1, 3, 1, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (3, 1, 7, 0, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (3, 1, 8, 0, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (4, 1, 7, 1, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (4, 1, 8, 1, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (5, 0, 1, 0, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (5, 0, 3, 0, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (6, 0, 1, 1, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (6, 0, 3, 1, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (7, 0, 7, 0, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (7, 0, 8, 0, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (8, 0, 7, 1, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (8, 0, 8, 1, 1)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (9, 1, 1, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (9, 1, 3, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (10, 1, 7, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (10, 1, 8, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (11, 1, 609, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (11, 1, 610, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (12, 0, 1, 0, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (12, 0, 3, 0, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (13, 0, 1, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (13, 0, 3, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (14, 0, 7, 0, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (14, 0, 8, 0, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (15, 0, 7, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (15, 0, 8, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (16, 0, 609, 0, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (16, 0, 610, 0, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (17, 0, 609, 1, 2)
INSERT [dbo].[TWGroupBettingGroupingRule] ([RuleId], [IsBigLeague], [Bettype], [IsLive], [Sporttype]) VALUES (17, 0, 610, 1, 2)
GO
SET IDENTITY_INSERT [dbo].[TWGroupBettingRule] ON 

INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (1, N'RuleType1', 5, 14, 8, 70, N'1,2', 50, N'x,z', 70)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (2, N'RuleType2', 5, 14, 8, 80, N'1,2', 60, N'x,z', 80)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (3, N'RuleType3', 5, 8, 8, 60, N'1,2', 50, N'x,z', 70)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (4, N'RuleType4', 5, 9, 8, 70, N'1,2', 60, N'x,z', 80)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (5, N'RuleType5', 5, 10, 8, 60, N'1,2', 50, N'x,z', 70)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (6, N'RuleType6', 5, 13, 8, 70, N'1,2', 70, N'x,z', 80)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (7, N'RuleType7', 5, 5, 8, 60, N'1,2', 50, N'x,z', 70)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (8, N'RuleType8', 5, 8, 8, 70, N'1,2', 70, N'x,z', 80)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (9, N'RuleType9', 5, 11, 8, 50, N'1,2', 50, N'x,z', 50)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (10, N'RuleType10', 5, 6, 8, 50, N'1,2', 50, N'x,z', 50)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (11, N'RuleType11', 5, 7, 8, 50, N'1,2', 50, N'x,z', 50)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (12, N'RuleType12', 5, 9, 8, 50, N'1,2', 50, N'x,z', 60)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (13, N'RuleType13', 5, 10, 8, 50, N'1,2', 50, N'x,z', 50)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (14, N'RuleType14', 5, 4, 8, 50, N'1,2', 50, N'x,z', 60)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (15, N'RuleType15', 5, 5, 8, 50, N'1,2', 50, N'x,z', 50)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (16, N'RuleType16', 5, 4, 8, 50, N'1,2', 50, N'x,z', 60)
INSERT [dbo].[TWGroupBettingRule] ([RuleId], [RuleName], [LimitSecond], [TicketCountLimit], [RFMLimitValue], [RFMLimitPercent], [CustClassLimitValue], [CustClassLimitPercent], [BetFromLimitValue], [BetFromLimitPercent]) VALUES (17, N'RuleType17', 5, 5, 8, 50, N'1,2', 50, N'x,z', 50)
SET IDENTITY_INSERT [dbo].[TWGroupBettingRule] OFF
GO

*/