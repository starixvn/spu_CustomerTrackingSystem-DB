/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240923@Jonas.Huynh
Task:	 	script updata data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240923@Jonas.Huynh: Created  [RedmineID: #209792]
Reviewer:
*/
DROP TEMPORARY TABLE IF EXISTS tempCustomerCategory2;    
CREATE TEMPORARY TABLE tempCustomerCategory2 LIKE CustomerCategory;

INSERT INTO tempCustomerCategory2 
SELECT * 
FROM CustomerCategory;

UPDATE CTS_DataCenter.tempCustomerCategory2 SET CategoryPriority = 580, CustomerClassPriority = 580 WHERE CategoryID = 21200;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET CategoryPriority = 580, CustomerClassPriority = 580 WHERE CategoryID = 26200;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET CategoryPriority = 570, CustomerClassPriority = 570 WHERE CategoryID = 21100;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET CategoryPriority = 570, CustomerClassPriority = 570 WHERE CategoryID = 26100;

UPDATE CTS_DataCenter.tempCustomerCategory2 SET ParentID = 20000, CategoryPriority = 530, CustomerClassPriority = 530 WHERE CategoryID = 30100;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET ParentID = 20000, CategoryPriority = 530, CustomerClassPriority = 530 WHERE CategoryID = 35100;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET ParentID = 20000, CategoryPriority = 500, CustomerClassPriority = 500 WHERE CategoryID = 30200;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET ParentID = 20000, CategoryPriority = 500, CustomerClassPriority = 500 WHERE CategoryID = 35200;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET ParentID = 20000, CategoryPriority = 450, CustomerClassPriority = 450 WHERE CategoryID = 30300;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET ParentID = 20000, CategoryPriority = 450, CustomerClassPriority = 450 WHERE CategoryID = 35300;

UPDATE CTS_DataCenter.tempCustomerCategory2 SET CategoryPriority = 745, CustomerClassPriority = 750 WHERE CategoryID = 40605;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET CategoryPriority = 750, CustomerClassPriority = 750 WHERE CategoryID = 40405;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET CategoryPriority = 750, CustomerClassPriority = 750 WHERE CategoryID = 40505;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET CategoryPriority = 595, CustomerClassPriority = 600 WHERE CategoryID = 40604;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET CategoryPriority = 600, CustomerClassPriority = 600 WHERE CategoryID = 40404;
UPDATE CTS_DataCenter.tempCustomerCategory2 SET CategoryPriority = 750, CustomerClassPriority = 750 WHERE CategoryID = 40405;

DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
CREATE TEMPORARY TABLE Temp_Customers(
		CustID					BIGINT UNSIGNED
	,	CTSCustID				BIGINT UNSIGNED
    ,   CategoryID 				INT NOT NULL   
    ,	RelevantCategoryID 		INT NOT NULL 
    ,	CustomerClassPriority 	SMALLINT NOT NULL 
    ,	CustomerClass 			INT NOT NULL 
    ,	RelevantCustomerClass 	INT NOT NULL 
    , 	PRIMARY KEY (CustID, CategoryID)
);

INSERT INTO Temp_Customers(CTSCustID, CustID, CategoryID, RelevantCategoryID, CustomerClassPriority, CustomerClass, RelevantCustomerClass)
SELECT c.CTSCustID
	,	cis.CustID
	,	30300
	, 	35300
    ,	450
    , 	2600
    ,	2601
FROM Customer_InitialGroupBetting cis   
	INNER JOIN CTSCustomer AS c ON c.CustID = cis.CustID
WHERE NOT EXISTS (SELECT 1 FROM CTSCustomerClassification cc WHERE cc.CustID = cis.CustID AND cc.CategoryID IN (35300,30300));

INSERT INTO Temp_Customers(CTSCustID, CustID, CategoryID, RelevantCategoryID, CustomerClassPriority, CustomerClass, RelevantCustomerClass)
SELECT c.CTSCustID
	,	cis.CustID
	, 	30200
	, 	35200
    ,	500
    ,	2700
    ,	2701
FROM Customer_InitialSmart cis   
	 INNER JOIN CTSCustomer AS c ON c.CustID = cis.CustID
WHERE NOT EXISTS (SELECT 1 FROM CTSCustomerClassification cc WHERE cc.CustID = cis.CustID AND cc.CategoryID IN (35200,30200));      

INSERT INTO Temp_Customers(CTSCustID, CustID, CategoryID, RelevantCategoryID, CustomerClassPriority, CustomerClass, RelevantCustomerClass)
SELECT c.CTSCustID
	,	cis.CustID
	,	30100
	,	35100
    ,	530
    ,	2800
    ,	2801
FROM Customer_DangerousScore  cis
	INNER JOIN CTSCustomer AS c ON c.CustID = cis.CustID AND cis.ClassifiedScore IS NOT NULL
WHERE NOT EXISTS (SELECT 1 FROM CTSCustomerClassification cc WHERE cc.CustID = cis.CustID AND cc.CategoryID IN (35100,30100));

SELECT COUNT(1) FROM Temp_Customers;

SELECT tmp.CTSCustID
	,	tmp.CustID
	,	MIN(cc.CreatedDate)
	,	GROUP_CONCAT(cc.CategoryID)			AS 'From CategoryID'
	,	GROUP_CONCAT(cate.CategoryName)		AS 'From Category Name'
	,	(SELECT CASE WHEN sp.CustomerClass IS NOT NULL THEN sp.CustomerClass ELSE cate.CustomerClass END AS CustomerClass
		 FROM CTSCustomerClassification cc 
			INNER JOIN CustomerCategory cate ON cc.CategoryID = cate.CategoryID
			LEFT JOIN SpecialCustomerClass sp ON sp.CustID = tmp.CTSCustID 
		 WHERE tmp.CTSCustID = cc.CTSCustID 
		 ORDER BY cate.CustomerClassPriority ASC, cc.LastModifiedDate DESC 
		 LIMIT 1) AS 'From CC'
	,	 CASE WHEN GROUP_CONCAT(cate.IsPAProbation + 0) Like '%1%' AND (GROUP_CONCAT(cc.ParentID) LIKE ('%20000%') OR GROUP_CONCAT(cc.ParentID) LIKE ('%30000%')) THEN CONCAT(GROUP_CONCAT(cc.CategoryID), ",", GROUP_CONCAT(DISTINCT(tmp.RelevantCategoryID)))                                
              WHEN GROUP_CONCAT(cate.IsPAProbation + 0) NOT Like '%1%' AND (GROUP_CONCAT(cc.ParentID) LIKE ('%20000%') OR GROUP_CONCAT(cc.ParentID) LIKE ('%30000%')) THEN CONCAT(GROUP_CONCAT(cc.CategoryID), ",", GROUP_CONCAT(DISTINCT(tmp.CategoryID)))                       
			  ELSE CONCAT(GROUP_CONCAT(tmp.RelevantCategoryID), " or ", GROUP_CONCAT(tmp.CategoryID))
         END AS 'To CategoryID' 
	,	( SELECT CASE WHEN sp.CustomerClass IS NOT NULL THEN sp.CustomerClass 
                     WHEN cate2.CustomerClassPriority > MIN(tmp.CustomerClassPriority) AND cate2.IsPAProbation = 1 THEN MIN(tmp.RelevantCustomerClass) 
                     WHEN cate2.CustomerClassPriority > MIN(tmp.CustomerClassPriority) AND cate2.IsPAProbation <> 1 THEN MIN(tmp.CustomerClass)  
				     ELSE cate2.CustomerClass END AS CustomerClass
		  FROM CTSCustomerClassification cls 
			INNER JOIN tempCustomerCategory2 cate2 ON cls.CategoryID = cate2.CategoryID
			LEFT JOIN SpecialCustomerClass sp ON sp.CustID = cls.CustID 
		  WHERE cls.CTSCustID = tmp.CTSCustID
          ORDER BY cate2.CustomerClassPriority ASC, cls.LastModifiedDate DESC 
          LIMIT 1) AS 'To CC'
FROM Temp_Customers AS tmp
    LEFT JOIN CTSCustomerClassification cc ON cc.CustID = tmp.CustID
    LEFT JOIN CustomerCategory cate ON cate.CategoryID = cc.CategoryID            
GROUP BY tmp.CustID, tmp.CTSCustID                                
ORDER BY tmp.CTSCustID DESC;