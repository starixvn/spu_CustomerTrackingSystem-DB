INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'zzzzz_Job_Monitoring',
'Monitoring',
1,
'Fanex.NAP.SPU.Main.Features.JobSchedulers.Services.JobMonitoring',
'zzzzz_Job_Monitoring',
'zzzzz_Job_Monitoring',
'zzzzz_Job_Monitoring',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Monitoring_Secondly_NewCustomer',
'Monitoring',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500&externalSize=5000&addMinute=15',
'NewCustomerMonitoring',
'JobMonitoring',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Monitoring_Minutely_ReactivatedCustomer',
'Monitoring',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500&addMinute=30',
'ReactivatedCustomerMonitoring',
'JobMonitoring',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Monitoring_Minutely_CustomerInfo',
'Monitoring',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'CustomerInfoMonitoring',
'JobMonitoring',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Monitoring_Minutely_RealtimeClassification',
'Monitoring',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'ReatimeCategoryMonitoring',
'JobMonitoring',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Monitoring_Minutely_NormalPools',
'Monitoring',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?threshold=500000',
'NormalPoolMonitoring',
'JobMonitoring',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Monitoring_Minutely_IncorrectDataNotification',
'Monitoring',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api',
'IncorrectDataMonitoringNotification',
'JobMonitoring',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Monitoring_Minutely_LastLoginTransactionProcess',
'Monitoring',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?threshold=50000',
'LastLoginTransactionMonitoring',
'monitoring',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Transform_Secondly_Account',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?size=500&numberOfBatch=2',
'TransformAccount',
'TransformJob',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Secondly_LiveTicketDetailInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?size=5000',
'MatchMonitorInsertTicketDetailLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveTicketDetailInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?size=5000',
'MatchMonitorInsertTicketDetailNonLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Secondly_LiveRuleGroupBettingInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberOfThread=6',
'MatchMonitorProcessRuleGroupBettingLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveRuleGroupBettingInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberOfThread=6',
'MatchMonitorProcessRuleGroupBettingNonLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Secondly_LiveRuleSabaGroupBettingInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberOfThread=4',
'MatchMonitorProcessRuleSabaGroupBettingLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveRuleSabaGroupBettingInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberOfThread=2',
'MatchMonitorProcessRuleSabaGroupBettingNonLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Secondly_LiveRuleFixedGameInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberOfThread=6',
'MatchMonitorProcessRuleFixedGameLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveRuleFixedGameInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberOfThread=6',
'MatchMonitorProcessRuleFixedGameNonLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Secondly_LiveRuleHedgingInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberInternalOfThread=2&numberExternalOfThread=12',
'MatchMonitorProcessRuleHedgingLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveRuleHedgingInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberInternalOfThread=2&numberExternalOfThread=12',
'MatchMonitorProcessRuleHedgingNonLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Secondly_NonLiveRuleIrrigationInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberOfThread=12',
'MatchMonitorProcessRuleIrrigationNonLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Minutely_NonLiveRuleArbitrageInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberOfThread=6',
'MatchMonitorProcessRuleArbitrageNonLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitorParlay_Secondly_LiveTicketDetailInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?size=5000',
'MatchMonitorParlayInsertTicketDetailLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitorParlay_Minutely_NonLiveTicketDetailInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?size=5000',
'MatchMonitorParlayInsertTicketDetailNonLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitorParlay_Secondly_LiveRuleGroupBettingInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberOfThread=6',
'MatchMonitorParlayProcessRuleGroupBettingLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitorParlay_Minutely_NonLiveRuleGroupBettingInsert',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?numberOfThread=6',
'MatchMonitorParlayProcessRuleGroupBettingNonLive',
'matchmonitor',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Transform_Minutely_UserPermissionUpdate',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api',
'SyncUserPermission',
'TransformJob',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Transform_Secondly_AssociationByDevice',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?batchSize=500&numberOfBatch=2',
'TransformAssByDevice',
'TransformJob',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Transform_Secondly_AffectedEvidence',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api',
'AffectedEvidence',
'TransformJob',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Archive_Secondly_CustomerArchive',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api?batchSize=5000',
'ArchiveCustomer',
'ArchiveData',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_AffectedEvidence_Secondly_InsertFromQueue',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api',
'AffectedEvidenceInsertFromQueue',
'job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_AffectedEvidence_Secondly_RemoveFromQueue',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api',
'AffectedEvidenceRemoveFromQueue',
'job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Archive_Secondly_HistoryClassification',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api',
'ArchiveHistoryClassification',
'ArchiveData',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Archive_Secondly_HistoryClassificationBySport',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api',
'ArchiveHistoryClassificationBySport',
'ArchiveData',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Archive_Secondly_CustomerAssociation',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api',
'ArchiveAssociationCustomer',
'ArchiveData',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Archive_Secondly_CustomerAssociationRollback',
'CTS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api',
'RollbackAssociationCustomer',
'ArchiveData',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Daily_NormalAccountScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api',
'scanningDailyNormalClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Daily_NormalTaggingScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=5000',
'scanningDailyNormalTaggingClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Daily_ProblemAccountScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'scanningDailyProblemClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_RealtimeCheckChanges',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=5000',
'realtimeCheckChanges',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_RealtimeScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchExternalSize=3000&batchInternalSize=1000',
'scanningRealtimeClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_NormalAccountClassification',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchInternalSize=4000',
'normalAccountClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_NormalAccountInsert',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchExternalSize=500&batchInternalSize=5000&isLogData=true',
'normalAccountInsert',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Daily_ProbationScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'probationClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Minutely_RobotTWScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchExternalSize=500&batchInternalSize=500',
'robotTWClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Customer_Secondly_NewCustomerInsert',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'InsertNewCustomer',
'TransformCustomer',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Customer_Secondly_InsertMissingCustomer',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'InsertMissingCustomer',
'TransformCustomer',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Customer_Secondly_CustomerInfoUpdate',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=5000&waitTime=120',
'UpdateCTSCustomerInfo',
'TransformCustomer',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Customer_Secondly_Username2ForCustMainUpdate',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=1000',
'UpdateUsername2ForCustMain',
'TransformCustomer',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Customer_Hourly_Username2ForCustSubUpdate',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=1000',
'UpdateUsername2ForCustSub',
'TransformCustomer',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Customer_Hourly_Username2Update',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_LOCAL:5000/api?batchSize=500',
'UpdateUsername2',
'TransformCustomer',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Customer_Minutely_ReactivatedCustomerInsert',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api',
'InsertReactivatedCustomer',
'TransformCustomer',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Daily_NewCustomerInactive',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'InactivateNewCustomers',
'TransformCustomer',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_TWGroupBetting_Minutely_ScanTicket',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=3000',
'ScanTWGBTicket',
'twgroupbetting',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_TWGroupBetting_Minutely_CountTotalTicket',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api',
'UpdateTotalTWGBTicket',
'twgroupbetting',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_AffectedDownlineFromQueue',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'affectedDownlineClassificationFromQueue',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_NewCustomerClassify',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'newcustomerclassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_RobotAI_Minutely_Classification',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchExternalSize=500&batchInternalSize=500',
'robotAIDetection',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_TVSProblemAccountInsert',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'tvsProblemAccountInsert',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_MatchMonitor_Minutely_StatusUpdate',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api',
'UpdateStatusMatchMonitor',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_MatchMonitorGBClassify',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api',
'ClassifyMatchMonitor',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_SabaDangerLevel_Secondly_ByProblemAccountUpdate',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=5000',
'sabaDangerLevel',
'transExternalDataJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassificationBySport_Secondly_NormalAccountInsert',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchExternalSize=500&batchInternalSize=5000',
'NormalAccountInsertBySport',
'classificationBySportJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassificationBySport_Secondly_NormalAccountClassification',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchInternalSize=4000',
'NormalAccountClassificationBySport',
'classificationBySportJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassificationBySport_Daily_NormalAccountScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api',
'ScanningDailyNormalClassificationBySport',
'classificationBySportJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassificationBySport_Daily_ProbationScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api',
'ScanProbationClassificationBySport',
'classificationBySportJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassificationBySport_Secondly_RealtimeScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchInternalSize=5000',
'ScanRealtimeClassificationBySport',
'classificationBySportJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_AssociationAccountScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api',
'ScanAssociatedAccount',
'associationJob',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Daily_DetectUnauthorizedLogin_Credit',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchExternalSize=500&batchInternalSize=500',
'DetectUnauthorizedLoginCustomerCredit',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Daily_DetectUnauthorizedLogin_Licensee',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchExternalSize=500&batchInternalSize=500',
'DetectUnauthorizedLoginCustomerLicensee',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Daily_DangerousScoreToCCScan_Deposit',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'scanningDailyDangerousDepositClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Daily_DangerousScoreToCCScan_Credit',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'scanningDailyDangerousCreditClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_TWInitialGBToCCScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'scanningSecondlyTWInitialGBClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Minutely_TWInitialSmartToCCScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=500',
'scanningMinutelyTWInitialSmartClassification',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_NormalDangerousAssociationCheck',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?batchSize=5000',
'normalDangerousAssociationCheck',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassification_Secondly_NormalDangerousAssociationScan',
'CTS_CC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_cc_job_service_prod:5000/api?internalBatchSize=2000&externalBatchSize=5000',
'normalDangerousAssociationScan',
'classificationJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'FS_BigStateNearGoal',
'FS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_fs_bsng_job_service_prod:5000/api',
'bigstateneargoal',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'FS_CheckBet',
'FS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_fs_job_service_prod:5000/api',
'checkbet',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'FS_ScannedOfficeIp',
'FS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_fs_job_service_prod:5000/api',
'scannedofficeip',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'FS_DelayGoal',
'FS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_fs_job_service_prod:5000/api',
'delayedgoal',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'FS_DailyCaptureData',
'FS',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_fs_job_service_prod:5000/api',
'dailycapturedata',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'VR_BetLimit',
'VR',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_vr_job_service_prod:5000/api',
'betlimit',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'VR_SpecialLicensee',
'VR',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_vr_job_service_prod:5000/api',
'spaciallicensee',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'VR_AdjustVRSetting',
'VR',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_vr_job_service_prod:5000/api',
'adjustvrsetting',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'VR_Agent',
'VR',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_vr_job_service_prod:5000/api',
'agent',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'VR_MemberBigStake',
'VR',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_vr_job_service_prod:5000/api',
'memberbigstake',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'VR_SabaDangerLevel_Hourly_ByWinlossUpdate',
'VR',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_vr_job_service_prod:5000/api?batchSize=20000',
'SapaSportDangerLevel',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'AFC_B2CAccount_Daily_Update',
'AFC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_afc_job_service_prod:5000/api',
'SyncB2CAccount',
'Job',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_Scan_Data_Consistency_Monitoring',
'NotificationMonitor',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_job_service_prod:5000/api',
'ScanDataConsistencyMonitoring',
'Notification',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassificationAgency_Secondly_RealtimeScan',
'CTS_AgencyCC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_agencycc_job_service_prod:5000/api?batchExternalSize=3000&batchInternalSize=1000',
'scanningRealtimeClassificationAgency',
'classificationAgencyJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassificationAgency_Daily_NormalAccountScan',
'CTS_AgencyCC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_agencycc_job_service_prod:5000/api',
'scanningDailyNormalClassificationAgency',
'classificationAgencyJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassificationAgency_Secondly_NormalAccountClassification',
'CTS_AgencyCC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_agencycc_job_service_prod:5000/api?batchInternalSize=2000',
'normalAccountClassificationAgency',
'classificationAgencyJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassificationAgency_Secondly_NormalAccountInsert',
'CTS_AgencyCC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_agencycc_job_service_prod:5000/api?batchExternalSize=500&batchInternalSize=2000',
'normalAccountInsertAgency',
'classificationAgencyJobs',
false,
false,
false);

INSERT INTO CTS_Admin.CTSJob (JobName, GroupName, EnvironmentID, JobType, APIUrl, MethodName, Controller, IsStartByDefault, IsDisable, IsAdjust) VALUES (
'CTS_CustomerClassificationAgency_Daily_NewCustomerInactive',
'CTS_AgencyCC',
1,
'Fanex.NAP.SPU.Main.JobSchedulers.Services.JobExecute',
'http://nap_spu_cts_agencycc_job_service_prod:5000/api?batchSize=500',
'InactivateNewCustomersAgency',
'TransformCustomerAgency',
false,
false,
false);


