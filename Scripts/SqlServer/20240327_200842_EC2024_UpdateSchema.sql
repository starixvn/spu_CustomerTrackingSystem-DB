/*<info serverAlias="DBVR2-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20240327@Jonas.Huynh
    Task:	 	EC2024 - Resolve Locking [Redmine ID: #200842]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #1. General - Add new column
ALTER TABLE [dbo].[CustomerClassification]
ADD [RowVersion] ROWVERSION;
GO

-- #2. General - DROP INDEXES
DROP INDEX [CIX_CustomerClassification_IsApplied_Id] ON [dbo].[CustomerClassification];
DROP INDEX [IX_CustomerClassification_CreatedDate] ON [dbo].[CustomerClassification];
DROP INDEX [IX_CustomerClassification_CustId] ON [dbo].[CustomerClassification];
DROP INDEX [IX_CustomerClassification_Id] ON [dbo].[CustomerClassification];
GO

-- #3. General - CREATE NEW INDEXES
ALTER TABLE [dbo].[CustomerClassification]
ADD CONSTRAINT [PK_CustomerClassification] PRIMARY KEY (ID);
GO

CREATE NONCLUSTERED INDEX [IX_CustomerClassification_RowVersion] ON [dbo].[CustomerClassification]
(
	[RowVersion]
);
GO

-- #4. BySport - Add new column
ALTER TABLE [dbo].[CustomerClassification_BySport]
ADD [RowVersion] ROWVERSION;
GO

-- #5. BySport - DROP INDEXES
DROP INDEX [CIX_CustomerClassification_BySport_IsApplied_Id] ON [dbo].[CustomerClassification_BySport];
DROP INDEX [IX_CustomerClassification_BySport_CustIdSportId] ON [dbo].[CustomerClassification_BySport];
GO

-- #6. BySport - CREATE NEW INDEXES
CREATE NONCLUSTERED INDEX [IX_CustomerClassification_BySport_RowVersion] ON [dbo].[CustomerClassification_BySport]
(
	[RowVersion]
);

-- #7. Add System Parameter
DECLARE @GeneralValue VARCHAR(200);
DECLARE @BysportValue VARCHAR(200);

SELECT @GeneralValue = MAX([RowVersion]) FROM dbo.CustomerClassification WITH(NOLOCK);
--SELECT @BysportValue = MAX([RowVersion]) FROM dbo.CustomerClassification_BySport WITH(NOLOCK);

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (1, 'Normal Accounts Classification - General - Lastest Scan Rowversion', 'ROWVERSION', @GeneralValue);
GO

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (2, 'Normal Accounts Classification - BySport - Lastest Scan Rowversion', 'ROWVERSION', @BysportValue);
GO


select * from [dbo].[CustomerClassification_Parameter]