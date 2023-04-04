/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	202304035@Casey.Huynh
Task:	 	Update Setting mapping sub-site and correct data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 202304035@Casey.Huynh: Created [Redmine ID: #186086]
Reviewer:
*/

USE CTS_DataCenter;

#==================================1. UPDATE TABLE MappingSubscriberSite=============================================================================
UPDATE CTS_DataCenter.MappingSubscriberSite 
SET SubscriberID = 13659
	,	SubscriberName = 'AlphaIBCIndo'
    ,	Comments = CONCAT(current_date(),'#186086')
WHERE SiteName = '76666B' AND RoleMapping = 2;

UPDATE CTS_DataCenter.MappingSubscriberSite 
SET SubscriberID = 13658
	,	SubscriberName = 'IBCIndo'
    ,	Comments = CONCAT(current_date(),'#186086')
WHERE SiteName = '76666B' AND RoleMapping = 1;

SELECT * FROM CTS_DataCenter.MappingSubscriberSite WHERE SubscriberName IN ( 'IBCIndo', 'AlphaIBCIndo');

#======================================2. CORRECT SubscriberID FOR '76666B' Customer======================================

#====================2.1 UPDATE SUBSCRIBERID FOR OTHER TABLES BASE ON CTSCustomer TABLE===========================================
#====================2.1.0 GET Customer to update===================================
USE CTS_Adhoc;
DROP TABLE IF EXISTS zz186086_CTSCustomer;
CREATE TABLE zz186086_CTSCustomer(
		CTSCustID BIGINT PRIMARY KEY
	,	CustID BIGINT
    ,	CustSubID BIGINT
    ,	RoleID INT
    ,	SubscriberID INT
    ,	SiteID INT
    ,	ToSubscriberID INT
    ,	INDEX zz186086_CTSCustomer_SubscriberID(SubscriberID)
);

USE CTS_DataCenter;
INSERT INTO CTS_Adhoc.zz186086_CTSCustomer (CTSCustID, CustID, CustSubID, RoleID, SubscriberID, SiteID, ToSubscriberID)
SELECT CTSCustID, CustID, CustSubID, RoleID, SubscriberID, SiteID
	, 13658 AS ToSubscriberID
FROM CTS_DataCenter.CTSCustomer AS cus
WHERE SiteID = 547 AND SubscriberID = 130;

INSERT INTO CTS_Adhoc.zz186086_CTSCustomer (CTSCustID, CustID, CustSubID, RoleID, SubscriberID, SiteID, ToSubscriberID)
SELECT CTSCustID, CustID, CustSubID, RoleID, SubscriberID, SiteID
	, 13659 AS ToSubscriberID
FROM CTS_DataCenter.CTSCustomer AS cus
WHERE SiteID = 547 AND SubscriberID = 2;

SELECT * FROM CTS_Adhoc.zz186086_CTSCustomer;

#====================2.1.2 UPDATE Subscriber for CTSCustomer===================================
SELECT COUNT(1) FROM CTS_DataCenter.CTSCustomer AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.CTSCustomer AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.CTSCustomer AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.ToSubscriberID;
#====================2.1.3 UPDATE Subscriber for AssociationByDevice===================================
SELECT COUNT(1) FROM CTS_DataCenter.AssociationByDevice AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.AssociationByDevice AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.AssociationByDevice AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.ToSubscriberID;

#====================2.1.4 UPDATE Subscriber for AssociationRemove===================================
SELECT COUNT(1) FROM CTS_DataCenter.AssociationRemove AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.FromCTSCustID;
SELECT COUNT(1) FROM CTS_DataCenter.AssociationRemove AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.ToCTSCustID;
SELECT * FROM CTS_DataCenter.AssociationRemove AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.FromCTSCustID;
SELECT * FROM CTS_DataCenter.AssociationRemove AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.ToCTSCustID;

UPDATE CTS_DataCenter.AssociationRemove AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.FromCTSCustID
SET t.FromSubscriberID = s.ToSubscriberID;

UPDATE CTS_DataCenter.AssociationRemove AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.ToCTSCustID
SET t.ToSubscriberID = s.ToSubscriberID;

#====================2.1.5 UPDATE Subscriber for CTSCustomerClassification===================================
SELECT COUNT(1) FROM CTS_DataCenter.CTSCustomerClassification AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.CTSCustomerClassification AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.CTSCustomerClassification AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.ToSubscriberID;

#====================2.1.6 UPDATE Subscriber for CTSCustomerClassificationOldCategory===================================
SELECT COUNT(1) FROM CTS_DataCenter.CTSCustomerClassificationOldCategory AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.CTSCustomerClassificationOldCategory AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.CTSCustomerClassificationOldCategory AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.ToSubscriberID;

#====================2.1.7 UPDATE Subscriber for CTSCustomerClassificationQueue===================================
SELECT COUNT(1) FROM CTS_DataCenter.CTSCustomerClassificationQueue AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.CTSCustomerClassificationQueue AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.CTSCustomerClassificationQueue AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.ToSubscriberID;

#====================2.1.8 UPDATE Subscriber for CTSCustomerClassificationVVIP===================================
SELECT COUNT(1) FROM CTS_DataCenter.CTSCustomerClassificationVVIP AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.CTSCustomerClassificationVVIP AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.CTSCustomerClassificationVVIP AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.ToSubscriberID;

#====================2.1.10 UPDATE Subscriber for CTSCustomerDuplicate===================================
UPDATE CTS_DataCenter.CTSCustomerDuplicate AS t 
SET t.SubscriberID = 13658
WHERE Site = '76666B' AND RoleID = 1;

UPDATE CTS_DataCenter.CTSCustomerDuplicate AS t 
SET t.SubscriberID = 13659
WHERE Site = '76666B' AND RoleID > 1;

#====================2.1.11 UPDATE Subscriber for CustDCSAccount===================================
SELECT COUNT(1) FROM CTS_DataCenter.CustDCSAccount AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.CustDCSAccount AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.CustDCSAccount AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.ToSubscriberID;

#====================2.1.12 UPDATE Subscriber for CustEvidenceFromFile===================================
SELECT COUNT(1) FROM CTS_DataCenter.CustEvidenceFromFile AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.CustEvidenceFromFile AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.CustEvidenceFromFile AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.ToSubscriberID;

#====================2.1.13 UPDATE Subscriber for CustEvidenceQueue===================================
SELECT COUNT(1) FROM CTS_DataCenter.CustEvidenceQueue AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.CustEvidenceQueue AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.CustEvidenceQueue AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.ToSubscriberID;

#====================2.1.14 UPDATE Subscriber for SpecialCustomerClass===================================
SELECT COUNT(1) FROM CTS_DataCenter.SpecialCustomerClass AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.SpecialCustomerClass AS t INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.SpecialCustomerClass AS t 
	INNER JOIN CTS_Adhoc.zz186086_CTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = s.ToSubscriberID;

#=**********************************************************************************************************************==#
#====================2.2 UPDATE SubscriberID BASE ON ArchiveCustomer_CTSCustomer===================================
USE CTS_Adhoc;
DROP TABLE IF EXISTS zz186086_ArchiveCustMainDB;
CREATE TABLE zz186086_ArchiveCustMainDB(
		CustID	INT PRIMARY KEY
    ,	RoleID	INT
    ,	SiteID	VARCHAR(50)
    ,	INDEX IX_zz186086_ArchiveCust_RoleID(RoleID)
);

DROP TABLE IF EXISTS zz186086_ArchiveCTSCustomer;
CREATE TABLE zz186086_ArchiveCTSCustomer(
		CTSCustID BIGINT PRIMARY KEY
	,	CustID BIGINT
    ,	CustSubID BIGINT
    ,	RoleID INT
    ,	SubscriberID INT
    ,	SiteID INT
    ,	ToSubscriberID INT
    ,	INDEX zz186086_ArchiveCTSCustomer_SubscriberID(SubscriberID)
);
#====================MAINDB: Get Archive Cust then import into CTS_Adhoc.zz186086_ArchiveCust
Server Ailas: DBARCCUST
DB Name: bodb_Customer

SELECT CustID, RoleID, Site
FROM bodb_Customer.dbo.Customer_Old 
WHERE Site = '76666B';
#======================================================================================
USE CTS_DataCenter;
INSERT INTO CTS_Adhoc.zz186086_ArchiveCTSCustomer (CTSCustID, CustID, CustSubID, RoleID, SubscriberID, SiteID, ToSubscriberID)
SELECT cus.CTSCustID, cus.CustID, cus.CustSubID, cus.RoleID, cus.SubscriberID, 547 AS SiteID
	, 13658 AS ToSubscriberID
FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS cus
	INNER JOIN CTS_Adhoc.zz186086_ArchiveCustMainDB AS arc ON cus.CustID = arc.CustID
WHERE arc.RoleID = 1;

INSERT INTO CTS_Adhoc.zz186086_ArchiveCTSCustomer (CTSCustID, CustID, CustSubID, RoleID, SubscriberID, SiteID, ToSubscriberID)
SELECT cus.CTSCustID, cus.CustID, cus.CustSubID, cus.RoleID, cus.SubscriberID, 547 AS SiteID
	, 13659 AS ToSubscriberID
FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS cus
	INNER JOIN CTS_Adhoc.zz186086_ArchiveCustMainDB AS arc ON cus.CustID = arc.CustID
WHERE arc.RoleID > 1;

SELECT * FROM CTS_Adhoc.zz186086_ArchiveCTSCustomer;
#======================================================================================
SELECT COUNT(1) FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS t INNER JOIN CTS_Adhoc.zz186086_ArchiveCTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;
SELECT * FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS t INNER JOIN CTS_Adhoc.zz186086_ArchiveCTSCustomer AS s WHERE s.CTSCustID = t.CTSCustID;

UPDATE CTS_DataCenter.ArchiveCustomer_CTSCustomer AS t 
	INNER JOIN CTS_Adhoc.zz186086_ArchiveCTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = 13658
WHERE s.RoleID = 1;

UPDATE CTS_DataCenter.ArchiveCustomer_CTSCustomer AS t 
	INNER JOIN CTS_Adhoc.zz186086_ArchiveCTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET t.SubscriberID = 13659
WHERE s.RoleID IN (2,3,4);

UPDATE DCS_DataCenter.Account AS acc
	INNER JOIN CTS_DataCenter.ArchiveCustomer_CTSCustomer AS t ON acc.AccountID = t.AccountID
	INNER JOIN CTS_Adhoc.zz186086_ArchiveCTSCustomer AS s ON s.CTSCustID = t.CTSCustID
SET acc.IsCTSTransformed = -1;

UPDATE CTS_DataCenter.ArchiveCustomer_CTSCustomer AS t 
	INNER JOIN CTS_Adhoc.zz186086_ArchiveCTSCustomer AS s ON s.CTSCustID = t.CTSCustID
    INNER JOIN DCS_DataCenter.Account AS acc ON t.UserName = acc.LoginName AND t.SubscriberID = acc.SubscriberID
SET t.AccountID = acc.AccountID;

UPDATE CTS_DataCenter.ArchiveCustomer_CTSCustomer AS t 
	INNER JOIN CTS_Adhoc.zz186086_ArchiveCTSCustomer AS s ON s.CTSCustID = t.CTSCustID
    INNER JOIN DCS_DataCenter.Account AS acc ON t.UserName2 = acc.LoginName AND t.SubscriberID = acc.SubscriberID
SET t.AccountID = acc.AccountID;   

#=**********************************************************************************************************************==#
#===================3. Re-Transform DCS ===============================================================================
USE DCS_DataCenter;
SELECT COUNT(1) FROM DCS_DataCenter.`Account` WHERE SubscriberID IN (13658, 13659) AND IsCTSTransformed = -1;

UPDATE DCS_DataCenter.`Account` AS acc
SET acc.IsCTSTransformed = 0
WHERE SubscriberID IN (13658, 13659) AND IsCTSTransformed = -1;

#=================4. DROP ===========================================
DROP PROCEDURE CTS_DC_CustClassification_RemoveVVIP_xtest;
DROP PROCEDURE CTS_DC_CustClassification_RemoveVVIP;
DROP TABLE CTSCustomerClassificationVVIPQueue;