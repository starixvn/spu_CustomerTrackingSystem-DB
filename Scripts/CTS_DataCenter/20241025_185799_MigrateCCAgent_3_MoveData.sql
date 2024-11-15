/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241025@Casey.Huynh
Task:	 	Migrate Data MOVE/UPDATE Data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241025@Casey.Huynh: Created [Redmine ID: #185799]
Reviewer:
*/

USE CTS_DataCenter;
BEGIN;#============STEP 1: MOVE  CTSCustomerClassification ==================EST: Duration() RowCount(~)=======================
#DELETE# FROM CTS_DataCenter.CTSCustomerClassificationAgency;
INSERT INTO CTS_DataCenter.CTSCustomerClassificationAgency(CustID,CTSCustID,ParentID,CategoryID,SubscriberID,RoleID,IsAffectToDownline,Remark,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,LastScannedDate,IsMarkedDirectly,IsFromTW,IsFromCTS,IsFromAI)
SELECT CustID,CTSCustID
, Migrate_ToParentID AS ParentID
, Migrate_ToCategoryID AS CategoryID
, Migrate_ToSubscriberID AS SubscriberID
, Migrate_ToRoleID AS RoleID
,IsAffectToDownline,Remark,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,LastScannedDate,IsMarkedDirectly,IsFromTW,IsFromCTS,IsFromAI
FROM CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification 
WHERE Migrate_IsMove = 1; # 0.266 sec # 12869 row(s) affected Records: 12869  Duplicates: 0  Warnings: 0

DELETE del
FROM CTS_DataCenter.CTSCustomerClassification AS del
	INNER JOIN CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification AS mig ON del.CustID = mig.CustID;
END;

BEGIN;#============STEP 2: MOVE  CTSCustomerClassification_History ==========EST: Duration() RowCount(~)=======================
INSERT INTO CTS_DataCenter.CTSCustomerClassificationAgency_History(ID,CustID,CTSCustID
	,RoleID,ParentID,CategoryID,OldCategoryID,DWCategoryID,TargetCC,SourceTypeID,IsDataChanged,ActionType,IsAuto,LastModifiedDate,LastModifiedBy,InsertDate,TargetDangerLevel1,Remark,IsMarkedDirectly,IsFromTW,IsFromCTS,IsFromAI,TurnoverRM,WinlossRM,BetCount,PerformanceTime,RobotCounter)
SELECT  ROW_NUMBER()  OVER (ORDER BY ID ASC) AS  ID,CustID,CTSCustID
	,	Migrate_ToRoleID AS RoleID
    ,	Migrate_ToParentID AS ParentID
    ,	Migrate_ToCategoryID AS CategoryID
    ,	Migrate_ToOldCategoryID AS OldCategoryID
    ,	Migrate_ToDWCategoryID AS DWCategoryID 
    ,	Migrate_ToTargetCC AS TargetCC
    ,	SourceTypeID
	,	IsDataChanged,ActionType,IsAuto,LastModifiedDate,LastModifiedBy,InsertDate,TargetDangerLevel1,Remark,IsMarkedDirectly,IsFromTW,IsFromCTS,IsFromAI
	,	CASE WHEN Migrate_ToParentID = 120000 THEN IFNULL(TurnoverRM,0.0) ELSE TurnoverRM END
	, 	CASE WHEN Migrate_ToParentID = 120000 THEN IFNULL(WinlossRM,0.0) ELSE WinlossRM END
	, 	CASE WHEN Migrate_ToParentID = 120000 THEN IFNULL(BetCount,0) ELSE BetCount END
    ,	PerformanceTime,RobotCounter
FROM CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History
WHERE Migrate_IsMove = 1; #0.203 sec #9002 row(s) affected Records: 9002  Duplicates: 0  Warnings: 0

DELETE del
FROM CTS_DataCenter.CTSCustomerClassification_History AS del
	INNER JOIN CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification_History AS mig ON del.ID = mig.ID;
END;

BEGIN;#============STEP 3: UPDATE  ArchiveCustomer_CTSCustomer ==========EST: Duration() RowCount(~)=======================
UPDATE CTS_DataCenter.ArchiveCustomer_CTSCustomer AS arc
	INNER JOIN CTS_DataCenter.Adhoc_F185799Mig_ArchiveCustomer_CTSCustomer AS src ON src.ID = arc.ID
SET 	arc.CategoryID = src.Migrate_ToCategoryID
	,	arc.ParentID = src.Migrate_ToParentID;
END;

BEGIN;#============STEP 3: UPDATE CTSCustomerClassificationQueue ==========EST: Duration() RowCount(~)=======================
UPDATE CTS_DataCenter.CTSCustomerClassificationQueue AS que
	INNER JOIN CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassificationQueue AS src ON src.ID = que.ID
SET que.CategoryID = src.Migrate_ToCategoryID
	, que.CategoryGroupID = src.Migrate_ToCategoryGroupID;
END;

