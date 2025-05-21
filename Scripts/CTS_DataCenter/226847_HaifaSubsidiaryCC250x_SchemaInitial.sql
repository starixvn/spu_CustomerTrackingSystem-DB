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

DROP TABLE IF EXISTS Customer_SpecialLicSubCC;
CREATE TABLE Customer_SpecialLicSubCC(
		ID						BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY	
	,	CustID					BIGINT UNSIGNED NULL
    ,	APICustomerClass 		INT UNSIGNED NOT NULL
    ,	LatestCustomerClass 	INT UNSIGNED NULL
    ,	ProcessStatus			TINYINT NOT NULL DEFAULT 0	COMMENT '0:API INPUT, 1:Inprocess, 2:ClassifiedComplete, 3:ResponseFail, 4:ResponseSuccess'   
    ,	IsDisabled				TINYINT(1) NOT NULL DEFAULT 0 COMMENT '0:Enabled, 1:Disabled'
    ,	StatusCode				INT NULL
    ,	ResponseTime			DATETIME(4) NULL
    ,	ResponseHttpCode		SMALLINT NULL
    ,	InsertedTime			DATETIME(4) NOT NULL
    
    ,	INDEX IX_Customer_Customer_SpecialLicSubCC_CustID(CustID)
    ,	INDEX IX_Customer_Customer_SpecialLicSubCC_ProcessStatusCustID(ProcessStatus, CustID)
);

DELETE FROM CustomerCategory 
WHERE  CategoryID IN (40106,40406,40506,40606);

DELETE FROM CustomerCategorySettings 
WHERE  CategoryID IN (40106,40406,40506,40606);

INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,CustomerClass,CustomerClassName,CategoryGroupID,CategoryPriority,CustomerClassPriority,BusinessCategoryGroupID,IsActive,ScanIntervalInSecond,ScanTaggingIntervalInSecond,RelevantCategoryID,IsHedgingReasonMM,TVSReasonID,IsPAProbation,IsDangerProbation,AFCFraudID,DataSource,CreatedDate,CategoryNameCN,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CustomerClassNameCN,SabaSportType,TaggingID,TaggingType,RootTaggingID,OldCategoryID,ColorTypeID,Ext_ABIDangerLevel_Licensee,Ext_ABIDangerLevel_Credit,Ext_DangerLevelType,Ext_CategoryGroupID,Ext_EvidenceID_Licensee,Ext_EvidenceID_Credit,Ext_SabaIntelligentRiskLevel,Ext_SabaIntelligentRiskLevelTCN,Ext_SabaIntelligentRiskLevelSCN,Ext_SabaIntelligentRiskLevelCN3,Ext_SabaIntelligentRiskLevelTHB,Ext_SabaIntelligentRiskLevelIND)
VALUES(40106,'New (Lic Sub)','New Member (43)',40000,2500,'New',40100,850,850,30,1,NULL,86400,NULL,NULL,NULL,0,1,NULL,NULL,NOW(),'新注册玩家','Mới (tuyến phụ)','ใหม่ (สายรอง)','Baru (jalur sekunder)','新會員',NULL,1,3,NULL,234,1,NULL,NULL,1,201,NULL,NULL,'New','新玩家','新玩家','Mới','นักเดิมพันใหม่','Baru')
,(40406,'Prob (Lic Sub)','Probation (45)',40000,2503,'Suspicious',40400,850,850,30,1,1209600,86400,NULL,NULL,NULL,0,0,NULL,NULL,NOW(),'观察中玩家','Theo dõi (tuyến phụ)','ติดตาม (สายรอง)','Pantau (jalur sekunder)','可疑',NULL,1,3,NULL,254,2,NULL,NULL,1,206,NULL,NULL,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan')
,(40506,'Smart (Lic Sub)','Smart Punter (46)',40000,2504,'Dangerous',40500,850,850,30,1,1209600,86400,NULL,NULL,NULL,0,0,NULL,NULL,NOW(),'精明玩家','Thông minh (tuyến phụ)','สมาร์ท (สายรอง)','Kecerdasan (jalur sekunder)','危險',NULL,1,3,NULL,264,2,NULL,NULL,1,203,NULL,NULL,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya')
,(40606,'Risky (Lic Sub)','High Risk Punter (47)',40000,2505,'Dangerous',40600,845,850,30,1,1209600,86400,NULL,NULL,NULL,0,0,NULL,NULL,NOW(),'高风险玩家','Rủi ro (tuyến phụ)','ความเสี่ยง (สายรอง)','Risiko (jalur sekunder)','危險',NULL,1,3,NULL,274,2,NULL,NULL,1,204,NULL,NULL,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya')
;

INSERT INTO CTS_DataCenter.CustomerCategorySettings(CategoryID,CategoryGroupID,ParentID,IsParallelParentID,IsMultiCateIDSameParentID,IsKeepOldCateID,RemarkTemplateID,ExcludedFromClassifyMM,FlowNormalDgrAssociation,IsFirstTWTagging)
VALUES(40106,40100,40000,0,0,0,59,0,0,0)
,(40406,40400,40000,0,0,0,59,0,0,0)
,(40506,40500,40000,0,0,0,59,0,0,0)
,(40606,40600,40000,0,0,0,59,0,0,0)
;

INSERT INTO StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,Description,CreatedDate)
VALUES(25,1,'LicSubCustomerClass','','LicSubCustomerClass_New','',200,NULL,NULL,NULL,1,NULL,NOW())
,(25,2,'LicSubCustomerClass','','LicSubCustomerClass_Probation','',203,NULL,NULL,NULL,1,NULL,NOW())
,(25,3,'LicSubCustomerClass','','LicSubCustomerClass_Smart','',204,NULL,NULL,NULL,1,NULL,NOW())
,(25,4,'LicSubCustomerClass','','LicSubCustomerClass_Risky','',205,NULL,NULL,NULL,1,NULL,NOW());

INSERT INTO StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,Description,CreatedDate)
VALUES(26,1,'LicSubStatusCode','','LicSubStatusCode_Successfully','Updated player CC successfully',200,NULL,NULL,NULL,1,NULL,NOW())
,(26,2,'LicSubStatusCode','','LicSubStatusCode_Successfully','Updated player CC successfully. However, the previous CC did not match',201,NULL,NULL,NULL,1,NULL,NOW())
,(26,3,'LicSubStatusCode','','LicSubStatusCode_Inprogress','LicSubStatusCode_Inprogress',300,NULL,NULL,NULL,1,NULL,NOW())
,(26,4,'LicSubStatusCode','','LicSubStatusCode_Fail','CC update failed, player CC does not match',400,NULL,NULL,NULL,1,NULL,NOW())
,(26,5,'LicSubStatusCode','','LicSubStatusCode_Fail','CC update failed, player CC does not fit the rules',401,NULL,NULL,NULL,1,NULL,NOW());

/*========================================THOMAS=============================================*/
INSERT INTO CustomerClassification_Remark (RemarkID,RemarkTemplate,Description)
VALUES
(59,'Turnover: [TurnOver] | Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount]',NULL);