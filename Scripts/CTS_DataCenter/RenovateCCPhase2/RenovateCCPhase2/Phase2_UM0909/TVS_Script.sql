DROP TEMPORARY TABLE IF EXISTS Adhoc_TVSCustomer;
CREATE TEMPORARY TABLE Adhoc_TVSCustomer
(
		ID 					BIGINT
	,	CustID				BIGINT
	, 	PRIMARY KEY (ID, CustID)
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
	, 	PRIMARY KEY (ID)
	,	KEY IX_Temp_CustID_CategoryID (CustID, CategoryID)
);

INSERT IGNORE INTO Adhoc_TVSCustomer (ID, CustID)
SELECT h.ID, js.CustID
FROM TVSVoidRequest_History AS h
	INNER JOIN JSON_TABLE(REPLACE(JSON_ARRAY(h.CustIDs), ',', '","'), 
									'$[*]' COLUMNS (CustID BIGINT UNSIGNED PATH '$')
									) js
	INNER JOIN CTSCustomer AS cust ON cust.CustID = js.CustID AND cust.CustSubID = 0
WHERE h.ID IN (173982,173983)
	AND h.ReasonID NOT IN (36,10500)
ORDER BY h.ID DESC;

INSERT INTO Adhoc_TVSVoidRequest_CC (ID, CustID, CategoryID, TVSRequestID, IsParlay, SportType, IssueTypeID, IsCheck)
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
WHERE h.IsFromTVS = 1 AND h.CategoryID NOT IN (163,164)
	AND h.ID >= 246549533 AND h.ID <= 1081107112
;

UPDATE Adhoc_TVSVoidRequest_CC AS tvscc
	INNER JOIN Adhoc_TVSCustomer AS tvs ON tvs.CustID = tvscc.CustID
	INNER JOIN TVSVoidRequest_History AS tvshis ON tvshis.ID = tvs.ID
SET tvscc.ReasonID = tvshis.ReasonID
, 	tvscc.CreatedBy = tvshis.CreatedBy
, 	tvscc.CreatedDate = tvshis.CreatedDate
, 	tvscc.IsDisable = CASE WHEN (tvscc.TVSRequestID = tvshis.TVSRequestID AND tvscc.IsParlay = tvshis.IsParlay AND tvscc.SportType = tvshis.SportType AND tvscc.IssueTypeID = tvshis.IssueTypeID) 
								THEN 0 
							 ELSE 1 END
WHERE tvscc.IsCheck = 1;
;

select * from Adhoc_TVSVoidRequest_CC;

										