/*
    Creator: 	20230818@Jonas.Huynh
    Task:	 	Customer Classification Tagging [Redmine ID: #191400]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- DROP SPs
DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_GeneralCategorize_Probation;
DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_GeneralCategorize_Probation_xtest;

DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GeneralCategorize_Daily;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GeneralCategorize_Daily_xtest;

DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_BetCount_Update;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_BetCount_Update_xtest;

DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GetNewClassification;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GetNewClassification_xtest;

DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_UpdateAppliedStatus;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_UpdateAppliedStatus_xtest;

DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_RealTime_CheckChanges;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_RealTime_CheckChanges_xtest;

DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GeneralCategorize_RealTime_GetChanges;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GeneralCategorize_RealTime_GetChanges_xtest;

DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GeneralCategorize_RealTime;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GeneralCategorize_RealTime_xtest;

DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_Realtime_UpdateLastScan;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_Realtime_UpdateLastScan_xtest;

DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GeneralCategorize_InitData;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GeneralCategorize_InitData_xtest;

-- REMOVE Unused SystemParameters
DELETE t
FROM [dbo].[CustomerClassification_Parameter]
WHERE [DataId] IN (1, 2, 5, 6, 7, 8);

-- DROP Table
--DROP TABLE IF EXISTS dbo.CustomerClassification_InputLog;

--DROP TABLE IF EXISTS dbo.CustomerClassification_LatestChanged;