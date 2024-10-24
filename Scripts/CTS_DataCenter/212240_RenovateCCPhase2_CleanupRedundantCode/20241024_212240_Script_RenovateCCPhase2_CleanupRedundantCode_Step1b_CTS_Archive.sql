/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
	Created:	20241017@Victoria.Le
	Task:		RenovateCC Phase 2 - Change datatype
	Server:  	Master
	DBName:		CTS_Archive

	Param's Expanation:
	
	Example:
		
	Revisions: 
		- 20241017@Victoria.Le:			Initial Writing [Redmine ID: #212240]
*/

USE CTS_Archive;

ALTER TABLE CTSCustomerClassification_History_Renovate_Archive
MODIFY COLUMN RobotCounter INT UNSIGNED;