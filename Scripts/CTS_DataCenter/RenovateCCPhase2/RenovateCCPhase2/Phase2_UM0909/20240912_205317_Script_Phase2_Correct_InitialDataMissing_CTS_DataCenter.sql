/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240912@Victoria.Le
	Task :	Fix Data and Init Missing TVSVoidRequest (UM10092024)
	DB:			
	
	Description: 

	Revisions:	
		- 20240912@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;


/*-- ParentID + CategoryID = NULL -- REMOVE VVIP*/
UPDATE CTSCustomerClassification_History 
SET ParentID = 1000
  , CategoryID = 1010
WHERE ID = 1096115669;


/*-- CategoryID INCORRECT*/
UPDATE CTSCustomerClassification AS cc
	, LATERAL (
		SELECT h.ParentID,h.CategoryID,h.CustID
		FROM CTSCustomerClassification_History AS h 
		WHERE h.CustID = 55766060
			AND h.IsDataChanged = 1
		ORDER BY h.ID DESC
		LIMIT 1
	) AS latest
SET cc.CategoryID = latest.CategoryID
WHERE cc.CustID = latest.CustID AND cc.ParentID = latest.ParentID
	AND cc.CategoryID <> latest.CategoryID
;

/*-- TVS MISSING*/
DROP TEMPORARY TABLE IF EXISTS Adhoc_TVSCustomer;
CREATE TEMPORARY TABLE Adhoc_TVSCustomer
(
		ID 					BIGINT
	,	CustID				BIGINT
    ,	TVSRequestID 		BIGINT
    , 	CreatedDate 		datetime
    , 	MaxIDKeep 			BIGINT
	,	IsDisable			TINYINT DEFAULT 0
	, 	PRIMARY KEY (ID,CustID)
    , 	UNIQUE KEY UK_Temp (TVSRequestID,CustID)
);

DROP TEMPORARY TABLE IF EXISTS Adhoc_TVSVoidRequest_CC;
CREATE TEMPORARY TABLE Adhoc_TVSVoidRequest_CC
(
		ID 					BIGINT
	,	CustID				BIGINT
	,	CategoryID			INT
	-- ,	CategoryID_new		INT
	,	TVSRequestID 		BIGINT
	,	ReasonID			INT
	,	CreatedBy 			INT
	,	CreatedDate 		DATE
	,	IsParlay 			TINYINT(1)
	,	SportType 			SMALLINT
	,	IssueTypeID 		TINYINT
-- 	,	CheckType		 	TINYINT DEFAULT 0
-- 	,	IsDisable			TINYINT DEFAULT 0
	, 	PRIMARY KEY (ID, CustID)
	,	KEY IX_Temp_CustID_CategoryID (CustID, CategoryID)
);


DROP TEMPORARY TABLE IF EXISTS Adhoc_TVSVoidRequest_CCHis;
CREATE TEMPORARY TABLE Adhoc_TVSVoidRequest_CCHis
(
		ID 					BIGINT
	,	CustID				BIGINT
	,	CategoryID			INT
	-- ,	CategoryID_new		INT
	,	TVSRequestID 		BIGINT
	,	ReasonID			INT
	,	CreatedBy 			INT
	,	CreatedDate 		DATE
	,	IsParlay 			TINYINT(1)
	,	SportType 			SMALLINT
	,	IssueTypeID 		TINYINT
-- 	,	CheckType		 	TINYINT DEFAULT 0
-- 	,	IsDisable			TINYINT DEFAULT 0
	, 	PRIMARY KEY (ID, CustID)
	,	KEY IX_Temp_CustID_CategoryID (CustID, CategoryID)
);

INSERT IGNORE INTO Adhoc_TVSCustomer (ID, CustID, TVSRequestID,CreatedDate )
SELECT h.ID, js.CustID, h.TVSRequestID,h.CreatedDate
FROM TVSVoidRequest_History AS h
	INNER JOIN JSON_TABLE(REPLACE(JSON_ARRAY(h.CustIDs), ',', '","'), 
									'$[*]' COLUMNS (CustID BIGINT UNSIGNED PATH '$')
									) js
	INNER JOIN CTSCustomer AS cust ON cust.CustID = js.CustID AND cust.CustSubID = 0
where h.ID > 174216
ORDER BY h.ID DESC;

DROP TEMPORARY TABLE IF EXISTS Adhoc_TVSCustomer_DUP;
CREATE TEMPORARY TABLE Adhoc_TVSCustomer_DUP LIKE Adhoc_TVSCustomer;

INSERT INTO Adhoc_TVSCustomer_DUP (ID, CustID, TVSRequestID, CreatedDate, MaxIDKeep)
WITH CTE AS
(
	SELECT ID, CustID, TVSRequestID, CreatedDate, ROW_NUMBER() OVER (PARTITION BY CustID ORDER BY ID DESC) AS RN
	FROM Adhoc_TVSCustomer
	WHERE TVSRequestID IS NULL
)
SELECT ID, CustID, TVSRequestID, CreatedDate, RN AS MaxIDKeep
FROM CTE
WHERE RN = 1;

INSERT INTO Adhoc_TVSCustomer_DUP (ID, CustID, TVSRequestID, CreatedDate, MaxIDKeep)
SELECT ID, CustID, TVSRequestID, CreatedDate, ID
FROM Adhoc_TVSCustomer
WHERE TVSRequestID IS NOT NULL
;

