/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="0" isNested="0"></info>*/
/*
	Creator:	20240424@Victoria.Le
	Task:		Integrate 2 New Sites and Update existing data - [Redmine: #204012]
	Database:	CTSMain.CTS_DataCenter
	
	Revisions:
		- 20240424@Victoria.Le: Initial Writing [Redmine ID: #204012]
	
	Steps:
		1. Create Adhoc table to backup data before deploying script migration
		2. Initial Data - Temp Table: CTSCustomer/CustDCSAccount/Account
		3. Backup Data
		4. Update Data
		5. Remove and Insert new custid in (76047311,79314572,76046278,76910613) by script and archived job -- username updated 
		6. Check count data and rollback data if any issues
		
*/
USE CTS_DataCenter;

-- 1. --------------------------------
/*Create Adhoc table to backup data before deploying script migration*/


CREATE TABLE Adhoc_204012_CTSCustomer(
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


CREATE TABLE Adhoc_204012_CustDCSAccount(		 	
		CTSCustID			BIGINT UNSIGNED
	,	AccountID 			BIGINT UNSIGNED
	,	SubscriberID		INT
	,	SubscriberID_New	INT
	, 	PRIMARY KEY(CTSCustID,AccountID)
);    

CREATE TABLE Adhoc_204012_Account(		 	
		AccountID 			BIGINT UNSIGNED
	,	SubscriberID		INT
	,	SubscriberID_New	INT
	, 	PRIMARY KEY(AccountID)
);   


-- 2. --------------------------------
/*Initial Data - Temp Table*/

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

DROP TEMPORARY TABLE IF EXISTS Temp_RecommendList_RoleID3;
CREATE TEMPORARY TABLE 		Temp_RecommendList_RoleID3(		 		
		Recommend			INT	UNSIGNED
	,	MRecommend			INT	UNSIGNED 
	,	SRecommend_New		INT UNSIGNED 
	,	SiteID_New			INT
	,	Site_New			VARCHAR(20)
	, 	PRIMARY KEY(Recommend)
);   

DROP TEMPORARY TABLE IF EXISTS Temp_CustDCSAccount;
CREATE TEMPORARY TABLE 		Temp_CustDCSAccount(		 	
		CTSCustID			BIGINT UNSIGNED
	,	AccountID 			BIGINT UNSIGNED
	,	SubscriberID		INT
	,	SubscriberID_New	INT
	, 	PRIMARY KEY(CTSCustID,AccountID)
);    

DROP TEMPORARY TABLE IF EXISTS Temp_Account;
CREATE TEMPORARY TABLE 		Temp_Account(		 	
		AccountID 			BIGINT UNSIGNED
	,	SubscriberID		INT
	,	SubscriberID_New	INT
	, 	PRIMARY KEY(AccountID)
);    

-- 2.1 --------------------------------
-- ------------------------------------
INSERT INTO Temp_CTSCustomer(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID, SRecommend, MRecommend, Recommend, SiteID_New, Site_New)
SELECT CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, IFNULL(SubscriberID,0), SRecommend, MRecommend, Recommend, 1369, 'Hedging' -- 20
FROM CTSCustomer
WHERE UserName IN (
'MOLLYBET','AH501','MollyBF','XYZHK','billma',
'FRARM','M008iRM','M9999RM','mbrm','2022WC-RM',
'CASHTEST','CMD','FRA','IT-test1','MMRODDS',
'XYZPTRM','XYZRM','ISN','STELIM',
'6666AHK' -- 16/04
)
UNION
SELECT CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, IFNULL(SubscriberID,0), SRecommend, MRecommend, Recommend, 1370, 'Special' -- 20
FROM CTSCustomer
WHERE UserName IN (
'wsrmb','8RM','8RM8801','8RM8802','8RM8803',
'8RM8804','8RM8805','8RM8806','8RM8807','8RM8808',
'8RM8809','8RM8810','8RMTest01','BARM','BARM002',
'MMRWC22','PHIRM','WCBill','WINRM','wsrm');

-- update Super
;WITH T AS (
	SELECT 	'MOLLYBET' UserName, 'MH-EURO' Master, 'SH-EURO' Super
	UNION SELECT 'AH501'	, NULL		, 'SH-HK$'
	UNION SELECT 'MollyBF'	, 'MH-HK$'	, 'SH-HK$'
	UNION SELECT 'XYZHK'	, 'MH-HK$'	, 'SH-HK$'
	UNION SELECT 'billma'	, NULL		, 'SH-RM'
	UNION SELECT 'FRARM'	, NULL		, 'SH-RM'
	UNION SELECT 'M008iRM'	, NULL		, 'SH-RM'
	UNION SELECT 'M9999RM'	, NULL		, 'SH-RM'
	UNION SELECT 'mbrm'		, NULL		, 'SH-RM'
	UNION SELECT '2022WC-RM', 'MH-RM'	, 'SH-RM'
	UNION SELECT 'CASHTEST'	, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'CMD'		, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'FRA'		, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'IT-test1'	, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'MMRODDS'	, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'XYZPTRM'	, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'XYZRM'	, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'ISN'		, NULL		, 'SH-RMB'
	UNION SELECT 'STELIM'	, NULL		, 'SH-RMB'
	UNION SELECT '6666AHK'  , 'MH-HK$'  , 'SH-HK$'		-- 16/04

	UNION SELECT 'wsrmb'		, 'MS-RMB' 	, 'SS-RMB'
	UNION SELECT '8RM'			, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8801'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8802'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8803'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8804'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8805'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8806'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8807'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8808'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8809'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8810'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RMTest01'	, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'BARM'			, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'BARM002'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'MMRWC22'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'PHIRM'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'WCBill'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'WINRM'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'wsrm'			, 'MS-RM'	, 'SS-RM'
)
UPDATE Temp_CTSCustomer AS c
	INNER JOIN T ON c.UserName = T.UserName
	INNER JOIN CTSCustomer AS s ON T.Super = s.UserName
SET c.SRecommend_New = s.CustID;
	
-- update master
;WITH T AS (
	SELECT 	'MOLLYBET' UserName, 'MH-EURO' Master, 'SH-EURO' Super
	UNION SELECT 'AH501'	, NULL		, 'SH-HK$'
	UNION SELECT 'MollyBF'	, 'MH-HK$'	, 'SH-HK$'
	UNION SELECT 'XYZHK'	, 'MH-HK$'	, 'SH-HK$'
	UNION SELECT 'billma'	, NULL		, 'SH-RM'
	UNION SELECT 'FRARM'	, NULL		, 'SH-RM'
	UNION SELECT 'M008iRM'	, NULL		, 'SH-RM'
	UNION SELECT 'M9999RM'	, NULL		, 'SH-RM'
	UNION SELECT 'mbrm'		, NULL		, 'SH-RM'
	UNION SELECT '2022WC-RM', 'MH-RM'	, 'SH-RM'
	UNION SELECT 'CASHTEST'	, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'CMD'		, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'FRA'		, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'IT-test1'	, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'MMRODDS'	, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'XYZPTRM'	, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'XYZRM'	, 'MH-RM'	, 'SH-RM'
	UNION SELECT 'ISN'		, NULL		, 'SH-RMB'
	UNION SELECT 'STELIM'	, NULL		, 'SH-RMB'
	UNION SELECT '6666AHK'  , 'MH-HK$'  , 'SH-HK$'		-- 16/04

	UNION SELECT 'wsrmb'		, 'MS-RMB' 	, 'SS-RMB'
	UNION SELECT '8RM'			, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8801'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8802'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8803'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8804'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8805'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8806'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8807'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8808'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8809'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RM8810'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT '8RMTest01'	, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'BARM'			, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'BARM002'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'MMRWC22'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'PHIRM'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'WCBill'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'WINRM'		, 'MS-RM'	, 'SS-RM'
	UNION SELECT 'wsrm'			, 'MS-RM'	, 'SS-RM'
)
UPDATE Temp_CTSCustomer AS c
	INNER JOIN T ON c.UserName = T.UserName 
	LEFT JOIN CTSCustomer AS m ON T.Master = m.UserName
SET c.MRecommend_New = m.CustID;
	
-- 2.2 --------------------------------
-- ------------------------------------
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
				WHERE UserName = 'AH-RMB') AS tmp
