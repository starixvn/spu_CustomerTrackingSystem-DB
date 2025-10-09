/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20251009@Thomas.Nguyen
Task:	 	DB CleanUp Schema
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20251009@Thomas.Nguyen: Created [Redmine ID: #241032]
Reviewer:
*/

USE CTS_DataCenter;

/********************* Remove unused tables *********************/
ALTER TABLE AssociatedAccountMonitor RENAME TO DLE_AssociatedAccountMonitor;
ALTER TABLE CustEvidenceFromFile RENAME TO DLE_CustEvidenceFromFile;
ALTER TABLE CustEvidenceLog RENAME TO DLE_CustEvidenceLog;
ALTER TABLE CustEvidenceQueue RENAME TO DLE_CustEvidenceQueue;
ALTER TABLE SmartGroupHistory RENAME TO DLE_SmartGroupHistory;
