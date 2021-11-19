/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20211119@Casey.Huynh
Task:	 	Remove UnUsed Subscriber
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20211119@Casey.Huynh: Created [Redmine ID: #164521]
Reviewer:
*/
/****************Issue01.Remove UnUsed SubscriberID*************************/
# Remove Data CTSCustomerClassification_History
DELETE rev
FROM CTS_DataCenter.CTSCustomerClassification_History AS rev
	INNER JOIN CTS_Adhoc.CS164521_CTSCustomer AS cus ON cch.CustID = rev.CustID;
    
# Remove Data CTSCustomerClassification    
DELETE rev
FROM CTS_DataCenter.CTSCustomerClassification AS rev
	INNER JOIN CTS_Adhoc.CS164521_CTSCustomer AS cus ON cch.CustID = rev.CustID;

# Remove Data CTSCustomer    
DELETE rev
FROM CTS_DataCenter.CTSCustomer AS rev
	INNER JOIN CTS_Adhoc.CS164521_CTSCustomer AS cus ON cch.CustID = rev.CustID;  

# Remove Data MappingSubscriberSite
DELETE rev
FROM CTS_DataCenter.MappingSubscriberSite AS rev
WHERE rev.SubscriberID IN (4604,4605,4606,4607,4608,4609,4612,4613,4614,4615,4616,4617,4618,4619,4620,4621,4622,4623);

/* Get data CTSCustomer
USE CTS_Adhoc;
CREATE TABLE CS164521_CTSCustomer (
  `CTSCustID` bigint unsigned NOT NULL,
  `SubscriberID` int unsigned DEFAULT NULL,
  `CustID` int unsigned DEFAULT NULL,
  `CustSubID` int unsigned DEFAULT NULL,
  `UserName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `UserName2` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RegisterName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `SiteID` int DEFAULT NULL,
  `Site` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RoleID` tinyint DEFAULT NULL,
  `Currency` varchar(10) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `CurrencyID` int DEFAULT NULL,
  `SRecommend` int unsigned DEFAULT NULL,
  `MRecommend` int unsigned DEFAULT NULL,
  `Recommend` int unsigned DEFAULT NULL,
  `LastLoginTime` timestamp(4) NULL DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `CustStatusID` tinyint DEFAULT '0',
  `Danger1` tinyint DEFAULT '0',
  `Danger2` tinyint DEFAULT '0',
  `Danger3` tinyint DEFAULT '0',
  `InsertedTime` datetime(4) DEFAULT NULL COMMENT 'When row inserted',
  `ModifiedTime` datetime(4) DEFAULT NULL COMMENT 'When row modified',
  PRIMARY KEY (`CTSCustID`),
  UNIQUE INDEX CustIDCustSubID(CustID,CustSubID)
) ENGINE=InnoDB;

SELECT mms.* 
FROM CTS_DataCenter.MappingSubscriberSite AS mms 
LEFT JOIN CTS_Admin.Subscriber AS sub ON mms.SubscriberID = sub.SubscriberID
WHERE sub.SubscriberID IS NULL;

INSERT INTO CTS_Adhoc.CS164521_CTSCustomer
SELECT * FROM CTS_DataCenter.CTSCustomer WHERE SubscriberID IN (4604,4605,4606,4607,4608,4609,4612,4613,4614,4615,4616,4617,4618,4619,4620,4621,4622,4623);
*/
/****************Issue02. Remove UnUsed Site "BSA'" From MappingSubscriberSite *************************/
DELETE rev
FROM CTS_DataCenter.MappingSubscriberSite AS rev
WHERE SiteName = 'BSA' AND SubscriberID = 4611;
/*
SELECT * FROM CTS_DataCenter.MappingSubscriberSite AS rev
WHERE SubscriberID = 4611;*/
