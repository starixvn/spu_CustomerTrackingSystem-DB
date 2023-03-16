/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230310@victoria.le
	Task:	 	Scale out - Split 789y Site
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230310@Victoria.le: 	STEP 0: Table MappingSubscriberSite - Edit Schema [Redmine ID: #183140]

*/

USE CTS_DataCenter;

ALTER TABLE MappingSubscriberSite
ADD COLUMN SiteLabel VARCHAR(50) DEFAULT NULL;