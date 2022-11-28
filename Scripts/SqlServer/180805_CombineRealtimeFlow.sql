/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20221125@Jonas.Huynh
    Task:	 	Combine Realtime Flow of General CC and By Sport [Redmine ID: #180805]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #1. Insert new system parameter
DECLARE @MinValue DATETIME;

SELECT @MinValue = Min(CONVERT(DATETIME, [Value], 121))
FROM dbo.CustomerClassification_Parameter WITH(NOLOCK)
WHERE DataId in (1, 3);

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (5, 'Normal Accounts Classification - Realtime - Get datetime for picking up the latest customer changes', 'VARCHAR(20)', CONVERT( [varchar](200), @MinValue, 121));
GO

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (6, 'Normal Accounts Classification - Realtime - General - Get max ID of processed record', 'VARCHAR(20)', '0');
GO

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (7, 'Normal Accounts Classification - Realtime - BySport - Get max ID of processed records', 'VARCHAR(20)', '0');
GO

-- #2. Create new table [CustomerClassification_LatestChanged] for GeneraL - Realtime flow
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[CustomerClassification_LatestChanged](
	[ID]				[bigint] IDENTITY(1,1),  
	[CustId]			[int] NOT NULL,
	[TurnoverRM]		[decimal](19, 4) NULL,
	[WinlossRM]			[decimal](19, 4) NULL,
	[TurnoverORG]		[decimal](19, 4) NULL,
	[WinlossORG]		[decimal](19, 4) NULL,
	[BetCount]			[bigint] NULL,
	[ActiveDays]		[int] NULL,
	[CreateDate]		[datetime] NOT NULL,
	[Margin]			[decimal](19, 4) NULL,
	PRIMARY KEY (ID)
)
GO

CREATE CLUSTERED INDEX [CIX_CustomerClassificationLatestChanged_ID] ON [dbo].[CustomerClassification_LatestChanged]
(
	[ID]
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassificationLatestChanged_CustId] ON [dbo].[CustomerClassification_LatestChanged]
(
	[CustId]
)


GRANT SELECT ON [dbo].[CustomerClassification_LatestChanged] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_LatestChanged] TO [bodbSPUNet]
GO


-- #3. Alter table [CustomerClassification_BySport_LatestChanged] for BySport - Realtime flow

EXEC sp_rename '[dbo].[CustomerClassification_BySport_LatestChanged].[LastModifiedDate]', 'CreateDate', 'COLUMN';
GO

ALTER TABLE [dbo].[CustomerClassification_BySport_LatestChanged]
ALTER COLUMN [CreateDate] [datetime] NOT NULL;
GO

ALTER TABLE [dbo].[CustomerClassification_BySport_LatestChanged] DROP CONSTRAINT PK__Customer__D33A205ADFBE544F
GO


ALTER TABLE [dbo].[CustomerClassification_BySport_LatestChanged]
ADD [ID] [bigint] IDENTITY(1,1) PRIMARY KEY;
GO

CREATE CLUSTERED INDEX [CIX_CustomerClassificationBySportLatestChanged_ID] ON [dbo].[CustomerClassification_BySport_LatestChanged]
(
	[ID]
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassificationBySportLatestChanged_CustId_SportId] ON [dbo].[CustomerClassification_BySport_LatestChanged]
(
	[CustId],
	[SportId]
)