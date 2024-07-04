SELECT * INTO dbo.CustomerClassification_BySport_Rule FROM CustomerClassification_BySport_Rule WITH(NOLOCK);
SELECT * INTO dbo.CustomerClassification_Rule FROM CustomerClassification_Rule WITH(NOLOCK);

CREATE TABLE [dbo].[CustomerClassification](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustId] [int] NOT NULL,
	[SportId] [int] NOT NULL,
	[CurrentCategoryId] [smallint] NULL,
	[CategoryId] [smallint] NOT NULL,
	[CreatedDate] [date] NOT NULL,
	[CreatedTime] [datetime] NULL,
	[TurnoverRM] [decimal](19, 4) NULL,
	[WinlossRM] [decimal](19, 4) NULL,
	[BetCount] [bigint] NULL,
	[ActiveDays] [int] NULL,
	[PerformanceTime] [datetime] NULL,
	[ScanTaggingType] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[CustomerClassification_BySport](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[CustId] [int] NOT NULL,
	[SportId] [int] NOT NULL,
	[CurrentCategoryId] [smallint] NULL,
	[CategoryId] [smallint] NOT NULL,
	[CreatedDate] [date] NOT NULL,
	[CreatedTime] [datetime] NULL,
	[TurnoverRM] [decimal](19, 4) NULL,
	[WinlossRM] [decimal](19, 4) NULL,
	[BetCount] [bigint] NULL,
	[ActiveDays] [int] NULL,
	[PerformanceTime] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]





