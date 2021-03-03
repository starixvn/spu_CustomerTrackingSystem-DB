/*<info serverAlias="CTSMain-MonDB" databaseType="2"></info>*/
/*
	Created: 20210303@Aries.Nguyen
	Task: 	 Create schema [Redmine ID: #149662]
	DB: 	 MonDB
*/

USE MonDB;
CREATE TABLE `DBA_SPMonitor` (
   `RowID` bigint unsigned NOT NULL AUTO_INCREMENT,
   `Database` varchar(64) DEFAULT NULL,
   `GroupID` int DEFAULT NULL,
   `Name` varchar(64) DEFAULT NULL,
   `Type` varchar(64) DEFAULT NULL,
   `Count_Star` bigint unsigned DEFAULT NULL,
   `Count_Star_Flag` bigint unsigned DEFAULT NULL,
   `Sum_Errors` bigint unsigned DEFAULT NULL,
   `Sum_Errors_Flag` bigint unsigned DEFAULT NULL,
   `Sum_Warnings` bigint unsigned DEFAULT NULL,
   `Sum_Warnings_Flag` bigint unsigned DEFAULT NULL,
   `Sum_Rows_Affected` bigint unsigned DEFAULT NULL,
   `Sum_Rows_Affected_Flag` bigint unsigned DEFAULT NULL,
   `Sum_Rows_Sent` bigint unsigned DEFAULT NULL,
   `Sum_Rows_Sent_Flag` bigint unsigned DEFAULT NULL,
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`RowID`),
   KEY `IX_SPMonitor_Created` (`Created` DESC)
) ENGINE=InnoDB AUTO_INCREMENT=0;


USE MonDB;
CREATE TABLE `DBA_CTS_DataFlow_Monitor` (
   `SPName` varchar(64) NOT NULL,
   `GroupID` int NOT NULL,
   `GroupName` varchar(50) DEFAULT NULL,
   PRIMARY KEY (`SPName`),
   KEY `GroupID` (`GroupID`)
 ) ENGINE=InnoDB;



INSERT IGNORE INTO `DBA_CTS_DataFlow_Monitor` 
VALUES ('CTS_DC_CTSCustomer_GetInfoByCustIDList',4,'Customer'),
('CTS_DC_CTSCustomer_GetLastInsertCust',4,'Customer'),
('CTS_DC_CTSCustomer_GetLastUpdateTime',4,'Customer'),
('CTS_DC_CTSCustomer_GetNULLUserName2',4,'Customer'),
('CTS_DC_CTSCustomer_Insert',4,'Customer'),
('CTS_DC_CTSCustomer_UpdateCustInfoComplete',4,'Customer'),
('CTS_DC_CTSCustomer_UpdateCustomerComplete',4,'Customer'),
('CTS_DC_CTSCustomer_UpdateUserName2',4,'Customer'),
('CTS_DC_CustClassification_GetLatestClassification',2,'CustomerClassification_Common'),
('CTS_DC_CustClassification_GetTaggingByAssociationWithPA',8,'CustomerClassification_AutoTagNormal'),
('CTS_DC_CustClassification_Probation_GetCustForScanning',5,'Probation'),
('CTS_DC_CustClassification_Probation_UpdateLastScanDate',5,'Probation'),
('CTS_DC_CustClassification_UpdateIsAppliedCC',2,'CustomerClassification_Common'),
('CTS_DC_CustEvidence_ClearEvidence',7,'RemoveMutilpleEvidence'),
('CTS_DC_CustEvidence_GetExistedEvidencesToSync',7,'RemoveMutilpleEvidence'),
('CTS_DC_CustEvidence_InsertMultilpleEvidencesForCustomers',3,'Evidence'),
('CTS_DC_CustEvidence_InsertMultiple',3,'Evidence'),
('CTS_DC_CustEvidence_InsertSingle',3,'Evidence'),
('CTS_DC_CustEvidence_RemoveOldEvidenceForInsertMultiple',3,'Evidence'),
('CTS_DC_CustEvidence_SyncToCategory',11,'CustomerClassification_ProblemAccount'),
('CTS_DC_CustEvidence_ValidateMultipleInput',3,'Evidence'),
('CTS_DC_CustEvidenceFromFile_Get',3,'Evidence'),
('CTS_DC_CustEvidenceFromFile_UpdateProcessed',3,'Evidence'),
('CTS_DC_CustEvidenceQueue_Get',7,'RemoveMutilpleEvidence'),
('CTS_DC_CustEvidenceQueue_Insert',7,'RemoveMutilpleEvidence'),
('CTS_DC_CustEvidenceQueue_Update',7,'RemoveMutilpleEvidence'),
('CTS_DC_GetCustomerClassificationByCategory',9,'CustomerClassification_RealTimeNormal'),
('CTS_DC_InsertCategorizedProblemAccounts',11,'CustomerClassification_ProblemAccount'),
('CTS_DC_InsertMainCustomerClassification',8,'CustomerClassification_AutoTagNormal'),
('CTS_DC_Notification_InsertProbationNotification',5,'Probation'),
('CTS_DC_SpecialCustClass_InsertRobotUsers',6,'RobotUser'),
('CTS_DC_Task_CountAssociatedAccountNewAssociation',1,'Transaction'),
('CTS_DC_Task_TransformAccountAssociationToCTSRetry',1,'Transaction'),
('CTS_DC_TransformAssociationByDevice',1,'Transaction'),
('CTS_DC_TransformDCSAccountToCTSCustomer',1,'Transaction'),
('DCS_DC_Transaction_GetHistory',1,'Transaction'),
('DCS_DC_TransformData_Device_Insert',1,'Transaction'),
('DCS_DC_TransformData_Device_Transaction_GetPackage',1,'Transaction'),
('DCS_DC_TransformData_Transaction_Insert',1,'Transaction'),
('DCS_DC_TransformData_UnhandleSubscriberAction',1,'Transaction'),
('DCS_DC_TransformData_UserAgent_GetNullBrowserOSList',1,'Transaction'),
('DCS_DC_TransformData_UserAgent_Insert',1,'Transaction'),
('DCS_DC_TransformData_UserAgent_UpdateOSBrowser',1,'Transaction'),
('DCS_DC_TransformToCTS_Account_Completed',1,'Transaction'),
('DCS_DC_TransformToCTS_Account_GetPackage',1,'Transaction'),
('DCS_DC_TransformToCTS_Association_GetPackage',1,'Transaction'),
('DCS_RT_RawTrans_Insert',1,'Transaction'),
('DCS_ST_TransformData_GetPackage',1,'Transaction'),
('DCS_Task_RawTransaction_Cleanup',1,'Transaction'),
('DBA_Monitor_SPMetric_Insert',12,'DBAMonitor'),
('DBA_Replication_Status_Monitor',12,'DBAMonitor'),
('grafana_Transaction_Metric_Insert',12,'DBAMonitor'),
('grafana_Transaction_Metric_Select',12,'DBAMonitor'),
('Others',0,'Others');









