/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20241226@Jonas.Huynh
    Task:	 	HF Incorrect CC  [Redmine ID: #214058]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #1. Insert new system parameter

INSERT INTO [dbo].[CustomerClassification_Parameter] ([DataId], [DataDescription], [DataType], [Value]) 
VALUES (3, 'Normal Accounts Classification - General - LastScannedID', 'BIGINT','0');
GO

DECLARE @LastScannedRow				ROWVERSION;
DECLARE @LastScannedID				BIGINT;

DECLARE @GENERAL_LASTSCANNEDROW		TINYINT = 1;
DECLARE @GENERAL_LASTSCANNEDID		TINYINT = 3;

SELECT @LastScannedRow = CAST(CAST([Value] AS BIGINT) AS ROWVERSION) 
FROM dbo.CustomerClassification_Parameter WITH(NOLOCK) 
WHERE [DataId] = @GENERAL_LASTSCANNEDROW;

SELECT @LastScannedID = ID
FROM [dbo].[CustomerClassification] WITH(NOLOCK)
WHERE [RowVersion] = @LastScannedRow;

UPDATE [dbo].[CustomerClassification_Parameter]
SET [Value] = @LastScannedID
WHERE [DataId] = @GENERAL_LASTSCANNEDID;
GO

