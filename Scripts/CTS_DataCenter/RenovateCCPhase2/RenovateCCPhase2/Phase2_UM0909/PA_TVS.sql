DROP TEMPORARY TABLE IF EXISTS Adhoc_TVSCustomer;
CREATE TEMPORARY TABLE Adhoc_TVSCustomer
(
		ID 					BIGINT
	,	CustID				BIGINT
    ,TVSRequestID 		BIGINT
	, 	PRIMARY KEY (ID,CustID)
    , UNIQUE KEY UK_Temp (TVSRequestID,CustID)
);

DROP TEMPORARY TABLE IF EXISTS Adhoc_TVSVoidRequest_CC;
CREATE TEMPORARY TABLE Adhoc_TVSVoidRequest_CC
(
		ID 					BIGINT
	,	CustID				BIGINT
	,	CategoryID			INT
	,	CategoryID_new		INT
	,	TVSRequestID 		BIGINT
	,	ReasonID			INT
	,	CreatedBy 			INT
	,	CreatedDate 		DATE
	,	IsParlay 			TINYINT(1)
	,	SportType 			SMALLINT
	,	IssueTypeID 		TINYINT
	,	IsCheck		 		TINYINT(1) DEFAULT 0
	,	IsDisable			TINYINT(1) DEFAULT 0
	, 	PRIMARY KEY (ID, CustID)
	,	KEY IX_Temp_CustID_CategoryID (CustID, CategoryID)
);

INSERT IGNORE INTO Adhoc_TVSCustomer (ID, CustID, TVSRequestID)
SELECT h.ID, js.CustID, h.TVSRequestID
FROM TVSVoidRequest_History AS h
	INNER JOIN JSON_TABLE(REPLACE(JSON_ARRAY(h.CustIDs), ',', '","'), 
									'$[*]' COLUMNS (CustID BIGINT UNSIGNED PATH '$')
									) js
	INNER JOIN CTSCustomer AS cust ON cust.CustID = js.CustID AND cust.CustSubID = 0
-- WHERE h.ID = 117631
ORDER BY h.ID DESC;

INSERT IGNORE INTO Adhoc_TVSVoidRequest_CC (ID, CustID, CategoryID, TVSRequestID, IsParlay, SportType, IssueTypeID, IsCheck)
SELECT 	tvs.ID
	, 	h.CustID
	, 	h.CategoryID
	, 	h.TVSRequestID
	, 	h.IsParlay
	, 	h.SportType
	, 	h.IssueTypeID
	,	CASE WHEN cc.CustID IS NULL THEN 0 ELSE 1 END AS IsCheck
FROM CTSCustomerClassification_History AS h
	INNER JOIN Adhoc_TVSCustomer AS tvs ON tvs.CustID = h.CustID
	INNER JOIN CustomerCategory AS cate ON cate.CategoryID = h.CategoryID
	INNER JOIN CustomerCategory AS relcate ON relcate.CategoryID = cate.RelevantCategoryID
	LEFT JOIN CTSCustomerClassification AS cc ON h.CustID = cc.CustID AND cc.IsFromTVS = 1 AND (cc.CategoryID = cate.CategoryID OR cc.CategoryID = relcate.CategoryID)
WHERE h.IsFromTVS = 1 
-- AND h.CategoryID NOT IN (163,164)
;