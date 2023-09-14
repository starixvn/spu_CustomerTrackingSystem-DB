/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230803@Jonas.Huynh
	Task:	 	Customer Classification - Remove unused code
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230803@Jonas.Huynh: Create Schema [Redmine ID: #191400]

*/

DROP PROCEDURE IF EXISTS CTS_DC_CustClassification_Normal_GetExisting;
DROP PROCEDURE IF EXISTS CTS_DC_CustClassification_Normal_GetExisting_xtest;

DROP PROCEDURE IF EXISTS CTS_DC_Notification_InsertProbationNotification;
DROP PROCEDURE IF EXISTS CTS_DC_Notification_InsertProbationNotification_xtest;