INSERT IGNORE INTO Adhoc_TVSVoidRequest_CCHis (ID, CustID, CategoryID, TVSRequestID, IsParlay, SportType, IssueTypeID)
SELECT 	tvs.ID
	, 	h.CustID
	, 	h.CategoryID
	, 	h.TVSRequestID
	, 	h.IsParlay
	, 	h.SportType
	, 	h.IssueTypeID
FROM CTSCustomerClassification_History AS h
INNER JOIN Adhoc_TVSCustomer_DUP AS tvs ON tvs.CustID = h.CustID AND  IFNULL(tvs.TVSRequestID,0) =  IFNULL(h.TVSRequestID,0)
	INNER JOIN CustomerCategory AS cate ON cate.CategoryID = h.CategoryID
	INNER JOIN CustomerCategory AS relcate ON relcate.CategoryID = cate.RelevantCategoryID
WHERE h.IsFromTVS = 1
;

INSERT IGNORE INTO Adhoc_TVSVoidRequest_CC (ID, CustID, CategoryID, TVSRequestID, IsParlay, SportType, IssueTypeID)
SELECT 	tvs.ID
	, 	h.CustID
	, 	h.CategoryID
	, 	h.TVSRequestID
	, 	h.IsParlay
	, 	h.SportType
	, 	h.IssueTypeID
FROM CTSCustomerClassification AS h
INNER JOIN Adhoc_TVSCustomer_DUP AS tvs ON tvs.CustID = h.CustID AND  IFNULL(tvs.TVSRequestID,0) =  IFNULL(h.TVSRequestID,0)
	INNER JOIN CustomerCategory AS cate ON cate.CategoryID = h.CategoryID
	INNER JOIN CustomerCategory AS relcate ON relcate.CategoryID = cate.RelevantCategoryID
WHERE h.IsFromTVS = 1
;

/*
UPDATE Adhoc_TVSCustomer_DUP AS tvs
	INNER JOIN Adhoc_TVSVoidRequest_CC AS main ON tvs.CustID = main.CustID AND  IFNULL(tvs.TVSRequestID,0) =  IFNULL(main.TVSRequestID,0)
	LEFT JOIN Adhoc_TVSVoidRequest_CCHis AS his ON main.CustID = his.CustID AND IFNULL(main.TVSRequestID,0) =  IFNULL(his.TVSRequestID,0)
SET tvs.IsDisabled = 1
WHERE his.CustID IS NULL
;
*/

UPDATE Adhoc_TVSCustomer_DUP AS tvs
	INNER JOIN Adhoc_TVSVoidRequest_CCHis AS his ON his.CustID = tvs.CustID AND IFNULL(his.TVSRequestID,0) =  IFNULL(tvs.TVSRequestID,0)
	LEFT JOIN Adhoc_TVSVoidRequest_CC AS main ON his.CustID = main.CustID AND  IFNULL(his.TVSRequestID,0) =  IFNULL(main.TVSRequestID,0)
SET tvs.IsDisable = 1
WHERE main.CustID IS NULL
;

DROP TEMPORARY TABLE IF EXISTS Adhoc_TVSCustomer_DUP2;
CREATE TEMPORARY TABLE Adhoc_TVSCustomer_DUP2 AS SELECT * FROM Adhoc_TVSCustomer_DUP;


INSERT IGNORE INTO TVSVoidRequest (CustID, CategoryID, TVSRequestID, IsParlay, SportType, IssueTypeID, TVSReasonID, CreatedBy, CreatedDate, RequestTypeID, IsDisabled)
SELECT DISTINCT tvs.CustID, tvs.CategoryID , tvs.TVSRequestID, tvs.IsParlay, tvs.SportType, tvs.IssueTypeID, main.ReasonID, main.CreatedBy, main.CreatedDate, 1, cust.IsDisable
FROM Adhoc_TVSCustomer_DUP AS cust
	INNER JOIN Adhoc_TVSVoidRequest_CC AS tvs ON cust.CustID = tvs.CustID AND IFNULL(cust.TVSRequestID,0) =  IFNULL(tvs.TVSRequestID,0)
	INNER JOIN TVSVoidRequest_History AS main ON main.ID = cust.ID
UNION
SELECT DISTINCT tvs.CustID, tvs.CategoryID , tvs.TVSRequestID, tvs.IsParlay, tvs.SportType, tvs.IssueTypeID, main.ReasonID, main.CreatedBy, main.CreatedDate, 1, cust.IsDisable
FROM Adhoc_TVSCustomer_DUP2 AS cust
	INNER JOIN Adhoc_TVSVoidRequest_CCHis AS tvs ON cust.CustID = tvs.CustID AND IFNULL(cust.TVSRequestID,0) =  IFNULL(tvs.TVSRequestID,0)
	INNER JOIN TVSVoidRequest_History AS main ON main.ID = cust.ID
;

/*CC305-CC3005 -- distinct cc.CustID: 10135*/
UPDATE CTSCustomerClassification AS cc
	INNER JOIN CustomerLoginInfoDetection AS cld ON cld.CustID = cc.CustID
SET cc.Remark = NULL
WHERE cc.ParentID = 20000
	AND cc.CategoryID IN (21000,26000)
	AND cc.CustID >= 106954653	AND cc.CustID <= 165623851
;