WHERE cust.UserName = 'fmrup';

-- move member >> 230RMB, 231RMB -- 16/04
INSERT INTO Temp_CTSCustomer(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend, LastLoginTime, SRecommend_New, MRecommend_New, Recommend_New, SiteID_New, Site_New)
SELECT cust.CTSCustID, cust.CustID, cust.CustSubID, cust.UserName, cust.SiteID, cust.Site, cust.RoleID, IFNULL(cust.SubscriberID,0),
	cust.SRecommend, cust.MRecommend, cust.Recommend, cust.LastLoginTime, tmp.SRecommend_New, tmp.MRecommend_New, tmp.Recommend_New, 1369, 'Hedging'
FROM CTSCustomer AS cust
,	LATERAL (	SELECT   CustID AS Recommend_New
					,	 MRecommend AS MRecommend_New
					,	 SRecommend AS SRecommend_New		
				FROM CTSCustomer
				WHERE UserName = 'AH-RMB') AS tmp
WHERE cust.UserName IN('230RMB','231RMB');


INSERT IGNORE INTO Temp_CTSCustomer_FINAL(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend,  LastLoginTime, SRecommend_New, MRecommend_New, Recommend_New, SiteID_New, Site_New)
SELECT tmp.CTSCustID, tmp.CustID, tmp.CustSubID, tmp.UserName, tmp.SiteID, tmp.Site, tmp.RoleID, IFNULL(tmp.SubscriberID,0),
	tmp.SRecommend, tmp.MRecommend, tmp.Recommend,  tmp.LastLoginTime, tmp.SRecommend_New, tmp.MRecommend_New, tmp.Recommend_New, tmp.SiteID_New, tmp.Site_New
