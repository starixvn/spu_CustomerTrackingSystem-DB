/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20220627@Casey.Huynh
Task:	 	Fix Missing VVIP
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20220627@Casey.Huynh: Created [Redmine ID: #174549]
Reviewer:
*/


/* Step01. GET List VVIP SMA CTSCustomerClassificationVVIP WITH====================
   - IsDirect IS NULL: the VVIP added before "Renovation PA"
   - IsAffectToDownline = 0: Maybe Issue record
   - JOIN WITH CTSCustomerClassification_History WHERE SourceTypeID = 30 --> Affected BY UPLINE
*/
DROP TEMPORARY TABLE IF EXISTS Temp_VVIPCust;
CREATE TEMPORARY TABLE Temp_VVIPCust(
  ID bigint unsigned NOT NULL AUTO_INCREMENT,
  CTSCustID bigint unsigned DEFAULT NULL,
  CustID bigint unsigned DEFAULT NULL,
  RoleID tinyint DEFAULT NULL,
  SubscriberID int unsigned DEFAULT NULL,
  CreatedBy bigint unsigned DEFAULT NULL,
  Remark varchar(300) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (ID)
  , UNIQUE KEY UX_Temp_VVIPCust(CustID)
  , KEY IX_CTSCustomerClassificationQueue_CustID (CustID)
) ENGINE=InnoDB;

INSERT INTO Temp_VVIPCust(CTSCustID,CustID,RoleID,SubscriberID,CreatedBy,Remark)
SELECT 	vip.CTSCustID
	,	vip.CustID,vip.RoleID,vip.SubscriberID,vip.CreatedBy,vip.Remark
FROM CTSCustomerClassificationVVIP AS vip
INNER JOIN CTSCustomerClassification_History AS his ON vip.CustID = his.CustID
INNER JOIN StaticList s ON his.SourceTypeID = s.ItemID AND ListID = 4
WHERE vip.IsAffectToDownline = 0 
	AND vip.RoleID > 1 
    AND his.SourceTypeID = 30 
    AND vip.IsDirect IS NULL;
    
/* Step 02: UPDATE CTSCustomerClassificationVVIP vip
	JOIN with Step1 Result    
*/
UPDATE CTSCustomerClassificationVVIP AS vip
INNER JOIN Temp_VVIPCust AS tmpVvip ON vip.CustID = tmpVvip.CustID
SET		vip.IsDirect = 0
	,	vip.IsAffectToDownline = 1;

/* Step 03: INSERT TO Queue AND UPDATE SourceTypeID = 30 After DOne 
	JOIN with Step1 Result    
*/

SET @MaxHistoryID = (SELECT MAX(ID) FROM CTSCustomerClassification_History AS his);

INSERT INTO CTSCustomerClassificationQueue (ID, CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, CategoryGroup, CategoryID, LastDownlineCTSCustID, ActionType, InsertTime, IsFromCTS, IsDirect)
SELECT tmpVvip.ID, tmpVvip.CTSCustID, tmpVvip.CustID, tmpVvip.RoleID, tmpVvip.SubscriberID, CreatedBy, 'HF174549' AS Remark, 
	210 AS CategoryGroup, 210 AS CategoryID, 0 AS LastDownlineCTSCustID, 1 AS ActionType, CURRENT_TIMESTAMP(3) InsertTime, 1 AS IsFromCTS, 0 AS IsDirect
FROM Temp_VVIPCust AS tmpVvip;

/*****WAIT QUEUE RUN DONE DATA********************/

/******UPDATE SourceTypeID FOR AGENT*************/   
UPDATE CTS_DataCenter.CTSCustomerClassification_History AS his
	INNER JOIN CTS_DataCenter.CTSCustomerClassificationVVIP AS vvip ON his.CTSCustID = vvip.CTSCustID AND vvip.IsDirect = 0
	INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON vvip.CustID = cus.Recommend AND cus.RoleID = 2
	INNER JOIN  Temp_VVIPCust AS tmpVvip ON tmpVvip.CustID = cus.Mrecommend
SET his.SourceTypeID = 30, his.LastModifiedBy = 10278938,  his.Remark = ''
WHERE his.ID > @MaxHistoryID AND his.CategoryID = 210 AND his.Remark = 'HF174549';

/******UPDATE SourceTypeID FOR MEMBER*************/   
UPDATE CTS_DataCenter.CTSCustomerClassification_History AS his
	INNER JOIN CTS_DataCenter.CTSCustomerClassificationVVIP AS vvip ON his.CTSCustID = vvip.CTSCustID AND vvip.IsDirect = 0
	INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON vvip.CustID = cus.CustID AND cus.RoleID = 1
	INNER JOIN  Temp_VVIPCust AS tmpVvip ON tmpVvip.CustID IN (cus.Mrecommend, cus.Recommend)
SET his.SourceTypeID = 30, his.LastModifiedBy = 10278938, his.Remark = ''
WHERE his.ID > @MaxHistoryID AND his.CategoryID = 210 AND his.Remark = 'HF174549';
    
/*Step04: Innit data before VVIP Downline launched*/
INSERT INTO CTS_DataCenter.CTSCustomerClassificationVVIP(CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, CategoryID, IsAffectToDownline, InsertTime, IsDirect)
SELECT cls.CTSCustID, cls.CustID, cus.RoleID, cus.Subkhông scriberID, cls.CreatedBy, cls.Remark, cls.CategoryID,  0 AS IsAffectToDownline, cls.CreatedDate, 1 AS IsDirect
FROM CTS_DataCenter.CTSCustomerClassification AS cls
	INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = cls.CTSCustID
LEFT JOIN CTS_DataCenter.CTSCustomerClassificationVVIP AS vvip ON cls.CTSCustID = vvip.CTSCustID
WHERE cls.CategoryID = 210 AND vvip.CTSCustID IS NULL;

