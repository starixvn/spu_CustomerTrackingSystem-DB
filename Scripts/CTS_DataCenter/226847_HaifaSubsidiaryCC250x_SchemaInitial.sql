/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250514@Casey.Huynh
Task:	 	HaifaSubsidiaryCC250x_SchemaInitial
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250514@Casey.Huynh: Created [Redmine ID #226847]

Reviewer:
*/

USE CTS_DataCenter;

#
/*
DROP TABLE IF EXISTS Customer_SpecialLicSubCC_Log;
CREATE TABLE Customer_SpecialLicSubCC_Log(
		ID				BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	Username		VARCHAR(50) NOT NULL
    ,	CustomerClass 	INT UNSIGNED NOT NULL
    ,	InsertedTime		DATETIME(4) NOT NULL
);
*/

DROP TABLE IF EXISTS Customer_SpecialLicSubCC;
CREATE TABLE Customer_SpecialLicSubCC(
		ID						INT UNSIGNED AUTO_INCREMENT PRIMARY KEY	
	,	Username				VARCHAR(50) NOT NULL
    ,	APICustomerClass 		INT UNSIGNED NOT NULL
    ,	LatestCustomerClass 	INT UNSIGNED NULL
    ,	CustID					BIGINT NULL
    ,	ProcessStatus			TINYINT NOT NULL DEFAULT 0	COMMENT '0:API INPUT, 1:Inprocess, 2:ClassifiedComplete, 3:ResponseFail, 4:ResponseSuccess'   
    ,	IsDisabled				TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0:Enabled, 1:Disabled'
    ,	StatusCode				INT NULL
    ,	ResponseTime			DATETIME(4) NULL
    ,	ResponseHttpCode		INT NULL
    ,	InsertedTime			DATETIME(4) NOT NULL
    
    ,	INDEX IX_Customer_Customer_SpecialLicSubCC_CustID(CustID)
    ,	INDEX IX_Customer_Customer_SpecialLicSubCC_ProcessStatusCustID(ProcessStatus, CustID)
);

# CustomerCategory
#CREATE TABLE CustomerCategory_CaseyBk20250514 SELECT * FROM CustomerCategory ;

UPDATE CustomerCategory
SET IsActive = 1
	, CustomerClassPriority = 850
	, CategoryPriority = (CASE WHEN CategoryID = 40606 THEN 845 ELSE 850 END)
    , RemarkTemplateID = 42
    , FlowNormalTaggingScan = 1
WHERE  CategoryID IN (40106,40406,40506,40606)
;

INSERT INTO StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,Description,CreatedDate)
VALUES(25,1,'LicSubCustomerClass','','LicSubCustomerClass_New','',200,NULL,NULL,NULL,1,NULL,NOW())
,(25,2,'LicSubCustomerClass','','LicSubCustomerClass_Probation','',203,NULL,NULL,NULL,1,NULL,NOW())
,(25,3,'LicSubCustomerClass','','LicSubCustomerClass_Smark','',204,NULL,NULL,NULL,1,NULL,NOW())
,(25,4,'LicSubCustomerClass','','LicSubCustomerClass_Risky','',205,NULL,NULL,NULL,1,NULL,NOW());

INSERT INTO StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,Description,CreatedDate)
VALUES(26,1,'LicSubStatusCode','','LicSubStatusCode_Successfully','Updated played CC Successfully',200,NULL,NULL,NULL,1,NULL,NOW())
,(26,2,'LicSubStatusCode','','LicSubStatusCode_Successfully','Updated played CC Successfully.However, the previous CC did not match',201,NULL,NULL,NULL,1,NULL,NOW())
,(26,3,'LicSubStatusCode','','LicSubStatusCode_Inprogress','LicSubStatusCode_Inprogress',300,NULL,NULL,NULL,1,NULL,NOW())
,(26,4,'LicSubStatusCode','','LicSubStatusCode_Fail','CC update failed, player CC does not match',400,NULL,NULL,NULL,1,NULL,NOW())
,(26,5,'LicSubStatusCode','','LicSubStatusCode_Fail','CC update failed, player CC does not fit the rule',401,NULL,NULL,NULL,1,NULL,NOW());

SELECT *
FROM CTS_DataCenter.StaticList WHERE ListID IN (25,26);

SELECT CustomerClassPriority, CategoryPriority, cat.*
FROM CustomerCategory cat
WHERE  CategoryID IN (40100,40400,40500,40600,40106,40406,40506,40606)
ORDER BY CustomerClassPriority DESC;

