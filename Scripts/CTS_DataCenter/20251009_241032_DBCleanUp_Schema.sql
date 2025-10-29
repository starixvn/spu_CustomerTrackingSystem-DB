/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20251009@Thomas.Nguyen
Task:	 	DB CleanUp Schema
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20251009@Thomas.Nguyen: Created [Redmine ID: #241032]
		- 20251014@Logan.Nguyen: Remove SystemParameter [Redmine ID: #241032]
Reviewer:
*/

USE CTS_DataCenter;

/********************* Remove unused tables *********************/
ALTER TABLE AssociatedAccountMonitor RENAME TO DLE_AssociatedAccountMonitor;
ALTER TABLE CustEvidenceFromFile RENAME TO DLE_CustEvidenceFromFile;
ALTER TABLE CustEvidenceLog RENAME TO DLE_CustEvidenceLog;
ALTER TABLE CustEvidenceQueue RENAME TO DLE_CustEvidenceQueue;
ALTER TABLE SmartGroupHistory RENAME TO DLE_SmartGroupHistory;

/********************* Correct Parameter Name *********************/
UPDATE SystemParameter
SET ParameterName = 'ClassificationDangerousScoreDeposit_LastCustID'
WHERE ParameterID = 157;

UPDATE SystemParameter
SET ParameterName = 'ClassificationDangerousScoreDeposit_BatchSize'
WHERE ParameterID = 158;

/********************* Remove unused procedures *********************/
/********************* CTS_DataCenter *********************/
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AddManualAssociation;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_Get;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_Insert;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_Remove;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_ValidateInput;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_VerifyPin;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociationDetection_Agent_DetectGroup;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociationGroupByAI_MergeGroup;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_CountByCategoryID;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_DeviceAssociationDay_Insert;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_Device_Insert;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_Get;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_GetByCustList;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_GetCleanAssociatedCustExceptAEvidence;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_GetWithCategory;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AutoTagCustomerClassification;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_DELETEHaifaCustomer;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_GetBABySiteName;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_GetLastInsertCust;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_GetNULLUserName2;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_Insert;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_InsertComplete;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateCustInfoComplete;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateCustomerComplete;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateInfoComplete;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateSubscriberSite_Haifa_BBIN;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateUserName2;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Common_GetAllSportGroups;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Common_GetCustomerGroup;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_DailyScan_UpdateStatus;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_History_CleanUp;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_History_DataUnChanged_CleanUp;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_InitialSmart_Get;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_UpdateCustInfo;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_UpdateDangerLevel;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceFromFile_Get;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceFromFile_Insert;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceFromFile_UpdateProcessed;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceFromFile_UpdateStatus;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceQueue_Get;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceQueue_Insert;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceQueue_RollbackRemovedEvidences;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceQueue_TakeAction;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceQueue_Update;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidence_InsertSingle;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidence_RemoveAllEvidenceByCTSCustIDs;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidence_RemoveOldEvidenceForInsertMultiple;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidence_ValidateMultipleInput;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_CheckCategoryInfoNewCust;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_FilterCustIDsBySite;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_GetCustomerRoles;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_RobotUser_CheckSiteByCustIds;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetAllSpecialCustomerClass;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustEvidenceByEvidenceID;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustIDsByAssociationDeviceCSTCustID;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerByUsername;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerForUpdateUsername2;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetDirectAssociatedAccount_TagAffected;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetEvidenceByCustID;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetLatestUpdatedDate_IPRange;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetMaxCustIdCTSCustomer;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetSystemParameterById;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_HealingCTSCustomer;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertAssociation;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertCTSCustomer;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertCustDCSAccount;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertEvidence;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertIPRangeLocation;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertUserPermission;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_MatchMonitor_DetectGroup;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_MatchMonitor_RuleLopsidedBetting_Complete;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_MatchMonitor_UpdateVerify;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_MissingCustomer_Complete;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_MissingCustomer_Get;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_ProblemAccountManagement_Evidence_Remove;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RobotClassification_GetLastest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RobotClassification_Insert;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RobotClassification_Scan;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RobotImperva_Insert;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RobotImperva_Transform_Update;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_SpecialCustClass_InitData;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_SpecialCustClass_InsertRobotUsers;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_SpecialCustomerClass_InsertRobotUsers;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TWProblemDetectionMonitor_Scan_Completed;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Task_CountAssociatedAccountNewAssociation;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Task_TransformAccountAssociationToCTSRetry;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformAssociationByDevice;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformAssociation_AffectedEvidence;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformCTSCustomerRetryManual;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformDCSAccountToCTSCustomer;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformDCSTransactionIPToCTSAssociationByIP;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformUpdateLastLoginTime;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_UpdateIPTableLog;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_UpdateSystemParameterById;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_UpdateUsername2;

/**********xtest**************/
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AddManualAssociation_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_Insert_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_Remove_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_ValidateInput_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociatedAccountMonitor_VerifyPin_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociationDetection_Agent_DetectGroup_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AssociationGroupByAI_MergeGroup_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_CountByCategoryID_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_DeviceAssociationDay_Insert_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_Device_Insert_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_GetByCustList_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_GetCleanAssociatedCustExceptAEvidence_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Association_GetWithCategory_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AutoTagCustomerClassification_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_DELETEHaifaCustomer_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_GetBABySiteName_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_GetLastInsertCust_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_GetNULLUserName2_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_Insert_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_InsertComplete_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateCustInfoComplete_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateCustomerComplete_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateInfoComplete_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateSubscriberSite_Haifa_BBIN_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateUserName2_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Common_GetAllSportGroups_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Common_GetCustomerGroup_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_DailyScan_UpdateStatus_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_History_CleanUp_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_History_DataUnChanged_CleanUp_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_InitialSmart_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_UpdateCustInfo_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustClassification_UpdateDangerLevel_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceFromFile_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceFromFile_Insert_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceFromFile_UpdateProcessed_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceFromFile_UpdateStatus_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceQueue_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceQueue_Insert_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceQueue_RollbackRemovedEvidences_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceQueue_TakeAction_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidenceQueue_Update_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidence_InsertSingle_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidence_RemoveAllEvidenceByCTSCustIDs_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidence_RemoveOldEvidenceForInsertMultiple_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidence_ValidateMultipleInput_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_CheckCategoryInfoNewCust_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_FilterCustIDsBySite_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_GetCustomerRoles_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustInfo_RobotUser_CheckSiteByCustIds_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetAllSpecialCustomerClass_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustEvidenceByEvidenceID_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustIDsByAssociationDeviceCSTCustID_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerByUsername_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustomerForUpdateUsername2_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetDirectAssociatedAccount_TagAffected_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetEvidenceByCustID_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetLatestUpdatedDate_IPRange_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetMaxCustIdCTSCustomer_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetSystemParameterById_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_HealingCTSCustomer_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertAssociation_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertCTSCustomer_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertCTSCustomer_xtest_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertCustDCSAccount_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertEvidence_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertIPRangeLocation_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertUserPermission_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_MatchMonitor_DetectGroup_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_MatchMonitor_RuleLopsidedBetting_Complete_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_MatchMonitor_UpdateVerify_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_MissingCustomer_Complete_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Monitoring_MissingCustomer_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_ProblemAccountManagement_Evidence_Remove_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RobotClassification_GetLastest_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RobotClassification_Insert_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RobotClassification_Scan_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RobotImperva_Insert_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_RobotImperva_Transform_Update_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_SpecialCustClass_InitData_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_SpecialCustClass_InsertRobotUsers_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_SpecialCustomerClass_InsertRobotUsers_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TWProblemDetectionMonitor_Scan_Completed_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Task_CountAssociatedAccountNewAssociation_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Task_TransformAccountAssociationToCTSRetry_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformAssociationByDevice_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformAssociation_AffectedEvidence_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformCTSCustomerRetryManual_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformDCSAccountToCTSCustomer_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformDCSTransactionIPToCTSAssociationByIP_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformUpdateLastLoginTime_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_UpdateIPTableLog_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_UpdateSystemParameterById_xtest;
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_UpdateUsername2_xtest;

/**********CTS_Admin**************/
DROP PROCEDURE IF EXISTS CTS_Admin.DCS_AD_InsertSubscriberByUser;
DROP PROCEDURE IF EXISTS CTS_Admin.DCS_AD_InsertSubscriberByUser_xtest;

/**********CTS_Log**************/
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_CTSCustomer_Get;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_InsertMissingCusts;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByAI_Get;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByAI_InsertMissing;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByDevice_Get;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByDevice_InsertMissing;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByIP_Get;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByIP_InsertMissing;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByManual_Get;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByManual_InsertMissing;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_CustClassification_Get;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_CustEvidence_Get;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_CustEvidence_InsertMissing;

DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_CTSCustomer_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_InsertMissingCusts_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByAI_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByAI_InsertMissing_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByDevice_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByDevice_InsertMissing_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByIP_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByIP_InsertMissing_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByManual_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_AssByManual_InsertMissing_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_CustClassification_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_CustEvidence_Get_xtest;
DROP PROCEDURE IF EXISTS CTS_Log.CTS_Log_Monitor_Neo4j_CustEvidence_InsertMissing_xtest;


/***************************** Remove unused SystemParameter *****************************/
CREATE TABLE CTS_DataCenter.Adhoc_241032_SystemParameter_BeforeRemove (
	ParameterID SMALLINT UNSIGNED NOT NULL,
	ParameterName VARCHAR(50) DEFAULT NULL,
	ParameterDesc VARCHAR(200) COLLATE DEFAULT NULL,
	ParameterDataType VARCHAR(50) COLLATE DEFAULT NULL,
	ParameterValue VARCHAR(200) COLLATE DEFAULT NULL,
	PRIMARY KEY (ParameterID) 
);

INSERT INTO CTS_DataCenter.Adhoc_241032_SystemParameter_BeforeRemove (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
SELECT ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue
FROM CTS_DataCenter.SystemParameter AS spt  
WHERE ParameterID IN (14, 21, 22, 23, 50, 51, 52, 68, 68, 71, 72, 73, 74,
						75, 77, 78, 82, 83, 90, 108, 109, 110, 111, 112,
						134, 135, 136, 141, 142, 170, 990, 991);
 
DELETE FROM CTS_DataCenter.SystemParameter 
WHERE ParameterID IN (14, 21, 22, 23, 50, 51, 52, 68, 68, 71, 72, 73, 74,
						75, 77, 78, 82, 83, 90, 108, 109, 110, 111, 112,
						134, 135, 136, 141, 142, 170, 990, 991);

/***************************** Remove unused procedures SPU_AIML *****************************/
USE SPU_AIML;
DROP PROCEDURE IF EXISTS SPU_AIML.SPU_AIML_OCRD_GetDetails;
DROP PROCEDURE IF EXISTS SPU_AIML.SPU_AIML_OCRD_GetMatchByCust;

DROP PROCEDURE IF EXISTS SPU_AIML.SPU_AIML_OCRD_GetDetails_xtest;
DROP PROCEDURE IF EXISTS SPU_AIML.SPU_AIML_OCRD_GetMatchByCust_xtest;