FROM Temp_CTSCustomer AS tmp;

INSERT IGNORE INTO Temp_CTSCustomer_FINAL(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend, LastLoginTime, SRecommend_New, MRecommend_New, Recommend_New, SiteID_New, Site_New)
SELECT cust.CTSCustID, cust.CustID, cust.CustSubID, cust.UserName, cust.SiteID, cust.Site, cust.RoleID, IFNULL(cust.SubscriberID,0),
	cust.SRecommend, cust.MRecommend, cust.Recommend, cust.LastLoginTime, tmp.SRecommend_New, tmp.MRecommend_New, tmp.Recommend_New, tmp.SiteID_New, tmp.Site_New
FROM Temp_CTSCustomer AS tmp
	INNER JOIN CTSCustomer AS cust ON cust.SRecommend = tmp.SRecommend
WHERE tmp.RoleID = 4
;

INSERT IGNORE INTO Temp_CTSCustomer_FINAL(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend, LastLoginTime, SRecommend_New, MRecommend_New, Recommend_New, SiteID_New, Site_New)
SELECT cust.CTSCustID, cust.CustID, cust.CustSubID, cust.UserName, cust.SiteID, cust.Site, cust.RoleID, IFNULL(cust.SubscriberID,0),
	cust.SRecommend, cust.MRecommend, cust.Recommend, cust.LastLoginTime, tmp.SRecommend_New, tmp.MRecommend_New, tmp.Recommend_New, tmp.SiteID_New, tmp.Site_New
FROM Temp_CTSCustomer AS tmp
	INNER JOIN CTSCustomer AS cust ON cust.MRecommend = tmp.MRecommend
WHERE tmp.RoleID = 3
;
	
INSERT IGNORE INTO Temp_CTSCustomer_FINAL(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend, LastLoginTime, SRecommend_New, MRecommend_New, Recommend_New, SiteID_New, Site_New)
SELECT cust.CTSCustID, cust.CustID, cust.CustSubID, cust.UserName, cust.SiteID, cust.Site, cust.RoleID, IFNULL(cust.SubscriberID,0),
	cust.SRecommend, cust.MRecommend, cust.Recommend, cust.LastLoginTime, tmp.SRecommend_New, tmp.MRecommend_New, tmp.Recommend_New, tmp.SiteID_New, tmp.Site_New
FROM Temp_CTSCustomer AS tmp
	INNER JOIN CTSCustomer AS cust ON cust.Recommend = tmp.Recommend
WHERE tmp.RoleID = 2
;

-- 2.3 --------------------------------
-- ------------------------------------
INSERT IGNORE INTO Temp_RecommendList_RoleID3 (Recommend, MRecommend, SRecommend_New, SiteID_New, Site_New)
SELECT cc.Recommend, c.CustID, c.SRecommend_New, c.SiteID_New, c.Site_New
FROM Temp_CTSCustomer AS c
	INNER JOIN CTSCustomer AS cc ON c.CustID = cc.MRecommend AND cc.RoleID = 2 
WHERE c.RoleID = 3;

INSERT IGNORE INTO Temp_CTSCustomer_FINAL(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend, LastLoginTime, SRecommend_New, SiteID_New, Site_New)
SELECT cust.CTSCustID, cust.CustID, cust.CustSubID, cust.UserName, cust.SiteID, cust.Site, cust.RoleID, IFNULL(cust.SubscriberID,0),
	cust.SRecommend, cust.MRecommend, cust.Recommend, cust.LastLoginTime, tmp.SRecommend_New, tmp.SiteID_New, tmp.Site_New
FROM Temp_RecommendList_RoleID3 AS tmp
	INNER JOIN CTSCustomer AS cust ON cust.Recommend = tmp.Recommend;


