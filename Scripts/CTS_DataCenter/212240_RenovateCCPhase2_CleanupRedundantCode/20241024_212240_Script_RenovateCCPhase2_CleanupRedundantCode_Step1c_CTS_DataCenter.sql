/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241017@Victoria.Le
	Task:		RenovateCC Phase 2 - Change datatype & Clean up redundant code - Drop columns with prefix _arc/new/bk
	Server:  	Master
	DBName:		CTS_DataCenter

	Param's Expanation:
	
	Example:
		
	Revisions: 
		- 20241017@Victoria.Le:			Initial Writing [Redmine ID: #212240]
*/

USE CTS_DataCenter;

/************************* 1. Tables CTSCustomerClassification ******************************/
	ALTER TABLE CTSCustomerClassification 
	DROP SportGroupID_arc
, 	DROP CategoryID_arc
, 	DROP CreatedDate_new
, 	DROP LastScannedDate_new
, 	DROP SportGroupID_bk
, 	DROP CreatedDate_bk
, 	DROP CategoryID_bk
, 	DROP LastScannedDate_bk;

	ALTER TABLE CTSCustomerClassification 
	MODIFY ParentID INT UNSIGNED AFTER IsAffectToDownline;
	
	ALTER TABLE CTSCustomerClassification 
	MODIFY CategoryID INT UNSIGNED AFTER ParentID;

/************************* 2. Tables CTSCustomerClassification_BySport ******************************/
	ALTER TABLE CTSCustomerClassification_BySport 
	DROP CategoryID_arc
, 	DROP CreatedDate_new
, 	DROP LastScannedDate_new
, 	DROP CategoryID_bk
, 	DROP CreatedDate_bk
, 	DROP LastScannedDate_bk;

	ALTER TABLE CTSCustomerClassification_BySport 
	MODIFY CategoryID INT UNSIGNED AFTER ParentID;

/************************* 3. Tables CTSCustomerClassification_History ******************************/
	ALTER TABLE CTSCustomerClassification_History 
	DROP LastXDaysMargin
, 	DROP ProbationPeriodWinloss
, 	DROP IsAppliedCC
, 	DROP IsAppliedDangerLevel1
, 	DROP First5TWGBTicketCount
, 	DROP SportGroupID_arc
, 	DROP CategoryID_arc
, 	DROP FromCategoryID_arc
, 	DROP ToCategoryID_arc
, 	DROP SportGroupID_bk
, 	DROP CategoryID_bk
, 	DROP FromCategoryID_bk
, 	DROP ToCategoryID_bk;

	ALTER TABLE CTSCustomerClassification_History
	MODIFY COLUMN RobotCounter INT UNSIGNED;

	ALTER TABLE CTSCustomerClassification_History 
	MODIFY ParentID INT UNSIGNED AFTER CTSCustID;
	
	ALTER TABLE CTSCustomerClassification_History 
	MODIFY CategoryID INT UNSIGNED AFTER ParentID;

/************************* 4. Tables CTSCustomerClassification_BySport_History ******************************/
	ALTER TABLE CTSCustomerClassification_BySport_History 
	DROP CategoryID_arc
, 	DROP CategoryID_bk;

	ALTER TABLE CTSCustomerClassification_BySport_History 
	MODIFY CategoryID INT UNSIGNED AFTER ParentID;

/************************* 5. Tables CTSCustomerClassificationQueue ******************************/
	ALTER TABLE CTSCustomerClassificationQueue 
	DROP CategoryGroupID_new
, 	DROP CategoryID_new
, 	DROP CategoryGroup_bk
, 	DROP CategoryID_bk;
	
/************************* 6. Tables ArchiveCustomer_CTSCustomer ******************************/
	ALTER TABLE ArchiveCustomer_CTSCustomer 
	DROP CategoryID_arc
, 	DROP CategoryID_bk;
	
/************************* 7. Tables CTSCustomerClassification_Log ******************************/
	ALTER TABLE CTSCustomerClassification_Log
	MODIFY COLUMN RobotCounter INT UNSIGNED;
	
/************************* 8. Tables TWRobotUser ******************************/
	ALTER TABLE TWRobotUser
	MODIFY COLUMN RobotCounter INT UNSIGNED;	
	
/************************* 9. Tables SystemParameter ******************************/
	DELETE FROM SystemParameter WHERE ParameterID >= 774 AND ParameterID <= 999;
	
/************************* 10. Tables SystemEventStatus ******************************/
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_Renovate_Phase1_Clean_History';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_Renovate_Phase2_Clean_Redundant';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_BySport_InitCCHistory';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_CCMain_CorrectData';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_RenovateCC_InitCCHistory';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_Adhoc_RenovatePhase2CleanBySportHistory';
	DELETE FROM SystemEventStatus WHERE EventName = 'EV_CTS_DC_MatchMonitor_Wrapper';
