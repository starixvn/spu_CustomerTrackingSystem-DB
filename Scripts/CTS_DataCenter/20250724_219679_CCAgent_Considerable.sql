/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250724@Casey.Huynh
Task:	 	
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250724@Casey.Huynh: Created [Redmine ID: #219679]
Reviewer:
*/

USE CTS_DataCenter;

#1. New staging table: Customer_ConsiderableDanger_Queue (ID, CustID, ScanType, InsertedTime)
#DROP TABLE CustomerConsiderableDangerQueue;
CREATE TABLE CustomerConsiderableDangerQueue(
		ID BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
    ,	CustID BIGINT
    ,	ScanType TINYINT
    ,	InsertedTime DATETIME(3)   
);
#================================================================================
DROP TABLE CTSCustomerClassificationAgency_History_Archive;
CREATE TABLE CTSCustomerClassificationAgency_History_Archive(
		ID BIGINT UNSIGNED NOT NULL
	,	CustID BIGINT UNSIGNED
	,	CTSCustID BIGINT UNSIGNED
	,	RoleID TINYINT
	,	ParentID INT UNSIGNED
	,	CategoryID INT
	,	OldCategoryID INT UNSIGNED
	,	DWCategoryID INT UNSIGNED
	,	TargetCC INT
	,	SourceTypeID SMALLINT UNSIGNED
	,	IsDataChanged TINYINT(1)
	,	ActionType TINYINT
	,	IsAuto TINYINT(1)
	,	LastModifiedDate DATETIME 
	,	LastModifiedBy INT UNSIGNED
	,	InsertDate DATETIME
	,	TargetDangerLevel1 SMALLINT
	,	Remark VARCHAR(500) 
	,	IsMarkedDirectly TINYINT(1)
	,	IsFromTW TINYINT(1)
	,	IsFromCTS TINYINT(1)
	,	IsFromAI TINYINT(1)
	,	TurnoverRM DECIMAL(20,4) 
	,	WinlossRM DECIMAL(20,4)
	,	BetCount BIGINT
	,	LastXDaysTurnoverRM DECIMAL(20,4)
	,	LastXDaysWinlossRM DECIMAL(20,4)
	,	LastXDaysBetCount BIGINT
	,	LastYDaysTurnoverRM DECIMAL(20,4) 
	,	LastYDaysWinlossRM DECIMAL(20,4)
	,	LastYDaysBetCount BIGINT 
	,	PerformanceTime DATETIME 
	,	RobotCounter SMALLINT
	,	PRIMARY KEY(ID) 
	,	KEY IX_CTSCustomerClassificationAgency_History_Archive_CustID(CustID) 
) ENGINE=InnoDB;

#2. New table Customer_ConsiderableDanger
#DROP TABLE Customer_ConsiderableDanger;
CREATE TABLE Customer_ConsiderableDanger(
    	CustID 			BIGINT	
	,	CTSCustID		BIGINT UNSIGNED
    ,	TotalMember		INT
    ,	PAMember		INT
    ,	PAMemberRatio	DECIMAL(2,2)
    ,	IsDisable		BOOLEAN
    ,	InsertedTime	DATETIME(4)
    
    ,	PRIMARY KEY PK_Customer_ConsiderableDanger(CustID,InsertedTime)    
);

#New table Customer_ConsiderableDanger_Log
#DROP TABLE Customer_ConsiderableDanger_Log;
CREATE TABLE Customer_ConsiderableDanger_Log(
		ID				BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
    ,	CustID 			BIGINT	
	,	CTSCustID		BIGINT UNSIGNED
    ,	TotalMember		INT
    ,	PAMember		INT
    ,	PAMemberRatio	DECIMAL(2,2)  
    ,	InsertedTime	DATETIME(4)
    
    ,	INDEX	IX_Customer_ConsiderableDanger_Log(CustID)
);

ALTER TABLE CTSCustomerClassificationAgency_History
	ADD COLUMN SystemRemark VARCHAR(255)
;

ALTER TABLE CustomerCategorySettings
	ADD COLUMN FlowConsiderableDangerScan TINYINT DEFAULT 0
;

#==============CTS_DataCenter.CustomerCategoryAgency===========================	
INSERT INTO CTS_DataCenter.CustomerCategoryAgency (CategoryID, CategoryName, CategorySpec, ParentID, RoleID, CustomerClass, CustomerClassName, CategoryGroupID, CategoryPriority, CustomerClassPriority, IsActive, RelevantCategoryID, IsPAProbation, ColorTypeID, Ext_CategoryGroupID) 
VALUES ('130100', 'Considerable Danger Low-value', 'Considerable Danger Low value', '130000', '2', '30001', 'Dangerous', '130100', '600', '600', '1', '135100', '0', '6', '130100')
	,	('135100', 'Considerable Danger Hight-value', 'Considerable Danger High value', '130000', '2', '31001', 'Dangerous -', '135100', '600', '600', '1', '130100', '1', '7', '135100');																															

SELECT * FROM CTS_DataCenter.CustomerCategoryAgency WHERE ParentID = 130000; 
#==============CTS_DataCenter.CustomerCategorySettingsAgency===========================	
          
INSERT INTO CTS_DataCenter.CustomerCategorySettingsAgency(CategoryID,CategoryGroupID,ParentID,IsParallelParentID,IsMultiCateIDSameParentID,IsKeepOldCateID,RemarkTemplateID,FlowPADailyScan)
VALUES(130100,130100,130000,0,0,0,39,0)
	,(135100,135100,130000,0,0,0,39,0);
    
SELECT * FROM CTS_DataCenter.CustomerCategorySettingsAgency WHERE ParentID = 130000;  

#==============CTS_DataCenter.CustomerCategorySettings===========================	
UPDATE CTS_DataCenter.CustomerCategorySettings AS cs
	INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cat.CategoryID = cs.CategoryID
SET cs.FlowConsiderableDangerScan = 1
WHERE cs.ParentID = 20000
	AND cat.CustomerClass NOT IN (3101, 3201, 305,  300, 3000, 3100, 3200, 2600, 2601, 2700, 2701, 2800, 2801);

#==============CTS_DataCenter.CustomerClassificationAgency_Remark===============================================

INSERT INTO `CTS_DataCenter`.`CustomerClassificationAgency_Remark` (`RemarkID`, `RemarkTemplate`, `Description`, `CreatedDate`) 
VALUES ('39', 'PA Ratio: [Remark] | Win loss: [Winloss] | Margin: [Margin]', 'Considerable Danger', '2025-07-18 02:45:52');

SELECT * FROM CTS_DataCenter.CustomerClassificationAgency_Remark where RemarkID = 39;
#========================================CTS_DataCenter.StaticList===============================================================================

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,Description,CreatedDate)
VALUES(@ListID:=6,@ItemID:=121,@ListName:='Classification ParentID',@ListNameDisplay:='PARENTID',@ItemName:='CONST_AGENCY_PARENTID_CONSIDERABLEDANGER',@ItemNameDisplay:='CONST_AGENCY_PARENTID_CONSIDERABLEDANGER',@ItemValue:='130000',@ItemDefaultValue:='130000',@ItemParentItemID:=2,@PriorityOrder:=NULL,@Status:=1,@Description:=NULL,@CreatedDate:=NOW())
;

