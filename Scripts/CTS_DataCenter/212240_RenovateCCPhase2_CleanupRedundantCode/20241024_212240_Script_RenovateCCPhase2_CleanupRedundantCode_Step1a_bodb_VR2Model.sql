/*<info serverAlias="DBVR2-bodb_VR2Model" databaseType="1"></info>*/
/*
		Created:	20241017@Victoria.Le
		Task:		RenovateCC Phase 2 - Clean up redundant code - Drop columns with prefix _arc/new/bk
		DB:			bodb_VR2Model

		Param's Expanation:
		
		Example:
			
		Revisions: 
			- 20241017@Victoria.Le:			Initial Writing [Redmine ID: #212240]
*/
USE bodb_VR2Model;

/************************* I. Tables Rule - Must be deployed priority ******************************/
ALTER TABLE dbo.CustomerClassification_Rule
DROP COLUMN CategoryID_new,
			CurrentCategory_new,
			CategoryID_bk,
			CurrentCategory_bk;

ALTER TABLE dbo.CustomerClassification_BySport_Rule
DROP COLUMN CategoryID_new,
			CurrentCategory_new,
			CategoryID_bk,
			CurrentCategory_bk;
			
/************************* II. Tables Classification - Create new table  ******************************/
/*CustomerClassification*/
CREATE TABLE [dbo].[CustomerClassification](
  [ID] [bigint] IDENTITY(1,1) NOT NULL,
  [RowVersion] [timestamp] NOT NULL,
  [CustId] [int] NOT NULL,
  [SportId] [int] NOT NULL,
  [CurrentCategoryId] [int] NULL,
  [CategoryId] [int] NULL,
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
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_CustIdRowVersion] ON [dbo].[CustomerClassification]
(
  [CustId] ASC,
  [RowVersion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_RowVersion] ON [dbo].[CustomerClassification]
(
  [RowVersion] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

/*CustomerClassification_BySport*/
CREATE TABLE [dbo].[CustomerClassification_BySport](
  [ID] [bigint] IDENTITY(1,1) NOT NULL,
  [RowVersion] [timestamp] NOT NULL,
  [CustId] [int] NOT NULL,
  [SportId] [int] NOT NULL,
  [CurrentCategoryId] [int] NULL,
  [CategoryId] [int] NULL,
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
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_CustIdSportIdRowVersion] ON [dbo].[CustomerClassification_BySport]
(
  [CustId] ASC,
  [SportId] ASC,
  [RowVersion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_RowVersion] ON [dbo].[CustomerClassification_BySport]
(
  [RowVersion] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

/************************* III. Tables CustomerClassification_Parameter - Initialize  ******************************/

DECLARE @GENERAL_LASTSCANNEDROW		TINYINT = 1;
DECLARE @BYSPORT_LASTSCANNEDROW		TINYINT = 2;

UPDATE cc WITH(ROWLOCK, UPDLOCK)
SET 	cc.[Value] = 0
FROM dbo.CustomerClassification_Parameter AS cc
WHERE cc.[DataId] IN (@GENERAL_LASTSCANNEDROW, @BYSPORT_LASTSCANNEDROW);
