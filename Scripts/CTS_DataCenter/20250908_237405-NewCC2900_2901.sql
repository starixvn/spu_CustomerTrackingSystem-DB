/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250908@Logan.Nguyen
Task:	 	New CC 2900/2901
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250908@Logan.Nguyen: Created [Redmine ID: #237405]
Reviewer:
*/



/*******************************New Table Customer_InitialSmart_BySport and Customer_InitialSmart_BySport_Log*********************************/
USE CTS_DataCenter;

#=================================================
CREATE TABLE Customer_InitialSmart_BySport (
        CustID              BIGINT UNSIGNED NOT NULL 
    ,   SportType           INT
    ,   Probability         DECIMAL(8,4)
    ,   SourceCreatedDate   DATETIME(3)
    ,   InsertedTime        DATETIME(3)
    ,   PRIMARY KEY (CustID, SportType)
    ,   KEY IX_Customer_InitialSmart_BySport_InsertedTime_CustID (InsertedTime,CustID,SportType)
);


CREATE TABLE Customer_InitialSmart_BySport_Log (
        ID                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY
    ,   CustID              BIGINT UNSIGNED NOT NULL
    ,   SportType           INT
    ,   Probability         DECIMAL(8,4)
    ,   SourceCreatedDate   DATETIME(3)
    ,   InsertedTime        DATETIME(3) 
    ,   KEY IX_Customer_InitialSmart_Log_BySport_CustID (CustID,SportType)
);


/*******************************ALTER Table CustomerCategorySettings*********************************/
USE CTS_DataCenter;

ALTER TABLE CTS_DataCenter.CustomerCategorySettings 
ADD COLUMN SportType INT DEFAULT '0';

ALTER TABLE CTS_DataCenter.CustomerCategorySettings 
ADD COLUMN FlowPADailyScan INT DEFAULT '0';

/*******************************INIT Table CustomerCategory*********************************/

INSERT INTO CTS_DataCenter.CustomerCategory
(
        CategoryID, CategoryName, CategorySpec, ParentID, CustomerClass
    ,   CustomerClassName, CategoryGroupID, CategoryPriority, CustomerClassPriority, BusinessCategoryGroupID
    ,   IsActive, ScanIntervalInSecond, ScanTaggingIntervalInSecond, RelevantCategoryID, IsHedgingReasonMM
    ,   TVSReasonID, IsPAProbation, IsDangerProbation, AFCFraudID, DataSource
    ,   CreatedDate, CategoryNameCN, CategoryNameCN3, CategoryNameTHB, CategoryNameIND
    ,   CustomerClassNameCN, SabaSportType, TaggingID, TaggingType, RootTaggingID
    ,   OldCategoryID, ColorTypeID, Ext_ABIDangerLevel_Licensee, Ext_ABIDangerLevel_Credit, Ext_DangerLevelType
    ,   Ext_CategoryGroupID, Ext_EvidenceID_Licensee, Ext_EvidenceID_Credit, Ext_SabaIntelligentRiskLevel, Ext_SabaIntelligentRiskLevelTCN
    ,   Ext_SabaIntelligentRiskLevelSCN, Ext_SabaIntelligentRiskLevelCN3, Ext_SabaIntelligentRiskLevelTHB, Ext_SabaIntelligentRiskLevelIND
)
VALUES
    (
            30400, 'Initial Smart (B)', 'Initial Smart (B)', 20000, 2900
        ,   'Dangerous', 30400, 500, 500, 30
        ,   1, NULL, NULL, 35400, NULL
        ,   NULL, 0, 0, NULL, ''
        ,   NOW(), '初始精明玩家 (篮球)', 'Người chơi khởi đầu thông minh (Bóng rổ)', 'ผู้เล่นเฉียบแหลมเริ่มต้น (บาสเกตบอล)', 'Pemain Cerdas Awal (Basket)'
        ,   '危險', NULL, NULL, NULL, NULL
        ,   30400, 2, NULL, NULL, NULL
        ,   30400, NULL, NULL, 'Dangerous', '危險'
        ,   '危险', 'Nguy hiểm', 'อันตราย', 'Berbahaya'
    )
    ,
    (
            35400, 'Initial Smart (B-Losing)', 'Initial Smart (B-Losing)', 20000, 2901
        ,   'Dangerous -', 35400, 500, 500, 30
        ,   1, NULL, NULL, 30400,NULL
        ,   NULL, 1, 1, NULL,''
        ,   NOW(), '初始精明玩家 (篮球-输钱)', 'Người chơi khởi đầu thông minh (Bóng rổ - Thua)', 'ผู้เล่นเฉียบแหลมเริ่มต้น (บาสเกตบอล-เสียเงิน)', 'Pemain Cerdas Awal (Basket–Rugi)'
        ,   '危險-', NULL, NULL, NULL, NULL
        ,   35400, 5, NULL, NULL, NULL
        ,   35400, NULL, NULL, 'Dangerous', '危險'
        ,   '危险', 'Nguy hiểm', 'อันตราย', 'Berbahaya'
    );

  

/*******************************INIT Table CustomerCategorySettings*********************************/

INSERT INTO CTS_DataCenter.CustomerCategorySettings
(
    CategoryID, CategoryGroupID, ParentID, IsParallelParentID, IsMultiCateIDSameParentID, IsKeepOldCateID, RemarkTemplateID, SportType
)
VALUES
    (30400, 30400, 20000, 0, 1, 1, 47, 2),
    (35400, 35400, 20000, 0, 1, 1, 47, 2);

UPDATE CTS_DataCenter.CustomerCategorySettings AS ccs
JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = ccs.CategoryID
SET FlowPADailyScan = 1
WHERE cc.ParentID = 20000;

/*******************************INIT Table system parameters *********************************/

INSERT INTO CTS_DataCenter.SystemParameter
    (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue) 
VALUES
        (196, 'InitialSmart_B_LastScanCustID', 'InitialSmart_B_LastScanCustID', 'INT', '0')
    ,   (197, 'InitialSmart_B_LastScanDate', 'InitialSmart_B_LastScanDate', 'DATETIME(3)', NOW())
    ,   (198, 'InitialSmart_B_LastLogID', 'InitialSmart_B_LastLogID', 'INT', '0');

