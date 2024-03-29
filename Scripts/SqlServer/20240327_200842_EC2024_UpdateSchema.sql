/*<info serverAlias="DBVR2-bodb_VR2Model" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20240327@Jonas.Huynh
    Task:	 	EC2024 - Resolve Locking [Redmine ID: #200842]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #1. ADD NEW COLUMN
ALTER TABLE [dbo].[CustomerClassification]
ADD [RowVersion] ROWVERSION NOT NULL;
GO

ALTER TABLE [dbo].[CustomerClassification_BySport]
ADD [RowVersion] ROWVERSION NOT NULL;
GO

-- #2. DROP INDEXES
DROP INDEX [CIX_CustomerClassification_IsApplied_Id] ON [dbo].[CustomerClassification];
DROP INDEX [IX_CustomerClassification_CreatedDate] ON [dbo].[CustomerClassification];
DROP INDEX [IX_CustomerClassification_CustIdSportIdCategoryId] ON [dbo].[CustomerClassification];
DROP INDEX [IX_CustomerClassification_Id] ON [dbo].[CustomerClassification];
GO

DROP INDEX [CIX_CustomerClassification_BySport_IsApplied_Id] ON [dbo].[CustomerClassification_BySport];
GO

-- #3. CREATE NEW INDEXES
ALTER TABLE [dbo].[CustomerClassification]
ADD CONSTRAINT [PK_CustomerClassification] PRIMARY KEY (ID);
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_RowVersion] ON [dbo].[CustomerClassification]
(
	[RowVersion]
);
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_RowVersion] ON [dbo].[CustomerClassification_BySport]
(
	[RowVersion]
);
GO

-- #7. Add System Parameter
DECLARE @GeneralValue BIGINT;
DECLARE @BysportValue BIGINT;

SELECT @GeneralValue = CAST(MAX([RowVersion]) AS BIGINT) FROM dbo.CustomerClassification WITH(NOLOCK);
SELECT @BysportValue = CAST(MAX([RowVersion]) AS BIGINT) FROM dbo.CustomerClassification_BySport WITH(NOLOCK);

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (1, 'Normal Accounts Classification - General - Lastest Scan Rowversion', 'ROWVERSION', CONVERT(VARCHAR(200), @GeneralValue));

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (2, 'Normal Accounts Classification - BySport - Lastest Scan Rowversion', 'ROWVERSION', CONVERT(VARCHAR(200), @BysportValue));
GO