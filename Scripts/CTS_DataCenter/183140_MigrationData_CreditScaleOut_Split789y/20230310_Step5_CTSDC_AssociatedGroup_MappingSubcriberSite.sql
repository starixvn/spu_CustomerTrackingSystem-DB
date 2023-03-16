/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230310@victoria.le
	Task:	 	Scale out - Split 789y Site
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230310@Victoria.le: 	STEP 5: 5.1: AssociatedGroup - Update Sites,PACreditSites,PASites 
											5.2: MappingSubscriberSite - Delete SiteID = 3 [Redmine ID: #183140]

*/
-- 5.1 AssociatedGroup
SELECT * 
FROM AssociatedGroup
WHERE Sites LIKE '%,3,%'
-- NEED TO CHECK MORE .........
;

UPDATE AssociatedGroup
SET Sites = REPLACE(Sites,',3,',CONCAT(',1040,1041,1042,1043,'));

-- 5.2 MappingSubscriberSite
DELETE FROM MappingSubscriberSite WHERE SiteID = 3;