SELECT * FROM CTS_DataCenter.StaticList WHERE ListID = 6;


INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,Description,CreatedDate)
VALUES(@ListID:=24,@ItemID:=28,@ListName:='Flow Classification Insert',@ListNameDisplay:='INPUTFLOWID',@ItemName:='CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_CONSIDERABLEDANGER',@ItemNameDisplay:='CONST_AGENCY_INPUTFLOWID_GENERAL_INSERT_CONSIDERABLEDANGER',@ItemValue:='1020',@ItemDefaultValue:='1020',@ItemParentItemID:=1,@PriorityOrder:=NULL,@Status:=1,@Description:=NULL,@CreatedDate:=NOW())
,	(@ListID:=24,@ItemID:=29,@ListName:='Flow Classification Rescan',@ListNameDisplay:='INPUTFLOWID',@ItemName:='CONST_AGENCY_INPUTFLOWID_GENERAL_RESCAN_CONSIDERABLEDANGER',@ItemNameDisplay:='CONST_AGENCY_INPUTFLOWID_GENERAL_RESCAN_CONSIDERABLEDANGER',@ItemValue:='1120',@ItemDefaultValue:='1120',@ItemParentItemID:=2,@PriorityOrder:=NULL,@Status:=1,@Description:=NULL,@CreatedDate:=NOW())
,	(@ListID:=24,@ItemID:=30,@ListName:='Flow Classification Remove',@ListNameDisplay:='INPUTFLOWID',@ItemName:='CONST_AGENCY_INPUTFLOWID_GENERAL_REMOVE_CONSIDERABLEDANGER',@ItemNameDisplay:='CONST_AGENCY_INPUTFLOWID_GENERAL_REMOVE_CONSIDERABLEDANGER',@ItemValue:='1220',@ItemDefaultValue:='1220',@ItemParentItemID:=3,@PriorityOrder:=NULL,@Status:=1,@Description:=NULL,@CreatedDate:=NOW())
;
SELECT * FROM CTS_DataCenter.StaticList WHERE ListID = 24;

#=========================CTS_DataCenter.SystemParameter===================================
SELECT * FROM CTS_DataCenter.SystemParameter WHERe ParameterID IN (192,193);
INSERT INTO CTS_DataCenter.SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue) 
VALUES ('192', 'ConsiderableDangeDailyScan Last ID', 'Max Queue ID at Daily RunTime (CustomerConsiderableDangerQueue.ID)', 'BIGINT UNSIGNED', '0')
	, ('193', 'ConsiderableDangeDailyScan Previous ID', 'Last ID (CustomerConsiderableDangerQueue.ID)', 'BIGINT UNSIGNED', '0');

#===============================================================================================================