# CustomerCategorySettings == Existing will dupcheck flow
SELECT cat.CategoryName, cat.CategoryPriority, cat.CustomerClassPriority,  st.*
FROM CustomerCategorySettings st
	INNER JOIN CustomerCategory as cat ON st.CategoryID = cat.CategoryID
WHERE  cat.CategoryID IN (40100,40400,40500,40600,40106,40406,40506,40606,21100)
;





SELECT * FROM StaticList WHERE ListID = 6
SELECT * FROM StaticList where itemvalue IN (40100,40400,40500,40600);
SELECT * FROM StaticList where itemvalue IN (200,203,204,205);
# CustomerClassification_Remark == 
USE CTS_DataCenter;

SELECT *
FROM CustomerCategory
WHERE CustomerClass IN (200,203,204,205)

;
/*
DROP TEMPORARY TABLE IF EXISTS Temp_Priority;
create temporary table Temp_Priority(CustomerClassPriority INT,	CategoryPriority INT,	CategoryID INT);
INSERT INTO Temp_Priority
VALUE (10,10,1010)
,(900,300,10100)
,(310,320,10200)
,(300,300,10201)
,(200,200,10300)
,(400,400,20100)
,(400,400,20101)
,(400,400,20102)
,(400,400,20103)
,(400,400,20200)
,(400,400,20201)
,(400,400,20202)
,(400,400,20203)
,(400,400,20300)
,(400,400,20301)
,(400,400,20302)
,(400,400,20303)
,(400,400,20400)
,(400,400,20401)
,(400,400,20402)
,(400,400,20403)
,(400,400,20500)
,(400,400,20501)
,(400,400,20502)
,(400,400,20503)
,(400,400,20600)
,(400,400,20601)
,(400,400,20602)
,(400,400,20603)
,(400,400,20700)
,(400,400,20701)
,(400,400,20800)
,(400,400,20801)
,(400,400,20802)
,(400,400,20900)
,(420,420,21000)
,(570,570,21100)
,(400,400,21101)
,(400,400,21103)
,(580,580,21200)
,(400,400,21300)
,(400,400,21302)
,(400,400,21303)
,(400,400,21402)
,(400,400,21500)
,(400,400,21501)
,(400,400,21502)
,(400,400,21503)
,(400,400,21600)
,(400,400,21602)
,(400,400,21700)
,(400,400,21701)
,(570,570,21800)
,(400,400,25100)
,(400,400,25101)
,(400,400,25102)
,(400,400,25103)
,(400,400,25200)
,(400,400,25201)
,(400,400,25202)
,(400,400,25203)
,(400,400,25300)
,(400,400,25301)
,(400,400,25302)
,(400,400,25303)
,(400,400,25400)
,(400,400,25401)
,(400,400,25402)
,(400,400,25403)
,(400,400,25500)
,(400,400,25501)
,(400,400,25502)
,(400,400,25503)
,(400,400,25600)
,(400,400,25601)
,(400,400,25602)
,(400,400,25603)
,(400,400,25700)
,(400,400,25701)
,(400,400,25800)
,(400,400,25801)
,(400,400,25802)
,(400,400,25900)
,(420,420,26000)
,(570,570,26100)
,(580,580,26200)
,(570,570,26800)
,(530,530,30100)
,(500,500,30200)
,(450,450,30300)
,(530,530,35100)
,(500,500,35200)
,(450,450,35300)
,(1000,1000,40100)
,(800,800,40101)
,(800,800,40102)
,(800,800,40103)
,(600,600,40104)
,(750,750,40105)
,(550,550,40106)
,(1000,1000,40200)
,(800,800,40201)
,(800,800,40202)
,(800,800,40203)
,(600,600,40204)
,(750,750,40205)
,(1000,1000,40300)
,(800,800,40301)
,(800,800,40302)
,(800,800,40303)
,(600,600,40304)
,(750,750,40305)
,(1000,1000,40400)
,(800,800,40401)
,(800,800,40402)
,(800,800,40403)
,(600,600,40404)
,(750,750,40405)
,(550,550,40406)
,(1000,1000,40500)
,(800,800,40501)
,(800,800,40502)
,(800,800,40503)
,(600,600,40504)
,(750,750,40505)
,(550,550,40506)
,(1000,1000,40600)
,(800,795,40601)
,(800,795,40602)
,(800,795,40603)
,(600,595,40604)
,(750,745,40605)
,(550,545,40606)
,(1000,1000,40700)
,(1000,1000,40701);

UPDATE CustomerCategory AS cat
INNER JOIN Temp_Priority AS t ON cat.CategoryID = t.CategoryID
SET cat.CategoryPriority= t.CategoryPriority, cat.CustomerClassPriority = t.CustomerClassPriority;
*/