-- 2.4 --------------------------------
-- ------------------------------------
INSERT INTO Temp_CTSCustomer(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend, SiteID_New, Site_New)
SELECT cust.CTSCustID, cust.CustID, cust.CustSubID, cust.UserName, cust.SiteID, cust.Site, cust.RoleID, IFNULL(cust.SubscriberID,0),
	cust.SRecommend, cust.MRecommend, cust.Recommend, 1369, 'Hedging'
FROM CTSCustomer AS cust
WHERE cust.UserName IN('999MYR','USTM'); -- Super

INSERT IGNORE INTO Temp_CTSCustomer_FINAL(CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend, LastLoginTime, SiteID_New, Site_New)
SELECT cust.CTSCustID, cust.CustID, cust.CustSubID, cust.UserName, cust.SiteID, cust.Site, cust.RoleID, IFNULL(cust.SubscriberID,0),
	cust.SRecommend, cust.MRecommend, cust.Recommend, cust.LastLoginTime, tmp.SiteID_New, tmp.Site_New
FROM Temp_CTSCustomer AS tmp
	INNER JOIN CTSCustomer AS cust ON cust.SRecommend = tmp.SRecommend
WHERE tmp.RoleID = 4
;
	
-- 2.5 --------------------------------
-- ------------------------------------
UPDATE Temp_CTSCustomer_FINAL AS tmp
SET tmp.SubscriberID_New = CASE WHEN tmp.RoleID = 1 THEN 130 -- MAXBET
								ELSE 2  END -- Alpha
WHERE tmp.SubscriberID NOT IN (2,130);


-- 2.6 --------------------------------
-- ------------------------------------
INSERT INTO Temp_CustDCSAccount (CTSCustID, AccountID, SubscriberID, SubscriberID_New)
SELECT dcs.CTSCustID, dcs.AccountID, dcs.SubscriberID, tmp.SubscriberID_New
FROM Temp_CTSCustomer_FINAL AS tmp
	INNER JOIN CustDCSAccount AS dcs ON dcs.CTSCustID = tmp.CTSCustID 
WHERE tmp.SubscriberID_New IS NOT NULL;

-- 2.7 --------------------------------
-- ------------------------------------
INSERT INTO Temp_Account (AccountID, SubscriberID, SubscriberID_New)
SELECT dcs.AccountID, dcs.SubscriberID, tmp.SubscriberID_New
FROM Temp_CustDCSAccount AS tmp
	INNER JOIN DCS_DataCenter.Account AS dcs ON dcs.AccountID = tmp.AccountID;

-- 3. --------------------------------
/*Backup Data*/

INSERT INTO Adhoc_204012_CTSCustomer (CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend, LastLoginTime, SRecommend_New, MRecommend_New, Recommend_New, SiteID_New, Site_New)
SELECT CTSCustID, CustID, CustSubID, UserName, SiteID, Site, RoleID, SubscriberID,
	SRecommend, MRecommend, Recommend, LastLoginTime, SRecommend_New, MRecommend_New, Recommend_New, SiteID_New, Site_New
FROM Temp_CTSCustomer_FINAL;

INSERT INTO Adhoc_204012_CustDCSAccount (CTSCustID, AccountID, SubscriberID, SubscriberID_New)
SELECT CTSCustID, AccountID, SubscriberID, SubscriberID_New
FROM Temp_CustDCSAccount;

INSERT INTO Adhoc_204012_Account (AccountID, SubscriberID, SubscriberID_New)
SELECT AccountID, SubscriberID, SubscriberID_New
FROM Temp_Account;

-- 4. --------------------------------
/*Update Data*/

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

UPDATE DCS_DataCenter.Account AS dcs
	INNER JOIN Temp_Account AS tmp ON tmp.AccountID = dcs.AccountID
SET dcs.SubscriberID = tmp.SubscriberID_New;

UPDATE CustDCSAccount AS dcs
	INNER JOIN Temp_CustDCSAccount AS tmp ON tmp.CTSCustID = dcs.CTSCustID
SET dcs.SubscriberID = tmp.SubscriberID_New;

/*
SELECT *
FROM Temp_CTSCustomer_FINAL
WHERE SubscriberID_New IS NOT NULL;


SELECT *
FROM Temp_Account;

SELECT *
FROM Temp_CustDCSAccount;
*/
-- 5. --------------------------------
/*Remove and Insert new custid in (76047311,79314572,76046278,76910613) by script and archived job -- username updated */



-- 6. --------------------------------
/*Check count data and rollback data if any issues*/
/*
SELECT SiteID, Site, RoleID, COUNT(1)
FROM CTSCustomer
WHERE SiteID in (1369,1370)
	AND currency not in (20,27,28) 
GROUP BY SiteID, Site, RoleID
ORDER BY 1,2,3;
*/