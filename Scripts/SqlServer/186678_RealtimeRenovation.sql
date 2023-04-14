/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20230414@Jonas.Huynh
    Task:	 	Realtime Renovation [Redmine ID: #186678]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

CREATE TABLE [dbo].[CustomerClassification_NormalPool](
	ID			BIGINT	 PRIMARY KEY IDENTITY(1,1),
	CustId		INT		 NOT NULL,
	[Priority]	TINYINT	 NOT NULL,
	IsProcessed	BIT		 DEFAULT 0,
	CreatedTime	Datetime NOT NULL
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_NormalPool_Priority_IsProcessed] ON [dbo].[CustomerClassification_NormalPool]
(
	[Priority]	ASC,
	IsProcessed ASC
)
GO

CREATE TABLE [dbo].[CustomerClassification_LastTransDate](
	CustId		  INT  PRIMARY KEY,
	LastTransDate DATE NOT NULL
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_LastTransDate] ON [dbo].[CustomerClassification_LastTransDate]
(
	LastTransDate ASC
)
GO

CREATE TABLE [dbo].[CustomerClassification_ScannedDailyCust](
	CustId		INT	 PRIMARY KEY,
	CreatedDate DATE NOT NULL
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_ScannedDailyCust_CreatedDate] ON [dbo].[CustomerClassification_ScannedDailyCust]
(
	CreatedDate ASC
)
GO

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

ALTER TABLE [dbo].[CustomerClassification] ADD PerformanceDateTime DateTime NULL
GO

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (3, 'Normal Accounts Classification - General - Get processed MaxID from normal pool classification', 'BIGINT', 0);
GO

GRANT SELECT ON [dbo].[CustomerClassification_NormalPool] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_NormalPool] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_LastTransDate] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_LastTransDate] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_ScannedDailyCust] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_ScannedDailyCust] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_Log] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_Log] TO [bodbSPUNet]
GO