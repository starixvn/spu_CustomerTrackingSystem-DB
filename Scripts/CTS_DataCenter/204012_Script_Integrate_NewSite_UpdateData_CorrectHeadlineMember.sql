/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
/*
	Creator:	20240426@Victoria.Le
	Task:		Correct Headline of member "fmrup"
	Database:	CTSMain.CTS_DataCenter
	
	Revisions:
		- 20240426@Victoria.Le: Initial Writing [Redmine ID: #204012]
	
	Steps:
		
*/
USE CTS_DataCenter;

DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;
CREATE TEMPORARY TABLE 		Temp_CTSCustomer(
		CTSCustID			BIGINT UNSIGNED
	,	CustID 				INT UNSIGNED
	,	CustSubID			INT UNSIGNED
	,	UserName			VARCHAR(50)
	,	SiteID				INT
	,	Site				VARCHAR(50)
	,	RoleID				TINYINT
	,	SubscriberID 		INT
	,	SRecommend			INT	UNSIGNED		 	
	,	MRecommend			INT	UNSIGNED 			
	,	Recommend			INT	UNSIGNED
	,	LastLoginTime 		DATETIME(4)
	,	SiteID_New			INT
	,	Site_New			VARCHAR(50)
	,	SRecommend_New		INT UNSIGNED 
	,	MRecommend_New		INT UNSIGNED 
	,	Recommend_New		INT UNSIGNED
	, 	PRIMARY KEY(CTSCustID)
);  

DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer_FINAL;
CREATE TEMPORARY TABLE 		Temp_CTSCustomer_FINAL(
		CTSCustID			BIGINT UNSIGNED
	,	CustID 				INT UNSIGNED
	,	CustSubID			INT UNSIGNED
	,	UserName			VARCHAR(50)
	,	SiteID				INT
	,	Site				VARCHAR(50)
	,	RoleID				TINYINT
	,	SubscriberID 		INT
	,	SRecommend			INT	UNSIGNED		 	
	,	MRecommend			INT	UNSIGNED 			
	,	Recommend			INT	UNSIGNED
	,	LastLoginTime 		DATETIME(4)
	,	SiteID_New			INT
	,	Site_New			VARCHAR(50)
	,	SRecommend_New		INT UNSIGNED 
	,	MRecommend_New		INT UNSIGNED 
	,	Recommend_New		INT UNSIGNED
	,	SubscriberID_New	INT 
	, 	PRIMARY KEY(CTSCustID)
	,	INDEX IX_Temp_CTSCustomer_FINAL(SubscriberID)
); 


-- move member >> fmrup
INSERT INTO Temp_CTSCustomer(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend, LastLoginTime, SRecommend_New, MRecommend_New, Recommend_New, SiteID_New, Site_New)
SELECT cust.CTSCustID, cust.CustID, cust.CustSubID, cust.UserName, cust.SiteID, cust.Site, cust.RoleID, IFNULL(cust.SubscriberID,0),
	cust.SRecommend, cust.MRecommend, cust.Recommend, cust.LastLoginTime, tmp.SRecommend_New, tmp.MRecommend_New, tmp.Recommend_New, 1369, 'Hedging'
FROM CTSCustomer AS cust
,	LATERAL (	SELECT   CustID AS Recommend_New
					,	 MRecommend AS MRecommend_New
					,	 SRecommend AS SRecommend_New		
				FROM CTSCustomer
				WHERE UserName = 'AH-RUP') AS tmp
WHERE cust.UserName = 'fmrup';

INSERT IGNORE INTO Temp_CTSCustomer_FINAL(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend,  LastLoginTime, SRecommend_New, MRecommend_New, Recommend_New, SiteID_New, Site_New)
SELECT tmp.CTSCustID, tmp.CustID, tmp.CustSubID, tmp.UserName, tmp.SiteID, tmp.Site, tmp.RoleID, IFNULL(tmp.SubscriberID,0),
	tmp.SRecommend, tmp.MRecommend, tmp.Recommend,  tmp.LastLoginTime, tmp.SRecommend_New, tmp.MRecommend_New, tmp.Recommend_New, tmp.SiteID_New, tmp.Site_New
FROM Temp_CTSCustomer AS tmp;


UPDATE CTSCustomer AS cust
	INNER JOIN Temp_CTSCustomer_FINAL AS tmp ON tmp.CTSCustID = cust.CTSCustID
SET 	cust.SRecommend 	= 	CASE WHEN tmp.SRecommend_New IS NOT NULL THEN tmp.SRecommend_New 
									 ELSE cust.SRecommend END
	,	cust.MRecommend 	= 	CASE WHEN tmp.MRecommend_New IS NOT NULL THEN tmp.MRecommend_New 
									 ELSE cust.MRecommend END
	,	cust.Recommend 		= 	CASE WHEN tmp.Recommend_New IS NOT NULL THEN tmp.Recommend_New 
									 ELSE cust.Recommend END
	,	cust.SubscriberID 	= 	CASE WHEN tmp.SubscriberID_New IS NOT NULL THEN tmp.SubscriberID_New 
									 ELSE cust.SubscriberID END
	,	cust.SiteID 		= 	tmp.SiteID_New
	,	cust.Site 			= 	tmp.Site_New
;