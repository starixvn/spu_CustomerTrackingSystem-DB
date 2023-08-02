/*
    Creator: 	20230726@Jonas.Huynh
    Task:	 	Saba Classification [Redmine ID: #185320]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

-- DROP SPs
DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BetCount_Update;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_Daily;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_GetNewClassification;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_Probation;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_RealTime_GetChanges;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_RealTime;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_UpdateAppliedStatus;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BetCount_Update_xtest;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_Daily_xtest;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_GetNewClassification_xtest;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_Probation_xtest;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_RealTime_GetChanges_xtest;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_RealTime_xtest;

DROP PROCEDURE IF EXISTS dbo.CTS_NormalAccountsClassification_BySport_UpdateAppliedStatus_xtest;

-- DROP Table
--DROP TABLE IF EXISTS dbo.CustomerClassification_BySport_InputLog;

--DROP TABLE IF EXISTS dbo.CustomerClassification_BySport_LatestChanged;