INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'zzzzz_Job_Monitoring_Trigger',
'zzzzz_Job_Monitoring',
1,
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Monitoring_Secondly_NewCustomer_Trigger',
'CTS_Monitoring_Secondly_NewCustomer',
1,
'Simple',
5,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Monitoring_Minutely_ReactivatedCustomer_Trigger',
'CTS_Monitoring_Minutely_ReactivatedCustomer',
'Simple',
600,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Monitoring_Minutely_CustomerInfo_Trigger',
'CTS_Monitoring_Minutely_CustomerInfo',
'Simple',
5,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Monitoring_Minutely_RealtimeClassification_Trigger',
'CTS_Monitoring_Minutely_RealtimeClassification',
'Simple',
900,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Monitoring_Minutely_NormalPools_Trigger',
'CTS_Monitoring_Minutely_NormalPools',
'Simple',
900,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Monitoring_Minutely_IncorrectDataNotification_Trigger',
'CTS_Monitoring_Minutely_IncorrectDataNotification',
'Simple',
900,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Monitoring_Minutely_LastLoginTransactionProcess_Trigger',
'CTS_Monitoring_Minutely_LastLoginTransactionProcess',
'Simple',
900,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Transform_Secondly_Account_Trigger',
'CTS_Transform_Secondly_Account',
'Cron',
NULL,
'0/30 * * * * ?',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Secondly_LiveTicketDetailInsert_Trigger',
'CTS_MatchMonitor_Secondly_LiveTicketDetailInsert',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveTicketDetailInsert_Trigger',
'CTS_MatchMonitor_Minutely_NonLiveTicketDetailInsert',
'Simple',
270,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Secondly_LiveRuleGroupBettingInsert_Trigger',
'CTS_MatchMonitor_Secondly_LiveRuleGroupBettingInsert',
'Simple',
5,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveRuleGroupBettingInsert_Trigger',
'CTS_MatchMonitor_Minutely_NonLiveRuleGroupBettingInsert',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Secondly_LiveRuleSabaGroupBettingInsert_Trigger',
'CTS_MatchMonitor_Secondly_LiveRuleSabaGroupBettingInsert',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveRuleSabaGroupBettingInsert_Trigger',
'CTS_MatchMonitor_Minutely_NonLiveRuleSabaGroupBettingInsert',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Secondly_LiveRuleFixedGameInsert_Trigger',
'CTS_MatchMonitor_Secondly_LiveRuleFixedGameInsert',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveRuleFixedGameInsert_Trigger',
'CTS_MatchMonitor_Minutely_NonLiveRuleFixedGameInsert',
'Simple',
300,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Secondly_LiveRuleHedgingInsert_Trigger',
'CTS_MatchMonitor_Secondly_LiveRuleHedgingInsert',
'Simple',
5,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveRuleHedgingInsert_Trigger',
'CTS_MatchMonitor_Minutely_NonLiveRuleHedgingInsert',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Secondly_NonLiveRuleIrrigationInsert_Trigger',
'CTS_MatchMonitor_Secondly_NonLiveRuleIrrigationInsert',
'Simple',
300,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveRuleArbitrageInsert_Trigger',
'CTS_MatchMonitor_Minutely_NonLiveRuleArbitrageInsert',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitorParlay_Secondly_LiveTicketDetailInsert_Trigger',
'CTS_MatchMonitorParlay_Secondly_LiveTicketDetailInsert',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitorParlay_Minutely_NonLiveTicketDetailInsert_Trigger',
'CTS_MatchMonitorParlay_Minutely_NonLiveTicketDetailInsert',
'Simple',
270,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitorParlay_Secondly_LiveRuleGroupBettingInsert_Trigger',
'CTS_MatchMonitorParlay_Secondly_LiveRuleGroupBettingInsert',
'Simple',
5,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitorParlay_Minutely_NonLiveRuleGroupBettingInsert_Trigger',
'CTS_MatchMonitorParlay_Minutely_NonLiveRuleGroupBettingInsert',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Transform_Minutely_UserPermissionUpdate_Trigger',
'CTS_Transform_Minutely_UserPermissionUpdate',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Transform_Secondly_AssociationByDevice_Trigger',
'CTS_Transform_Secondly_AssociationByDevice',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Transform_Secondly_AffectedEvidence_Trigger',
'CTS_Transform_Secondly_AffectedEvidence',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Archive_Secondly_CustomerArchive_Trigger',
'CTS_Archive_Secondly_CustomerArchive',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Archive_Secondly_ArchiveCreditCustMissing_Trigger',
'CTS_Archive_Secondly_ArchiveCreditCustMissing',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Archive_Secondly_ArchiveDepositCustMissing_Trigger',
'CTS_Archive_Secondly_ArchiveDepositCustMissing',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_AffectedEvidence_Secondly_InsertFromQueue_Trigger',
'CTS_AffectedEvidence_Secondly_InsertFromQueue',
'Simple',
15,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_AffectedEvidence_Secondly_RemoveFromQueue_Trigger',
'CTS_AffectedEvidence_Secondly_RemoveFromQueue',
'Simple',
15,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Archive_Secondly_HistoryClassification_Trigger',
'CTS_Archive_Secondly_HistoryClassification',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Archive_Secondly_HistoryClassificationBySport_Trigger',
'CTS_Archive_Secondly_HistoryClassificationBySport',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Archive_Secondly_CustomerAssociation_Trigger',
'CTS_Archive_Secondly_CustomerAssociation',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Archive_Secondly_CustomerAssociationRollback_Trigger',
'CTS_Archive_Secondly_CustomerAssociationRollback',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Daily_NormalAccountScan_Trigger',
'CTS_CustomerClassification_Daily_NormalAccountScan',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Daily_NormalTaggingScan_Trigger',
'CTS_CustomerClassification_Daily_NormalTaggingScan',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Daily_ProblemAccountScan_Trigger',
'CTS_CustomerClassification_Daily_ProblemAccountScan',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_RealtimeCheckChanges_Trigger',
'CTS_CustomerClassification_Secondly_RealtimeCheckChanges',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_RealtimeScan_Trigger',
'CTS_CustomerClassification_Secondly_RealtimeScan',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_NormalAccountClassification_Trigger',
'CTS_CustomerClassification_Secondly_NormalAccountClassification',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_NormalAccountInsert_Trigger',
'CTS_CustomerClassification_Secondly_NormalAccountInsert',
'Simple',
3,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Daily_ProbationScan_Trigger',
'CTS_CustomerClassification_Daily_ProbationScan',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Minutely_RobotTWScan_Trigger',
'CTS_CustomerClassification_Minutely_RobotTWScan',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Customer_Secondly_NewCustomerInsert_Trigger',
'CTS_Customer_Secondly_NewCustomerInsert',
'Simple',
2,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Customer_Secondly_InsertMissingCustomer_Trigger',
'CTS_Customer_Secondly_InsertMissingCustomer',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Customer_Secondly_CustomerInfoUpdate_Trigger',
'CTS_Customer_Secondly_CustomerInfoUpdate',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Customer_Secondly_Username2ForCustMainUpdate_Trigger',
'CTS_Customer_Secondly_Username2ForCustMainUpdate',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Customer_Hourly_Username2ForCustSubUpdate_Trigger',
'CTS_Customer_Hourly_Username2ForCustSubUpdate',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Customer_Hourly_Username2Update_Trigger',
'CTS_Customer_Hourly_Username2Update',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_Customer_Minutely_ReactivatedCustomerInsert_Trigger',
'CTS_Customer_Minutely_ReactivatedCustomerInsert',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Daily_NewCustomerInactive_Trigger',
'CTS_CustomerClassification_Daily_NewCustomerInactive',
'Cron',
NULL,
'0 0 21 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_TWGroupBetting_Minutely_ScanTicket_Trigger',
'CTS_TWGroupBetting_Minutely_ScanTicket',
'Simple',
300,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_TWGroupBetting_Minutely_CountTotalTicket_Trigger',
'CTS_TWGroupBetting_Minutely_CountTotalTicket',
'Simple',
300,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_AffectedDownlineFromQueue_Trigger',
'CTS_CustomerClassification_Secondly_AffectedDownlineFromQueue',
'Simple',
1,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_NewCustomerClassify_Trigger',
'CTS_CustomerClassification_Secondly_NewCustomerClassify',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_RobotAI_Minutely_Classification_Trigger',
'CTS_RobotAI_Minutely_Classification',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_TVSProblemAccountInsert_Trigger',
'CTS_CustomerClassification_Secondly_TVSProblemAccountInsert',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_MatchMonitor_Minutely_StatusUpdate_Trigger',
'CTS_MatchMonitor_Minutely_StatusUpdate',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_MatchMonitorGBClassify_Trigger',
'CTS_CustomerClassification_Secondly_MatchMonitorGBClassify',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_SabaDangerLevel_Secondly_ByProblemAccountUpdate_Trigger',
'CTS_SabaDangerLevel_Secondly_ByProblemAccountUpdate',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassificationBySport_Secondly_NormalAccountInsert_Trigger',
'CTS_CustomerClassificationBySport_Secondly_NormalAccountInsert',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassificationBySport_Secondly_NormalAccountClassification_Trigger',
'CTS_CustomerClassificationBySport_Secondly_NormalAccountClassification',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassificationBySport_Daily_NormalAccountScan_Trigger',
'CTS_CustomerClassificationBySport_Daily_NormalAccountScan',
'Cron',
NULL,
'0 0 6 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassificationBySport_Daily_ProbationScan_Trigger',
'CTS_CustomerClassificationBySport_Daily_ProbationScan',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassificationBySport_Secondly_RealtimeScan_Trigger',
'CTS_CustomerClassificationBySport_Secondly_RealtimeScan',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_AssociationAccountScan_Trigger',
'CTS_CustomerClassification_Secondly_AssociationAccountScan',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Daily_DetectUnauthorizedLogin_Credit_Trigger',
'CTS_CustomerClassification_Daily_DetectUnauthorizedLogin_Credit',
'Cron',
NULL,
'0 0 20 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Daily_DetectUnauthorizedLogin_Licensee_Trigger',
'CTS_CustomerClassification_Daily_DetectUnauthorizedLogin_Licensee',
'Cron',
NULL,
'0 0 20 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Daily_DangerousScoreToCCScan_Deposit_Trigger',
'CTS_CustomerClassification_Daily_DangerousScoreToCCScan_Deposit',
'Cron',
NULL,
'0 0 6 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Daily_DangerousScoreToCCScan_Credit_Trigger',
'CTS_CustomerClassification_Daily_DangerousScoreToCCScan_Credit',
'Cron',
NULL,
'0 0 3 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_TWInitialGBToCCScan_Trigger',
'CTS_CustomerClassification_Secondly_TWInitialGBToCCScan',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Minutely_TWInitialSmartToCCScan_Trigger',
'CTS_CustomerClassification_Minutely_TWInitialSmartToCCScan',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_NormalDangerousAssociationCheck_Trigger',
'CTS_CustomerClassification_Secondly_NormalDangerousAssociationCheck',
'Simple',
7,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassification_Secondly_NormalDangerousAssociationScan_Trigger',
'CTS_CustomerClassification_Secondly_NormalDangerousAssociationScan',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'FS_BigStateNearGoal_Trigger',
'FS_BigStateNearGoal',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'FS_CheckBet_Trigger',
'FS_CheckBet',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'FS_ScannedOfficeIp_Trigger',
'FS_ScannedOfficeIp',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'FS_DelayGoal_Trigger',
'FS_DelayGoal',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'FS_DailyCaptureData_Trigger',
'FS_DailyCaptureData',
'Cron',
NULL,
'0 0 0 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'FS_FlaggedAccount_Trigger',
'FS_FlaggedAccount',
'Simple',
60,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'VR_BetLimit_Trigger',
'VR_BetLimit',
'Cron',
NULL,
'0 0 17 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'VR_SpecialLicensee_Trigger',
'VR_SpecialLicensee',
'Cron',
NULL,
'0 0 17 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'VR_AdjustVRSetting_Trigger',
'VR_AdjustVRSetting',
'Cron',
NULL,
'0 15 0 * * ?',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'VR_Agent_Trigger',
'VR_Agent',
'Cron',
NULL,
'0 0 17 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'VR_MemberBigStake_Trigger',
'VR_MemberBigStake',
'Cron',
NULL,
'0 0 21 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'VR_SabaDangerLevel_Hourly_ByWinlossUpdate_Trigger',
'VR_SabaDangerLevel_Hourly_ByWinlossUpdate',
'Cron',
NULL,
'0 0 1/3 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'AFC_B2CAccount_Daily_Update_Trigger',
'AFC_B2CAccount_Daily_Update',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'NotificationMonitor_Trigger',
'NotificationMonitor',
'Cron',
NULL,
'0 0 04 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassificationAgency_Secondly_RealtimeScan_Trigger',
'CTS_CustomerClassificationAgency_Secondly_RealtimeScan',
'Simple',
30,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassificationAgency_Daily_NormalAccountScan_Trigger',
'CTS_CustomerClassificationAgency_Daily_NormalAccountScan',
'Cron',
NULL,
'0 0 7 1/1 * ? *',
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassificationAgency_Secondly_NormalAccountClassification_Trigger',
'CTS_CustomerClassificationAgency_Secondly_NormalAccountClassification',
'Simple',
10,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassificationAgency_Secondly_NormalAccountInsert_Trigger',
'CTS_CustomerClassificationAgency_Secondly_NormalAccountInsert',
'Simple',
3,
NULL,
false);

INSERT INTO CTS_Admin.CTSTrigger (TriggerName, JobName, EnvironmentID, TriggerType, IntervalInSecond, CronExpression, IsDisable) VALUES (
'CTS_CustomerClassificationAgency_Daily_NewCustomerInactive_Trigger',
'CTS_CustomerClassificationAgency_Daily_NewCustomerInactive',
'Cron',
NULL,
'0 0 22 1/1 * ? *',
false);



