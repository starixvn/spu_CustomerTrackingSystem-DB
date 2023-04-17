/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230310@victoria.le
	Task:	 	Scale out - Split 789y Site
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230310@Victoria.le: 	STEP 3-Pre: Check data before updating data [Redmine ID: #183140]

*/
-- Check exists any CustID with SiteID = 3
SELECT CustID, RoleID, SiteID, Site, Currency, IsInternal
FROM CTS_DataCenter.CTSCustomer
WHERE SiteID = 3;

SELECT COUNT(1) AS CC
FROM CTS_DataCenter.CTSCustomer
WHERE SiteID = 3;

-- For real currency ==> Currency <> 20
SELECT Site, COUNT(1) AS CC
FROM CTS_DataCenter.CTSCustomer
WHERE CurrencyID <> 20
	AND SiteID = 3
GROUP BY Site;

SELECT Site, RoleID, COUNT(1) AS CC
FROM CTS_DataCenter.CTSCustomer
WHERE CurrencyID <> 20
	AND SiteID = 3
GROUP BY Site, RoleID;

-- For test currency ==>  Currency = 20
SELECT Site, COUNT(1) AS CC
FROM CTS_DataCenter.CTSCustomer
WHERE CurrencyID = 20
	AND SiteID = 3
GROUP BY Site;

SELECT Site, RoleID, COUNT(1) AS CC
FROM CTS_DataCenter.CTSCustomer
WHERE CurrencyID = 20
	AND SiteID = 3
GROUP BY Site, RoleID;




