/*
		Created:	20200528@CaseyHuynh	
		Task :		Subsriber: New (2)
		DB:			CTS_Admin
		Original:

		Revisions:
		Param's Explanation (filtered by):
*/

# 1.Add new Deposit Subscriber
/*
INSERT INTO CTS_Admin.Subscriber
		(SubscriberID	, SubscriberName		, SubscriberPrefix		, SubscriberType	, SubscriberStatus	, CreatedDate		, CreatedBy	, IsTest	, DCSStatus	, DCSIntegrationDate	, FPSSubscriberID)
VALUES	(<???>			, <???>	 				, <???>					, 1					, 1					, CURRENT_DATE()	, NULL		, 0			, 1			, CURRENT_DATE()		, <???>)

INSERT INTO CTS_DataCenter.MappingSubscriberSite
		(SubscriberID	, SubscriberName		, RoleMapping	, SubscriberType	, SubscriberStatus	, SiteID	, SiteName	, Comments)
VALUES	(<???>			, <???>					, 0				, 1					, 1					, <???>		, <???>		, NULL)


*/

# Get Max SubscriberID
SELECT MAX(SubscriberID)
FROM CTS_Admin.Subscriber; 111308;

SELECT *
FROM CTS_Admin.Subscriber
WHERE SubscriberID > 13673;


/*Check SubscriberName*/
SELECT 	*
FROM 	CTS_Admin.Subscriber
WHERE 	SubscriberName IN ('liv66', 'HC6YAYOU', 'TIC88', 'Nbet', 'Sky88', 'Kbet', 'Dabet');

/*Check SubscriberName*/
SELECT 	*
FROM 	CTS_Admin.Subscriber
WHERE 	SubscriberPrefix IN ('liv66$', 'HC6YAYOU$', 'TIC88$', 'Nbet$', 'Sky88$', 'Kbet$', 'Dabet$');

INSERT INTO CTS_Admin.Subscriber
		(SubscriberID	, SubscriberName		,  SubscriberPrefix		, FPSSubscriberID		, SubscriberType	, SubscriberStatus	, CreatedDate		, CreatedBy	, IsTest	, DCSStatus	, DCSIntegrationDate	)
VALUES	(13672			, 'ZFRT082' 			, 'ZFRT082$'			, 0						, 1					, 1					, CURRENT_DATE()	, NULL		, 0			, 1			, CURRENT_DATE()		)
	,	(13673			, 'wmcasino' 			, 'wmcasino$'			, 0						, 1					, 1					, CURRENT_DATE()	, NULL		, 0			, 1			, CURRENT_DATE()		)
;

INSERT INTO CTS_DataCenter.MappingSubscriberSite
		(SubscriberID	, SubscriberName		, SiteID	, SiteName		, RoleMapping	, SubscriberType	, SubscriberStatus			, Comments)
VALUES	(13672			, 'ZFRT082'				, 505		, 'ZFRT082'		, 0				, 1					, 1							, NULL)
	,	(13673			, 'wmcasino'			, 506		, 'wmcasino'	, 0				, 1					, 1							, NULL)
;
   
SELECT *
FROM CTS_Admin.Subscriber
ORDER BY SubscriberID Desc;

SELECT *
FROM CTS_DataCenter.MappingSubscriberSite
ORDER BY SubscriberID Desc;