/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20230414@Jonas.Huynh
    Task:	 	Realtime Renovation [Redmine ID: #186678]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #0. Update Indexes
--DROP INDEX CIX_CustomerClassification_IsApplied  ON [dbo].[CustomerClassification];  
--CREATE CLUSTERED INDEX CIX_CustomerClassification_IsApplied_Id ON [dbo].[CustomerClassification] (
--	IsApplied ASC,
--	Id ASC
--);

-- #1. New table CustomerClassification_NormalPool
CREATE TABLE [dbo].[CustomerClassification_NormalPool](
	ID			BIGINT   PRIMARY KEY IDENTITY(1,1),
	CustId		INT		 NOT NULL,
	[Priority]	TINYINT  NOT NULL,
	FunctionId	SMALLINT NOT NULL,
	CreatedTime	Datetime NOT NULL
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_NormalPool_Priority_CustId] ON [dbo].[CustomerClassification_NormalPool]
(
	[Priority]	ASC,
	CustId
)

GO

-- #2. New table [CustomerClassification_LatestActiveDay]
CREATE TABLE [dbo].[CustomerClassification_LatestActiveDay](
	CustId		  INT  PRIMARY KEY,
	LastTransDate DATE NOT NULL
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_LatestActiveDay_LastTransDate] ON [dbo].[CustomerClassification_LatestActiveDay]
(
	LastTransDate ASC
)
GO

-- #3. New table CustomerClassification_ScannedDailyCust
CREATE TABLE [dbo].[CustomerClassification_ScannedDailyCust](
	CustId		INT	 PRIMARY KEY,
	CreatedDate DATE NOT NULL
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_ScannedDailyCust_CreatedDate] ON [dbo].[CustomerClassification_ScannedDailyCust]
(
	CreatedDate ASC
)
GO

-- #4. New table CustomerClassification_Log
CREATE TABLE [dbo].[CustomerClassification_Log](
	ID			BIGINT	 PRIMARY KEY IDENTITY(1,1),
	CustId		INT		 NOT NULL,
	FunctionId	SMALLINT NOT NULL,
	CreatedTime	DATETIME NOT NULL
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_Log_CustId_CreatedTime] ON [dbo].[CustomerClassification_Log]
(
	CustId,
	FunctionId DESC
)
GO

-- #5. New table CustomerClassification_RealtimeChanges
CREATE TABLE [dbo].[CustomerClassification_RealtimeChanges](
	ID			BIGINT	 PRIMARY KEY IDENTITY(1,1),
	CustId		INT		 NOT NULL,
	CreatedTime	DATETIME NOT NULL
)

-- #6. Add new column
ALTER TABLE [dbo].[CustomerClassification] ADD PerformanceTime DateTime NULL
GO

-- #7. New table CustomerClassification_Priority
CREATE TABLE [dbo].[CustomerClassification_Priority](
	GoupId	     BIGINT		  NOT NULL,
	GoupName     NVARCHAR(10) NOT NULL,
	FunctionId   INT		  NOT NULL,
	FunctionName NVARCHAR(50) NOT NULL,
	[Priority]   SMALLINT	  NOT NULL
)

CREATE CLUSTERED INDEX [CIX_CustomerClassification_Priority_GoupId_FunctionId] ON [dbo].[CustomerClassification_Priority]
(
	GoupId,
	FunctionId
)
GO

INSERT INTO [dbo].[CustomerClassification_Priority] (GoupId, GoupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 1, 'Realtime', 100)
GO

-- #8. New system parameter
DECLARE @Value DATETIME2;

SELECT @Value = CONVERT(DATETIME2, [Value], 121)
FROM dbo.CustomerClassification_Parameter WITH(NOLOCK)
WHERE DataId = 5;

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (3, 'Normal Accounts Classification - Realtime Check Changes - Get LastScannedTime', 'DATETIME', CONVERT( [varchar](200), @Value, 121));
GO

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (4, 'Normal Accounts Classification - Realtime Check Changes - Step minute jump for retrieving customer performance', 'TINYINT', '15');
GO

-- #9. Grant permissions
GRANT SELECT ON [dbo].[CustomerClassification_NormalPool] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_NormalPool] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_LatestActiveDay] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_LatestActiveDay] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_ScannedDailyCust] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_ScannedDailyCust] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_Log] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_Log] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_RealtimeChanges] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_RealtimeChanges] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_Priority] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_Priority] TO [bodbSPUNet]
GO