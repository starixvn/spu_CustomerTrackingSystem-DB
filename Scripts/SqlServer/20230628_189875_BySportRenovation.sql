/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20230628@Jonas.Huynh
    Task:	 	BySport Renovation [Redmine ID: #189875]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #0. Update Indexes
ALTER TABLE [dbo].[CustomerClassification_BySport] DROP CONSTRAINT PK__Customer__3214EC27859ADA93;   
ALTER TABLE [dbo].[CustomerClassification_BySport] ADD CONSTRAINT PK_CustomerClassification_BySport_ID PRIMARY KEY NONCLUSTERED (ID)

DROP INDEX CIX_CustomerClassification_BySport_IsApplied  ON [dbo].[CustomerClassification_BySport];  
CREATE CLUSTERED INDEX CIX_CustomerClassification_BySport_IsApplied_Id ON  [dbo].[CustomerClassification_BySport](
	IsApplied ASC,
	Id ASC
);

ALTER TABLE [dbo].[CustomerClassification_BySport] ADD PerformanceTime DATETIME NULL
GO

ALTER TABLE [dbo].[CustomerClassification_BySport] ADD CurrentCategoryId SMALLINT NULL
GO

-- #1. New table CustomerClassification_BySport_NormalPool
CREATE TABLE [dbo].[CustomerClassification_BySport_NormalPool](
	ID			BIGINT   PRIMARY KEY IDENTITY(1,1),
	CustId		INT		 NOT NULL,
	SportGroup	SMALLINT NOT NULL,
	[Priority]	SMALLINT NOT NULL,
	FunctionId	SMALLINT NOT NULL,
	CreatedTime	DATETIME NOT NULL
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_NormalPool_Priority_CustId_SportGroup] ON [dbo].[CustomerClassification_BySport_NormalPool]
(
	[Priority]	ASC,
	CustId,
	SportGroup
)
GO

-- #2. New table CustomerClassification_ScannedDailyCust
CREATE TABLE [dbo].[CustomerClassification_BySport_ScannedDailyCust](
	CustId		INT,
	SportGroup	SMALLINT,
	CreatedDate DATE NOT NULL
	PRIMARY KEY (CustId, SportGroup)
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_ScannedDailyCust_CreatedDate] ON [dbo].[CustomerClassification_BySport_ScannedDailyCust]
(
	CreatedDate ASC
)
GO

-- #3. New table CustomerClassification_BySport_Log
CREATE TABLE [dbo].[CustomerClassification_BySport_Log](
	ID			BIGINT	 PRIMARY KEY IDENTITY(1,1),
	CustId		INT		 NOT NULL,
	SportGroup	SMALLINT NOT NULL,
	FunctionId	SMALLINT NOT NULL,
	CreatedTime	DATETIME NOT NULL
)

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_Log_CustId_CreatedTime] ON [dbo].[CustomerClassification_BySport_Log]
(
	CustId,
	SportGroup,
	FunctionId DESC
)
GO

-- #4. New table CustomerClassification_BySport_RealtimeChanges
CREATE TABLE [dbo].[CustomerClassification_BySport_RealtimeChanges](
	ID			BIGINT	 PRIMARY KEY IDENTITY(1,1),
	CustId		INT		 NOT NULL,
	SportGroup	SMALLINT NOT NULL,
	CreatedTime	DATETIME NOT NULL
)

-- #5. New table CustomerClassification_BySport_Priority
CREATE TABLE [dbo].[CustomerClassification_BySport_Priority](
	GroupId	     BIGINT		  NOT NULL,
	GroupName    NVARCHAR(10) NOT NULL,
	FunctionId	 INT		  NOT NULL,
	FunctionName NVARCHAR(50) NOT NULL,
	[Priority]   SMALLINT	  NOT NULL
)

CREATE CLUSTERED INDEX [CIX_CustomerClassification_BySport_Priority_GroupId_FunctionId] ON [dbo].[CustomerClassification_BySport_Priority]
(
	GroupId,
	FunctionId
)
GO

INSERT INTO [dbo].[CustomerClassification_BySport_Priority] (GroupId, GroupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 1, 'Realtime', 100)
GO

INSERT INTO [dbo].[CustomerClassification_BySport_Priority] (GroupId, GroupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 2, 'Probation', 200)
GO

INSERT INTO [dbo].[CustomerClassification_BySport_Priority] (GroupId, GroupName, FunctionId, FunctionName, [Priority]) 
VALUES (1, 'ByFlow', 3, 'Daily', 200)
GO

-- #6.  Add Column
ALTER TABLE [dbo].[CustomerClassification_BySport_Rule]
ADD IsProbationLastDay BIT DEFAULT(0);
GO

UPDATE [dbo].[CustomerClassification_BySport_Rule]
SET IsProbationLastDay = 1
WHERE RuleId IN (85,86,88,87,101,102,136,134,133,135,257,264);

-- #7. Grant permissions
GRANT SELECT ON [dbo].[CustomerClassification_BySport_NormalPool] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_NormalPool] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_BySport_ScannedDailyCust] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_ScannedDailyCust] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_BySport_Log] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_Log] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_BySport_RealtimeChanges] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_RealtimeChanges] TO [bodbSPUNet]
GO

GRANT SELECT ON [dbo].[CustomerClassification_BySport_Priority] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CustomerClassification_BySport_Priority] TO [bodbSPUNet]
GO