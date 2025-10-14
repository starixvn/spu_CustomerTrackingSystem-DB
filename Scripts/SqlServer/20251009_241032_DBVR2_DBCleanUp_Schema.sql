/*<info serverAlias="DBVR2-bodb_VR2Model" databaseType="1"></info>*/
/*
Creator:	20251009@Thomas.Nguyen
Task:	 	DB CleanUp Schema
Server:  	DBVR2
DBName:		bodb_VR2Model

Revisions: 
		- 20251009@Thomas.Nguyen: Created [Redmine ID: #241032]
Reviewer:
*/

USE bodb_VR2Model;
GO
DROP PROCEDURE IF EXISTS CustomerClassification_CategorizeCustomer;
DROP PROCEDURE IF EXISTS CustomerClassification_CategorizeCustomer_Daily;
DROP PROCEDURE IF EXISTS CustomerClassification_CategorizeCustomer_RealTime;
DROP PROCEDURE IF EXISTS CustomerClassification_CategorizeCustomer_RealTime_CheckChanges;
DROP PROCEDURE IF EXISTS CustomerClassification_GetNewClassification;
DROP PROCEDURE IF EXISTS CustomerClassification_InitData;
DROP PROCEDURE IF EXISTS CustomerClassification_UpdateNewClassification;

DROP PROCEDURE IF EXISTS CustomerClassification_CategorizeCustomer_xtest;
DROP PROCEDURE IF EXISTS CustomerClassification_CategorizeCustomer_Daily_xtest;
DROP PROCEDURE IF EXISTS CustomerClassification_CategorizeCustomer_RealTime_xtest;
DROP PROCEDURE IF EXISTS CustomerClassification_CategorizeCustomer_RealTime_CheckChanges_xtest;
DROP PROCEDURE IF EXISTS CustomerClassification_GetNewClassification_xtest;
DROP PROCEDURE IF EXISTS CustomerClassification_InitData_xtest;
DROP PROCEDURE IF EXISTS CustomerClassification_UpdateNewClassification_xtest;

DROP PROCEDURE IF EXISTS CTS_CustomerClassification_CheckNewGroupBetting;
DROP PROCEDURE IF EXISTS CTS_GeneralNormalClassification_TWGroupBetting_Preprocess;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GeneralCategorize_InitData;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GetAccummulatedInfo;
DROP PROCEDURE IF EXISTS CustomerClassification_UpdateLastScanTime;

DROP PROCEDURE IF EXISTS CTS_CustomerClassification_CheckNewGroupBetting_xtest;
DROP PROCEDURE IF EXISTS CTS_GeneralNormalClassification_TWGroupBetting_Preprocess_xtest;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GeneralCategorize_InitData_xtest;
DROP PROCEDURE IF EXISTS CTS_NormalAccountsClassification_GetAccummulatedInfo_xtest;
DROP PROCEDURE IF EXISTS CustomerClassification_UpdateLastScanTime_xtest;