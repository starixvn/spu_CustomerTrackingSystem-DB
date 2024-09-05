/*<info serverAlias="DBVR2-bodb_VR2Model" databaseType="1"></info>*/
/*
		Created:	20240829@Victoria.Le
		Task:		Initial Data - Backup Data
		DB:			bodb_VR2Model

		Param's Expanation:
		
		Example:
			
		Revisions: 
			- 20240829@Victoria.Le:			Initial Writing [Redmine ID: #205317]
*/
	USE bodb_VR2Model;

	/************************* I. Tables Rule - Must be deployed priority ******************************/

	UPDATE cc WITH(ROWLOCK, UPDLOCK)
	SET 	cc.CategoryID 			= cc.CategoryID_new
		,	cc.CurrentCategory 		= cc.CurrentCategory_new
	FROM dbo.CustomerClassification_Rule AS cc;
		
	UPDATE cc WITH(ROWLOCK, UPDLOCK)
	SET 	cc.CategoryID	 		= cc.CategoryID_new
		,	cc.CurrentCategory	 	= cc.CurrentCategory_new
	FROM dbo.CustomerClassification_BySport_Rule AS cc;
	
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
	  [CategoryID_new] [int] NULL,
	  [CurrentCategoryId_new] [int] NULL,
	  [CategoryID_bk] [int] NULL,
	  [CurrentCategoryID_bk] [int] NULL,
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
	  [CategoryID_new] [int] NULL,
	  [CurrentCategoryId_new] [int] NULL,
	  [CategoryID_bk] [int] NULL,
	  [CurrentCategoryID_bk] [int] NULL,
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
	
	/************************* III. Tables Classification - Initialize and backup  ******************************/
	
	DROP TABLE IF EXISTS #tmpRawData;
	CREATE TABLE #tmpRawData (CategoryID INT, OldCategoryID INT);
	
	INSERT INTO #tmpRawData (CategoryID, OldCategoryID)
	VALUES 	(40100,201),
			(40300,202),
			(40500,203),
			(40600,204),
			(40200,205),
			(40400,206),
			(40700,1001),
			(40701,1002);
	
	UPDATE cc WITH(ROWLOCK, UPDLOCK)
	SET 	cc.CategoryID_bk	 		= cc.CategoryID
		,	cc.CurrentCategoryId_bk		= cc.CurrentCategoryId
		,	cc.CategoryID	 			= CASE WHEN temp1.CategoryID IS NOT NULL THEN temp1.CategoryID ELSE cc.CategoryID END
		,	cc.CurrentCategoryId	 	= CASE WHEN temp2.CategoryID IS NOT NULL THEN temp2.CategoryID ELSE cc.CurrentCategoryId END
	FROM dbo.CustomerClassification AS cc
		LEFT JOIN #tmpRawData AS temp1 ON temp1.OldCategoryID = cc.CategoryID
		LEFT JOIN #tmpRawData AS temp2 ON temp2.OldCategoryID = cc.CurrentCategoryId;
		
	UPDATE cc WITH(ROWLOCK, UPDLOCK)
	SET 	cc.CategoryID_bk	 		= cc.CategoryID
		,	cc.CurrentCategoryId_bk 	= cc.CurrentCategoryId
		,	cc.CategoryID	 			= CASE WHEN temp1.CategoryID IS NOT NULL THEN temp1.CategoryID ELSE cc.CategoryID END
		,	cc.CurrentCategoryId	 	= CASE WHEN temp2.CategoryID IS NOT NULL THEN temp2.CategoryID ELSE cc.CurrentCategoryId END
	FROM dbo.CustomerClassification_bysport AS cc
		LEFT JOIN #tmpRawData AS temp1 ON temp1.OldCategoryID = cc.CategoryID
		LEFT JOIN #tmpRawData AS temp2 ON temp2.OldCategoryID = cc.CurrentCategoryId;