/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
	Creator:	20230310@victoria.le
	Task:	 	Scale out - Split 789y Site

	 Revisions:
		- 20230310@Victoria.le: 	STEP 1: GET List Site which SiteLabel IS NOT NULL [Redmine ID: #183140]
								
*/

	SELECT	siteid AS SiteID
		,	Site AS SiteName
		,	SiteLabel
	FROM bodb02.dbo.Site WITH (NOLOCK)
	WHERE SiteLabel IS NOT NULL
		AND siteid <> 3
		AND IsActive = 1
		AND islicensee = 0;