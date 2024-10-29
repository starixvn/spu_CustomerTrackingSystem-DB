/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241025@Casey.Huynh
Task:	 	Migrate Data COOK Data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241025@Casey.Huynh: Created [Redmine ID: #185799]
Reviewer:
*/

USE CTS_DataCenter;                
BEGIN;#============STEP 1: COOK Adhoc_F185799Mig_CTSCustomerClassification ==========EST: Duration(~80.358 sec) RowCount(~13K)=======================
********STEP 1.1 GET BY JOIN CTSCustomer*********
INSERT INTO CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification(Migrate_Source,Migrate_IsLicensee,Migrate_Currency,Migrate_IsInternal
, Migrate_ToRoleID,Migrate_ToSubscriberID
, CustID,CTSCustID,SubscriberID,RoleID,IsAffectToDownline,ParentID,CategoryID,Remark,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,LastScannedDate,IsFromTVS,IsFromTW,IsFromCTS,IsMarkedDirectly,TVSRequestID,IsFromAI,IsFromImperva,IsParlay,SportType,IssueTypeID)
SELECT 	1 AS Migrate_Source
	,	cus.IsLicensee AS Migrate_IsLicensee
    ,	cus.Currency AS Migrate_Currency
    ,	cus.IsInternal AS Migrate_IsInternal
    
    , 	cus.RoleID AS Migrate_ToRoleID
    ,	cus.SubscriberID AS Migrate_ToSubscriberID
    
	,	cls.CustID
	,	cls.CTSCustID
	,	cls.SubscriberID
	,	cls.RoleID
	,	cls.IsAffectToDownline
	,	cls.ParentID
	,	cls.CategoryID
	,	cls.Remark
	,	cls.CreatedDate
	,	cls.CreatedBy
	,	cls.LastModifiedDate
	,	cls.LastModifiedBy
	,	cls.LastScannedDate
	,	cls.IsFromTVS
	,	cls.IsFromTW
	,	cls.IsFromCTS
	,	cls.IsMarkedDirectly
	,	cls.TVSRequestID
	,	cls.IsFromAI
	,	cls.IsFromImperva
	,	cls.IsParlay
	,	cls.SportType
	,	cls.IssueTypeID
FROM CTS_DataCenter.CTSCustomer AS cus
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON cls.CustID = cus.CustID
WHERE cus.RoleID IN (2,3,4)
	AND cus.CustSubID = 0; ## 19.656 sec 12882 row(s) affected Records: 12882  Duplicates: 0  Warnings: 0

********STEP 1.2 GET BY JOIN ArchiveCustomer_CTSCustomer*********
INSERT INTO CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification(Migrate_Source,Migrate_IsReactivated
, Migrate_ToRoleID, Migrate_ToSubscriberID
, CustID,CTSCustID,SubscriberID,RoleID,IsAffectToDownline,ParentID,CategoryID,Remark,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,LastScannedDate,IsFromTVS,IsFromTW,IsFromCTS,IsMarkedDirectly,TVSRequestID,IsFromAI,IsFromImperva,IsParlay,SportType,IssueTypeID)
SELECT 	2 AS Migrate_Source
	,	arc.IsReactivated AS Migrate_IsReactivated
    ,	arc.RoleID AS Migrate_ToRoleID
    ,	arc.SubscriberID AS Migrate_ToSubscriberID
	,	cls.CustID
	,	cls.CTSCustID
	,	cls.SubscriberID
	,	cls.RoleID
	,	cls.IsAffectToDownline
	,	cls.ParentID
	,	cls.CategoryID
	,	cls.Remark
	,	cls.CreatedDate
	,	cls.CreatedBy
	,	cls.LastModifiedDate
	,	cls.LastModifiedBy
	,	cls.LastScannedDate
	,	cls.IsFromTVS
	,	cls.IsFromTW
	,	cls.IsFromCTS
	,	cls.IsMarkedDirectly
	,	cls.TVSRequestID
	,	cls.IsFromAI
	,	cls.IsFromImperva
	,	cls.IsParlay
	,	cls.SportType
	,	cls.IssueTypeID
FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS arc
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON cls.CustID = arc.CustID
    LEFT JOIN CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification AS ad ON arc.CustID = ad.CustID
WHERE arc.RoleID IN (2,3,4)
	AND arc.CustSubID = 0
    AND ad.CustID IS NULL; #56.234 sec,10 row(s) affected Records: 10  Duplicates: 0  Warnings: 0

********STEP 1.3 SET Flag Migrate_IsMove = 1 FOR CREDIT(PA,VVIP) EXISTING CTSCustomer ONLY Migrate_Source = 1*********
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification
SET 	Migrate_Set = 1
	,	Migrate_IsMove = 1
WHERE Migrate_Source = 1 
	AND Migrate_IsLicensee = 0 
    AND CategoryID <> 40100 
    AND ParentID IN (20000, 1000); #0.500 sec #12870 row(s) affected Rows matched: 12870  Changed: 12870  Warnings: 0

********STEP 1.4 UPDATE VVIP Agent*********
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification
SET Migrate_ToCategoryID = 101010
	, Migrate_ToParentID = 101000
WHERE Migrate_ToRoleID = 2 
	AND ParentID = 1000 
    AND Migrate_IsMove = 1; #0.047 sec #20 row(s) affected Rows matched: 20  Changed: 20  Warnings: 0

********STEP 1.5 UPDATE VVIP Master*********
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification
SET Migrate_ToCategoryID = 101011
	, Migrate_ToParentID = 101000
WHERE Migrate_ToRoleID = 3 
	AND ParentID = 1000 
    AND Migrate_IsMove = 1; #0.031 sec #5 row(s) affected Rows matched: 5  Changed: 5  Warnings: 0

********STEP 1.6 UPDATE VVIP Super*********
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification
SET Migrate_ToCategoryID = 101012
	, Migrate_ToParentID = 101000
WHERE Migrate_ToRoleID = 4 
	AND ParentID = 1000 
    AND Migrate_IsMove = 1; # 0.031 sec #1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0

********STEP 1.7 UPDATE PA*********
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification
SET Migrate_ToCategoryID = CategoryID + 100000
	, Migrate_ToParentID = ParentID + 100000
WHERE ParentID = 20000 
    AND Migrate_IsMove = 1; #0.437 sec #12844 row(s) affected Rows matched: 12844  Changed: 12844  Warnings: 0

*******???????INVALID CTSCustomer Minssing Site CO MOVE??? ==========================================
SELECT DISTINCT Site, SiteID FROM CTS_DataCenter.CTSCustomer WHERE SubscriberID IS  NULL;

SELECT Migrate_ToSubscriberID, Migrate_IsLicensee, RoleID, cls.LastModifiedDate, cls.CategoryID, cls.* 
FROM Adhoc_F185799Mig_CTSCustomerClassification cls 
WHERE Migrate_ToSubscriberID  Is NULL AND Migrate_IsMove = 1;

SELECT site, siteID, cus.* FROM CTS_DataCenter.CTSCustomer cus WHERE CustID IN (27454001,27454055);
SELECT site, siteID, cus.* FROM CTS_DataCenter.CTSCustomer cus WHERE SiteID = 257;

SELECT * FROM CTS_DataCenter.MappingSubscriberSite WHERE SiteID = 257;

END;

BEGIN;#============STEP 2: COOK Adhoc_F185799Mig_CTSCustomerClassification_History ==EST: Duration() RowCount(~)=======================
********STEP 2.1 GET BY JOIN CTSCustomer*********
INSERT INTO CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History
(Migrate_Source, Migrate_ToRoleID, ID,CustID,CTSCustID,ParentID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TargetCC,SourceTypeID,IsDataChanged,ActionType,IsAuto,LastModifiedDate,LastModifiedBy,InsertDate,TaggingType,TargetDangerLevel1,TWGroupBettingRate,TWTicketRejectRate,TWDesktopUsageRate,TWBetCount,RobotCounter,Remark,IsMarkedDirectly,TVSRequestID,IsFromTVS,IsFromTW,IsFromCTS,IsFromAI,IsFromImperva,IsParlay,SportType,IssueTypeID,PerformanceTime,CategoryID,OldCategoryID,DWCategoryID)
SELECT
		1 AS Migrate_Source
	,	cus.RoleID AS Migrate_ToRoleID
	, his.ID
	, his.CustID
	, his.CTSCustID
	, his.ParentID
	, his.TurnoverRM
	, his.WinlossRM
	, his.BetCount
	, his.ActiveDays
	, his.TargetCC
	, his.SourceTypeID
	, his.IsDataChanged
	, his.ActionType
	, his.IsAuto
	, his.LastModifiedDate
	, his.LastModifiedBy
	, his.InsertDate
	, his.TaggingType
	, his.TargetDangerLevel1
	, his.TWGroupBettingRate
	, his.TWTicketRejectRate
	, his.TWDesktopUsageRate
	, his.TWBetCount
	, his.RobotCounter
	, his.Remark
	, his.IsMarkedDirectly
	, his.TVSRequestID
	, his.IsFromTVS
	, his.IsFromTW
	, his.IsFromCTS
	, his.IsFromAI
	, his.IsFromImperva
	, his.IsParlay
	, his.SportType
	, his.IssueTypeID
	, his.PerformanceTime
	, his.CategoryID
	, his.OldCategoryID
	, his.DWCategoryID
	FROM CTS_DataCenter.CTSCustomer AS cus
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS his ON cus.CustID = his.CustID
	WHERE cus.RoleID IN(2,3,4) AND cus.CustSubID = 0
; #6.109 sec #11839 row(s) affected Records: 11839  Duplicates: 0  Warnings: 0

********STEP 2.2 GET BY JOIN ArchiveCustomer_CTSCustomer*********
INSERT INTO CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History
(Migrate_Source, Migrate_ToRoleID, ID,CustID,CTSCustID,ParentID,TurnoverRM,WinlossRM,BetCount,ActiveDays,TargetCC,SourceTypeID,IsDataChanged,ActionType,IsAuto,LastModifiedDate,LastModifiedBy,InsertDate,TaggingType,TargetDangerLevel1,TWGroupBettingRate,TWTicketRejectRate,TWDesktopUsageRate,TWBetCount,RobotCounter,Remark,IsMarkedDirectly,TVSRequestID,IsFromTVS,IsFromTW,IsFromCTS,IsFromAI,IsFromImperva,IsParlay,SportType,IssueTypeID,PerformanceTime,CategoryID,OldCategoryID,DWCategoryID)
SELECT 2 AS Migrate_Source
	, cus.RoleID AS Migrate_ToRoleID
	, his.ID
	, his.CustID
	, his.CTSCustID
	, his.ParentID
	, his.TurnoverRM
	, his.WinlossRM
	, his.BetCount
	, his.ActiveDays
	, his.TargetCC
	, his.SourceTypeID
	, his.IsDataChanged
	, his.ActionType
	, his.IsAuto
	, his.LastModifiedDate
	, his.LastModifiedBy
	, his.InsertDate
	, his.TaggingType
	, his.TargetDangerLevel1
	, his.TWGroupBettingRate
	, his.TWTicketRejectRate
	, his.TWDesktopUsageRate
	, his.TWBetCount
	, his.RobotCounter
	, his.Remark
	, his.IsMarkedDirectly
	, his.TVSRequestID
	, his.IsFromTVS
	, his.IsFromTW
	, his.IsFromCTS
	, his.IsFromAI
	, his.IsFromImperva
	, his.IsParlay
	, his.SportType
	, his.IssueTypeID
	, his.PerformanceTime
	, his.CategoryID
	, his.OldCategoryID
	, his.DWCategoryID
	FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS cus
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS his ON cus.CustID = his.CustID
		LEFT JOIN CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History AS mig ON mig.ID = his.ID
	WHERE cus.RoleID IN(2,3,4) AND cus.CustSubID = 0 AND mig.ID IS NULL; #28.485 sec #56 row(s) affected Records: 56  Duplicates: 0  Warnings: 0

********STEP 2.3 SET Flag Migrate_IsMove=1 EXISTING IN  MOVE Adhoc_F185799Mig_CTSCustomerClassification *********
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History AS his
	INNER JOIN CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification AS cls ON his.CustID = cls.CustID 
SET   his.Migrate_IsMove = 1
    , his.Migrate_Set = 1
WHERE cls.Migrate_IsMove = 1
     AND his.CategoryID IS NOT NULL; #9004 row(s) affected Rows matched: 9002  Changed: 9002  Warnings: 0 #0.485 sec

********STEP 2.4 INVALID *********
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History AS his
	INNER JOIN CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification AS cls ON his.CustID = cls.CustID AND cls.Migrate_IsMove = 1 AND his.CategoryID IS NULL
SET his.Migrate_Set = -1; 

********STEP 2.5 UPDATE PA*********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History  AS his
SET his.Migrate_ToParentID = (CASE WHEN his.ParentID > 0 THEN  his.ParentID + 100000 ELSE his.ParentID END)
	, his.Migrate_ToCategoryID =(CASE WHEN his.CategoryID > 0 THEN  his.CategoryID + 100000 ELSE his.CategoryID END)
    , his.Migrate_ToDWCategoryID = (CASE WHEN his.DWCategoryID > 0 THEN  his.DWCategoryID + 100000 ELSE his.DWCategoryID END)
    , his.Migrate_ToOldCategoryID = (CASE WHEN his.OldCategoryID > 0 THEN  his.OldCategoryID + 100000 ELSE his.OldCategoryID END)
    , his.Migrate_ToTargetCC = (CASE WHEN TargetCC > 0 THEN 30000 ELSE NULL END)
WHERE Migrate_IsMove = 1 AND ParentID = 20000 ; #0.421 sec #8979 row(s) affected Rows matched: 8979  Changed: 8979  Warnings: 0

********STEP 2.6 UPDATE VVIP Agent*********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History  AS his
SET his.Migrate_ToParentID = 101000
	, his.Migrate_ToCategoryID = 101010 
    , his.Migrate_ToDWCategoryID = NULL 
    , his.Migrate_ToOldCategoryID = (CASE WHEN his.OldCategoryID > 0 THEN  his.OldCategoryID + 100000 ELSE his.OldCategoryID END)  
    , his.Migrate_ToTargetCC = (CASE WHEN TargetCC > 0 THEN 999 ELSE -1 END)
WHERE Migrate_IsMove = 1 AND ParentID = 1000
	AND Migrate_ToRoleID = 2; #0.047 sec #19 row(s) affected Rows matched: 19  Changed: 19  Warnings: 0

********STEP 2.7 UPDATE VVIP Master********************* 
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History  AS his
SET his.Migrate_ToParentID = (CASE WHEN his.ParentID > 0 THEN  his.ParentID + 100000 ELSE his.ParentID END)
	, his.Migrate_ToCategoryID = 101011 
    , his.Migrate_ToDWCategoryID = NULL 
    , his.Migrate_ToOldCategoryID = (CASE WHEN his.OldCategoryID > 0 THEN  his.OldCategoryID + 100000 ELSE his.OldCategoryID END)    
    , his.Migrate_ToTargetCC = (CASE WHEN TargetCC > 0 THEN 999 ELSE -1 END)
WHERE Migrate_IsMove = 1 AND ParentID = 1000
	AND Migrate_ToRoleID = 3;   #0.047 sec  #5 row(s) affected Rows matched: 5  Changed: 5  Warnings: 0

********STEP 2.8 UPDATE VVIP Super*********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History  AS his
SET his.Migrate_ToParentID = (CASE WHEN his.ParentID > 0 THEN  his.ParentID + 100000 ELSE his.ParentID END)
	, his.Migrate_ToCategoryID = 101012 
    , his.Migrate_ToDWCategoryID = NULL 
    , his.Migrate_ToOldCategoryID = (CASE WHEN his.OldCategoryID > 0 THEN  his.OldCategoryID + 100000 ELSE his.OldCategoryID END)   
    , his.Migrate_ToTargetCC = (CASE WHEN TargetCC > 0 THEN 999 ELSE -1 END)
WHERE Migrate_IsMove = 1 AND ParentID = 1000
	AND Migrate_ToRoleID = 4; #0.031 sec #1 row(s) affected Rows matched: 1  Changed: 1  Warnings: 0

END;    

BEGIN;#============STEP 3: COOK Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer ========EST: Duration() RowCount(~)=======================
********STEP 3.1 GET Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer FOR SMA*********************
INSERT INTO CTS_DataCenter.Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer(ID,ArchivedDate,CTSCustID,AccountID,SubscriberID,CustID,CustSubID,UserName,UserName2,RoleID,ParentID,InsertTime,IsReactivated,ReactivateDate,ProcessedDate,CategoryID)
SELECT 
	ID,
	ArchivedDate,
	CTSCustID,
	AccountID,
	SubscriberID,
	CustID,
	CustSubID,
	UserName,
	UserName2,
	RoleID,
	ParentID,
	InsertTime,
	IsReactivated,
	ReactivateDate,
	ProcessedDate,
	CategoryID
FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer AS arc
WHERE RoleID IN (2,3,4) AND CategoryID IS NOT NULL
; #33.297 sec #1525 row(s) affected Records: 1525  Duplicates: 0  Warnings: 0

********STEP 3.1 UPDATE PA*********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer  AS arc
	INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON arc.CategoryID = cat.CategoryID 
SET arc.Migrate_ToParentID = cat.ParentID + 100000
	, arc.Migrate_ToCategoryID =cat.CategoryID + 100000
WHERE cat.ParentID <> 1000; #0.078 sec #1422 row(s) affected Rows matched: 1422  Changed: 1422  Warnings: 0

********STEP 3.2 UPDATE VVIP Agent*********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer  AS arc
SET arc.Migrate_ToParentID = 101000
	, arc.Migrate_ToCategoryID =(CASE WHEN arc.CategoryID > 0 THEN 101010 ELSE arc.CategoryID END)
WHERE ParentID = 1000 AND RoleID = 2 ; #0.015 sec # 0 row(s) affected Rows matched: 0  Changed: 0  Warnings: 0

********STEP 3.2 UPDATE VVIP Master*********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer  AS arc
SET arc.Migrate_ToParentID = 101000
	, arc.Migrate_ToCategoryID =(CASE WHEN arc.CategoryID > 0 THEN 101011 ELSE arc.CategoryID END)
WHERE ParentID = 1000 AND RoleID = 3 ;

********STEP 3.2 UPDATE VVIP Super*********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer  AS arc
SET arc.Migrate_ToParentID = 101000
	, arc.Migrate_ToCategoryID =(CASE WHEN arc.CategoryID > 0 THEN 101012 ELSE arc.CategoryID END)
WHERE ParentID = 1000 AND RoleID = 4;

SELECT * FROM CTS_DataCenter.Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer WHERE Migrate_ToParentID IS NULL #===Expected EMPTY
END;

BEGIN;#============STEP 4: COOK Adhoc_F185799Mig_CTSCustomerClassificationQueue======EST: Duration() RowCount(~)=======================
********STEP 4.1 GET Adhoc_F185799Mig_CTSCustomerClassificationQueue FOR SMA*********************
INSERT INTO CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassificationQueue(ID,CTSCustID,CustID,RoleID,SubscriberID,CreatedBy,Remark,CategoryGroupID,CategoryID,LastDownlineCTSCustID,ActionType,InsertTime,IsExceptDirectDownline,IsFromTVS,IsFromTW,IsFromCTS,IsMarkedDirectly,TVSRequestID)
SELECT 
	ID,
	CTSCustID,
	CustID,
	RoleID,
	SubscriberID,
	CreatedBy,
	Remark,
	CategoryGroupID,
	CategoryID,
	LastDownlineCTSCustID,
	ActionType,
	InsertTime,
	IsExceptDirectDownline,
	IsFromTVS,
	IsFromTW,
	IsFromCTS,
	IsMarkedDirectly,
	TVSRequestID
FROM CTS_DataCenter.CTSCustomerClassificationQueue
WHERE RoleID IN (2,3,4);

********STEP 4.2 UPDATE Adhoc_F185799Mig_CTSCustomerClassificationQueue PA *********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassificationQueue  AS que
	INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = que.CategoryID
SET que.Migrate_ToCategoryGroupID = cat.CategoryGroupID + 100000
	, que.Migrate_ToCategoryID =(CASE WHEN que.CategoryID > 0 THEN  que.CategoryID + 100000 ELSE que.CategoryID END)
WHERE cat.ParentID = 20000  ;

********STEP 4.2 UPDATE Adhoc_F185799Mig_CTSCustomerClassificationQueue VVIP Agent *********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassificationQueue  AS que
	INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = que.CategoryID
SET que.Migrate_ToCategoryGroupID = 101010
	, que.Migrate_ToCategoryID =(CASE WHEN que.CategoryID > 0 THEN 101010 ELSE que.CategoryID END)
WHERE cat.ParentID = 1000 AND RoleID = 2 ;

********STEP 4.2 UPDATE Adhoc_F185799Mig_CTSCustomerClassificationQueue VVIP Master *********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassificationQueue  AS que
	INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = que.CategoryID
SET que.Migrate_ToCategoryGroupID = 101011
	, que.Migrate_ToCategoryID =(CASE WHEN que.CategoryID > 0 THEN 101011 ELSE que.CategoryID END)
WHERE cat.ParentID = 1000  AND RoleID = 3 ;

********STEP 4.2 UPDATE Adhoc_F185799Mig_CTSCustomerClassificationQueue VVIP Super *********************
UPDATE CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassificationQueue  AS que
SET que.Migrate_ToCategoryGroupID = 101012
	, que.Migrate_ToCategoryID =(CASE WHEN que.CategoryID > 0 THEN 101012 ELSE que.CategoryID END)
WHERE cat.ParentID = 1000  AND RoleID = 4;
#===========================================================================================================
