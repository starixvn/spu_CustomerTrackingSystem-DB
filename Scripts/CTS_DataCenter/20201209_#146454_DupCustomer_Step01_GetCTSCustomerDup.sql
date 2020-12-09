/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Created: 202012090@CaseyHuynh
Task: 	 Fix Data CTSCustomer Duplicate
DB: 	 CTS_DataCenter
*/
/************************ STEP01 ---GET DUPLICATE CUSTOMER*****************************************/
USE CTS_Adhoc;

TRUNCATE TABLE CTS_Adhoc.Iss145271_CTSCustomerDup;
INSERT INTO CTS_Adhoc.Iss145271_CTSCustomerDup
SELECT 	cus1.*, NULL
FROM 	CTS_DataCenter.CTSCustomer cus1 
INNER JOIN 	(SELECT  custID
		FROM 	CTS_DataCenter.CTSCustomer cus
		WHERE	CustSubID = 0
		Group by custID
		Having count(1) > 1) dup
        ON cus1.custID = dup.CustID;

UPDATE  	`CTS_Adhoc`.`Iss145271_CTSCustomerDup` AS a
INNER JOIN  `CTS_Adhoc`.`Iss145271_CTSCustomerDup` AS b
			ON a.CTSCustID > b.CTSCustID and a.CustID = b.CustID
SET 		a.CorrectedCTSCustID = b.CTSCustID;
/*
CREATE TABLE CTS_Adhoc.`Iss145271_CTSCustomerDup` (
  `CTSCustID` bigint(20) unsigned NOT NULL,
  `SubscriberID` int(10) unsigned DEFAULT NULL,
  `CustID` int(10) unsigned DEFAULT NULL,
  `CustSubID` int(10) unsigned DEFAULT NULL,
  `UserName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `UserName2` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RegisterName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `SiteID` int(11) DEFAULT NULL,
  `Site` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RoleID` tinyint(4) DEFAULT NULL,
  `Currency` varchar(10) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `CurrencyID` int(11) DEFAULT NULL,
  `SRecommend` int(10) unsigned DEFAULT NULL,
  `MRecommend` int(10) unsigned DEFAULT NULL,
  `Recommend` int(10) unsigned DEFAULT NULL,
  `LastLoginTime` timestamp(4) NULL DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `CustStatusID` tinyint(4) DEFAULT '0',
  `Danger1` tinyint(4) DEFAULT '0',
  `Danger2` tinyint(4) DEFAULT '0',
  `Danger3` tinyint(4) DEFAULT '0',
  `InsertedTime` datetime(4) DEFAULT NULL COMMENT 'When row inserted',
  `ModifiedTime` datetime(4) DEFAULT NULL COMMENT 'When row modified',
  CorrectedCTSCustID bigint(20) unsigned,
  PRIMARY KEY (`CTSCustID`),
  UNIQUE KEY `UK_CTSCustomer_04062020_SubID_UserName_UserName2` (`SubscriberID`,`UserName`,`UserName2`),
  KEY `IX_CTSCustomer_04062020_UserName` (`UserName`),
  KEY `IX_CTSCustomer_04062020_UserName2` (`UserName2`),
  KEY `IX_CTSCustomer_04062020_RegisterName` (`RegisterName`),
  KEY `IX_CTSCustomer_04062020_CustID_CustSubID` (`CustID`,`CustSubID`),
  KEY `IX_CTSCustomer_RoleID` (`RoleID`),
  KEY `IX_CTSCustomer_SRecommend_RoleID` (`SRecommend`,`RoleID`)
) ENGINE=InnoDB;
*/