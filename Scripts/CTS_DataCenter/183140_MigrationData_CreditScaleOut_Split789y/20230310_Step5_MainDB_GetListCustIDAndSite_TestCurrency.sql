/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
	Creator:	20230310@Victoria.le
	Task:	 	Scale out - Split 789y Site

	 Revisions:
		- 20230310@Victoria.le: 	STEP 5: GET List CustID and Site - Test Curreny [Redmine ID: #183140]
								
*/
/**************************
PART 1: GET DATA
***************************/

SELECT 	c.custid AS CustID
	,	c.site AS SiteName
FROM CustDB.dbo.Customer AS c WITH (NOLOCK) 
	INNER JOIN CustDB.dbo.Site AS s WITH (NOLOCK) ON s.site = c.site			
WHERE s.SiteLabel = '789y'				
	AND c.currency = 20;

/**************************
PART 2: Back to step 4 to update newsite for CTS system
***************************/

/**************************
PART 3: Check Consistency - Will be run when MainDB finish migration data
***************************/
/*
SELECT c.site AS SiteName, COUNT(1) AS CC
FROM CustDB.dbo.Customer AS c WITH (NOLOCK) 
	INNER JOIN CustDB.dbo.Site AS s WITH (NOLOCK) ON s.site = c.site			
WHERE s.SiteLabel = '789y'				
	AND c.currency = 20
GROUP BY c.site;
	
SELECT c.site AS SiteName, c.roleid AS RoleID, COUNT(1) AS CC
FROM CustDB.dbo.Customer AS c WITH (NOLOCK) 
	INNER JOIN CustDB.dbo.Site AS s WITH (NOLOCK) ON s.site = c.site			
WHERE s.SiteLabel = '789y'				
	AND c.currency = 20
GROUP BY c.site, c.roleid;
*/