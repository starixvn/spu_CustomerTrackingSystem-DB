/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
	Creator:	20240130@Victoria.Le
	Task:		Create tables on new database
	Server:		DB061 & DB062
	
	Revisions:
			- 20240130@Victoria.Le: Initial Writing - Step 3[Redmine: #191955]	
*/


USE	WASAVerse;
GO

/*****I. Existing tables*****/
/**1. SPU_GroupBettingGroupingRule >> TWGroupBettingGroupingRule**/
CREATE TABLE [dbo].[TWGroupBettingGroupingRule](
	[RuleId] [int] NOT NULL,
	[IsBigLeague] [bit] NULL,
	[Bettype] [smallint] NULL,
	[IsLive] [bit] NULL,
	[Sporttype] [tinyint] NULL
) ON [DATA]
GO

/**2. SPU_GroupBettingRule >> TWGroupBettingRule**/
CREATE TABLE [dbo].[TWGroupBettingRule](
	[RuleId] [int] IDENTITY(1,1) NOT NULL,
	[RuleName] [varchar](100) NULL,
	[LimitSecond] [smallint] NULL,
	[TicketCountLimit] [smallint] NULL,
	[RFMLimitValue] [smallint] NULL,
	[RFMLimitPercent] [tinyint] NULL,
	[CustClassLimitValue] [varchar](50) NULL,
	[CustClassLimitPercent] [tinyint] NULL,
	[BetFromLimitValue] [varchar](50) NULL,
	[BetFromLimitPercent] [tinyint] NULL,
PRIMARY KEY CLUSTERED
(
	[RuleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [IDX]
) ON [DATA]
GO

/**3. SPU_GroupBettingTicket >> TWGroupBettingTicket**/
CREATE TABLE [dbo].[TWGroupBettingTicket](
	[CustId] [int] NOT NULL,
	[TransId] [bigint] NOT NULL,
	[TransDate] [date] NULL,
PRIMARY KEY CLUSTERED
(
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [IDX]
) ON [DATA]
GO

CREATE NONCLUSTERED INDEX [IX_TWGroupBettingTicket_TransDate] ON [dbo].[TWGroupBettingTicket]
(
	[TransDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [IDX]
GO

/**4. SPU_GroupBettingTicket_History >> TWGroupBettingTicket_History**/
CREATE TABLE [dbo].[TWGroupBettingTicket_History](
	[TransId] [bigint] NOT NULL,
	[TransDate] [date] NULL,
	[RulesType] [varchar](100) NULL,
	[IsRule1] [bit] NULL,
	[IsRule2] [bit] NULL,
	[IsRule3] [bit] NULL,
	[InsertTime] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[TransId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [IDX]
) ON [DATA]
GO

ALTER TABLE [dbo].[TWGroupBettingTicket_History] ADD  DEFAULT (NULL) FOR [RulesType]
GO

ALTER TABLE [dbo].[TWGroupBettingTicket_History] ADD  DEFAULT (NULL) FOR [IsRule1]
GO

ALTER TABLE [dbo].[TWGroupBettingTicket_History] ADD  DEFAULT (NULL) FOR [IsRule2]
GO

ALTER TABLE [dbo].[TWGroupBettingTicket_History] ADD  DEFAULT (NULL) FOR [IsRule3]
GO

ALTER TABLE [dbo].[TWGroupBettingTicket_History] ADD  DEFAULT (getdate()) FOR [InsertTime]
GO

CREATE NONCLUSTERED INDEX [IX_TWGroupBettingTicket_History_TransDate] ON [dbo].[TWGroupBettingTicket_History]
(
	[TransDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [IDX]
GO

/**5. SPU_GroupBettingCustomer >> TWGroupBettingCustomer**/
CREATE TABLE [dbo].[TWGroupBettingCustomer](
	[CustId] [int] NOT NULL,
	[GBTicketCount] [int] NULL,
	[TicketCount] [int] NULL,
	[ScanDate] [date] NOT NULL,
	[LastModifiedDate] [datetime] NULL,
	[LastCountTotalTicketDate] [datetime] NULL,
	[RejectTicketCount] [int] NULL,
	[DesktopTicketCount] [int] NULL,
	[ParlayTicketCount] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[CustId] ASC,
	[ScanDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [IDX_TWGB]
) ON [DATA_TWGB]
GO

ALTER TABLE [dbo].[TWGroupBettingCustomer] ADD  DEFAULT (NULL) FOR [RejectTicketCount]
GO

ALTER TABLE [dbo].[TWGroupBettingCustomer] ADD  DEFAULT (NULL) FOR [DesktopTicketCount]
GO

ALTER TABLE [dbo].[TWGroupBettingCustomer] ADD  DEFAULT (NULL) FOR [ParlayTicketCount]
GO

/*****II. New tables*****/
/**6. SystemParameter**/
CREATE TABLE [dbo].[SystemParameter](
	[ParameterID] [smallint] NOT NULL,
	[ParameterName] [varchar](50) NOT NULL,
	[ParameterDesc] [varchar](200) NOT NULL,
	[ParameterDataType] [varchar](50) NOT NULL,
	[ParameterValue] [varchar](200) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ParameterID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [IDX]
) ON [DATA]
GO

/**7. TWGroupBettingCustomer_Archive**/
CREATE TABLE [dbo].[TWGroupBettingCustomer_Archive](
	[CustId] [int] NOT NULL,
	[GBTicketCount] [int] NULL,
	[TicketCount] [int] NULL,
	[ScanDate] [date] NOT NULL,
	[LastModifiedDate] [datetime] NULL,
	[LastCountTotalTicketDate] [datetime] NULL,
	[RejectTicketCount] [int] NULL,
	[DesktopTicketCount] [int] NULL,
	[ParlayTicketCount] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[CustId] ASC,
	[ScanDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [IDX_TWGB_BK]
) ON [DATA_TWGB_BK]
GO