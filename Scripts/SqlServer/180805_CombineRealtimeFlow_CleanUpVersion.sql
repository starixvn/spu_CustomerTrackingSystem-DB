/*<info serverAlias="DBCTS-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20221125@Jonas.Huynh
    Task:	 	Combine Realtime Flow of General CC and By Sport [Redmine ID: #180805]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- #1. Delete unused system parameter
DELETE r WITH(ROWLOCK)
FROM [dbo].[CustomerClassification_Parameter] as r
WHERE r.DataId in (1, 2, 3, 4);
GO

-- #2. Remove unused SPs
DROP PROCEDURE [dbo].[CTS_NormalAccountsClassification_BySport_RealTime_CheckChanges];
GO

DROP PROCEDURE [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_RealTime_CheckChanges]; 
GO

DROP PROCEDURE [dbo].[CTS_NormalAccountsClassification_UpdateLastScanTime]; 
GO

DROP PROCEDURE [dbo].[CTS_NormalAccountsClassification_BySport_Realtime_UpdateLastScanTime]; 
GO

-- #3. Remove unused tables
DROP TABLE [dbo].[CustomerClassification_LatestGeneralChanged];
GO
