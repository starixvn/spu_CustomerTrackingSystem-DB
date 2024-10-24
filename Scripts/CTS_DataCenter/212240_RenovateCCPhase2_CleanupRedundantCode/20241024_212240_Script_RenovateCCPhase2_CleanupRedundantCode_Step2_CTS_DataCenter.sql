/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241017@Victoria.Le
	Task:		RenovateCC Phase 2 - Change datatype & Clean up redundant code - Drop unuse tables/SPs/Events
	Server:  	Master
	DBName:		CTS_DataCenter

	Param's Expanation:
	
	Example:
		
	Revisions: 
		- 20241017@Victoria.Le:			Initial Writing [Redmine ID: #212240]
*/

USE CTS_DataCenter;

/************************* 1. Tables ******************************/
	DROP TABLE IF EXISTS PinCustomerCategory;
	DROP TABLE IF EXISTS CTSCustomerClassificationVVIP;
	DROP TABLE IF EXISTS CTSCustomerClassificationOldCategory;
	DROP TABLE IF EXISTS ProbationAccountMonitor;
	DROP TABLE IF EXISTS ProbationAccountMonitor_BySport;
	DROP TABLE IF EXISTS TaggingToCategory;
	DROP TABLE IF EXISTS CategoryToDangerLevel;
	DROP TABLE IF EXISTS ProblemCaseMonitor;
	DROP TABLE IF EXISTS TWProblemDetectionMonitor;
	DROP TABLE IF EXISTS TVSVoidRequest_History;
	DROP TABLE IF EXISTS MatchMonitor_AssociationDetection_Monitor;
	
	DROP TABLE IF EXISTS CustomerCategory_Arc;
	DROP TABLE IF EXISTS CTSCustomerClassification_Log_Before20240910;
	DROP TABLE IF EXISTS CTSCustomerClassification_BySport_Log_Before20240910;
	DROP TABLE IF EXISTS CTSCustomerClassificationOldCategory_BK2212;

	DROP TABLE IF EXISTS AdhocVic_Customer;
	DROP TABLE IF EXISTS Adhoc_CateDiff_Inccorect;
	DROP TABLE IF EXISTS Adhoc_CustID;
	DROP TABLE IF EXISTS Adhoc_CustIDCustID;

/************************* 2. SPs ******************************/
	DROP PROCEDURE IF EXISTS CTS_DC_AssociationDetection_DetectGroup_Monitor_xtest;
	DROP PROCEDURE IF EXISTS CTS_DC_CustClassification_GetLatestClassification_xtest;
	DROP PROCEDURE IF EXISTS CTS_DC_AssociationDetection_DetectGroup;
	DROP PROCEDURE IF EXISTS CTS_DC_CustClassification_SabaDangerLevel_Init;
	DROP PROCEDURE IF EXISTS CTS_DC_MatchMonitor_AssociationDetection_Wrapper;
	DROP PROCEDURE IF EXISTS CTS_DC_MatchMonitor_AssociationDetection_Wrapper_xtest;

/************************* 3. Events ******************************/
	DROP EVENT IF EXISTS EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_Redundant;
	DROP EVENT IF EXISTS EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_BySport_History;
	DROP EVENT IF EXISTS EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory;
	DROP EVENT IF EXISTS EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData;
	DROP EVENT IF EXISTS EV_CTS_DC_Adhoc_Renovate_Phase1_Clean_History;
	DROP EVENT IF EXISTS EV_CTS_DC_Adhoc_RenovateCC_InitCCHistory;
	
	DROP EVENT IF EXISTS EV_CTS_DC_MatchMonitor_Wrapper;
	DROP EVENT IF EXISTS Event_Long_Adhoc_UnleashHaifa4xPACC;
	
/************************* 4. SPs - 20241024******************************/
	DROP PROCEDURE IF EXISTS CTS_DC_AssociationDetection_DetectGroup_Monitor;
	DROP PROCEDURE IF EXISTS CTS_DC_CustClassification_SabaDangerLevel_Init_xtest;
