/*<info serverAlias="DBVR2-bodb_VR2Model" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20240327@Jonas.Huynh
    Task:	 	EC2024 - Resolve Locking [Redmine ID: #200842]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #1. CREATE GENERAL TABLE 
CREATE TABLE [dbo].[CustomerClassification](
	[ID]					BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[RowVersion]			ROWVERSION		NOT NULL,
	[CustId]				INT				NOT NULL,
	[SportId]				INT				NOT NULL,
	[CurrentCategoryId]		SMALLINT		NULL,
	[CategoryId]			SMALLINT		NOT NULL,
	[CreatedDate]			DATE			NOT NULL,
	[CreatedTime]			DATETIME		NULL,
	[TurnoverRM]			DECIMAL(19, 4)	NULL,
	[WinlossRM]				DECIMAL(19, 4)	NULL,
	[BetCount]				BIGINT			NULL,
	[ActiveDays]			INT				NULL,
	[PerformanceTime]		DATETIME		NULL,
	[ScanTaggingType]		INT				NULL
)
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_CustIdRowVersion] ON [dbo].[CustomerClassification]
(
	[CustId],
	[RowVersion]
);
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_RowVersion] ON [dbo].[CustomerClassification]
(
	[RowVersion] DESC
)
GO

-- #2.  CREATE BY-SPORT TABLE 
CREATE TABLE [dbo].[CustomerClassification_BySport](
	[ID]					BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[RowVersion]			ROWVERSION		NOT NULL,
	[CustId]				INT				NOT NULL,
	[SportId]				INT				NOT NULL,
	[CurrentCategoryId]		SMALLINT		NULL,
	[CategoryId]			SMALLINT		NOT NULL,
	[CreatedDate]			DATE			NOT NULL,
	[CreatedTime]			DATETIME		NULL,
	[TurnoverRM]			DECIMAL(19, 4)	NULL,
	[WinlossRM]				DECIMAL(19, 4)	NULL,
	[BetCount]				BIGINT			NULL,
	[ActiveDays]			INT				NULL,
	[PerformanceTime]		DATETIME		NULL
)
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_CustIdSportIdRowVersion] ON [dbo].[CustomerClassification_BySport]
(
	[CustId] ASC,
	[SportId] ASC,
	[RowVersion]
);
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_RowVersion] ON [dbo].[CustomerClassification_BySport]
(
	[RowVersion] DESC
)
GO

-- #3. UPDATE INDEX
DROP INDEX [IX_CustomerClassification_NormalPool_Priority_CustId] ON [dbo].[CustomerClassification_NormalPool];
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_NormalPool_CustId] ON [dbo].[CustomerClassification_NormalPool]
(
	CustId
);
GO

DROP INDEX [IX_CustomerClassification_BySport_NormalPool_Priority_CustId_SportGroup] ON [dbo].[CustomerClassification_BySport_NormalPool];
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_NormalPool_CustId_SportGroup] ON [dbo].[CustomerClassification_BySport_NormalPool]
(
	CustId,
	SportGroup
);
GO

-- #4. ADD SYSTEM PARAMETER
DECLARE @GeneralValue BIGINT;
DECLARE @BysportValue BIGINT;

SELECT @GeneralValue = CAST(MIN([RowVersion]) AS BIGINT) FROM dbo.CustomerClassification WITH(NOLOCK);
SELECT @BysportValue = CAST(MIN([RowVersion]) AS BIGINT) FROM dbo.CustomerClassification_BySport WITH(NOLOCK);

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (1, 'Normal Accounts Classification - General - Lastest Scan Rowversion', 'ROWVERSION', CONVERT(VARCHAR(200), @GeneralValue));

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (2, 'Normal Accounts Classification - BySport - Lastest Scan Rowversion', 'ROWVERSION', CONVERT(VARCHAR(200), @BysportValue));
GO