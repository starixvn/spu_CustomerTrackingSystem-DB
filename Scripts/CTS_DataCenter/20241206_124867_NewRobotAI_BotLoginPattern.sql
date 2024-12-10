/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20241210@Casey.Huynh
Task:	 	New Robot AI - Bot Login Pattern
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
	-	[20241210@Casey.Huynh]: Initial Data Settings [Remind ID: #214655]:
Reviewer:
*/
#DELETE del FROM CTS_DataCenter.CustomerCategory AS del WHERE CategoryID IN (21800,26800);
#DELETE del FROM CTS_DataCenter.CustomerCategorySettings AS del WHERE CategoryID IN (21800,26800);

INSERT INTO CTS_DataCenter.CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,CustomerClass,CustomerClassName,CategoryGroupID,CategoryPriority,CustomerClassPriority,BusinessCategoryGroupID,IsActive,ScanIntervalInSecond,ScanTaggingIntervalInSecond,RelevantCategoryID,IsHedgingReasonMM,TVSReasonID,IsPAProbation,IsDangerProbation,AFCFraudID,DataSource,CreatedDate,CategoryNameCN,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CustomerClassNameCN,SabaSportType,TaggingID,TaggingType,RootTaggingID,OldCategoryID,ColorTypeID,Ext_ABIDangerLevel_Licensee,Ext_ABIDangerLevel_Credit,Ext_DangerLevelType,Ext_CategoryGroupID,Ext_EvidenceID_Licensee,Ext_EvidenceID_Credit,Ext_SabaIntelligentRiskLevel,Ext_SabaIntelligentRiskLevelTCN,Ext_SabaIntelligentRiskLevelSCN,Ext_SabaIntelligentRiskLevelCN3,Ext_SabaIntelligentRiskLevelTHB,Ext_SabaIntelligentRiskLevelIND)
VALUES(21800,'Bot Login Pattern','Bot Login Pattern',20000,300,'Robot',21800,570,570,10,1,Null,Null,26800,Null,Null,0,0,Null,'AI',NOW(),'机械玩家','Hành Vi Đăng Nhập Robot','รูปแบบการเข้าสู่ระบบของบอท','Pola Masuk Bot','機械','2',Null,Null,13,Null,6,Null,Null,2,21800,Null,Null,'Robot','機械','机械','Robot','บอท','Robot')
,(26800,'Bot Login Pattern (Losing)','Bot Login Pattern (Losing)',20000,3000,'Robot',26800,570,570,10,1,Null,Null,21800,Null,Null,1,1,Null,'AI',NOW(),'机械玩家 (输钱)','Hành Vi Đăng Nhập Robot (Thua)','รูปแบบการเข้าสู่ระบบด้วยบอท (ขาดทุน)','Pola Masuk Bot (Kalah)','機械','2',Null,Null,13,Null,7,Null,Null,2,26800,Null,Null,'Robot','機械','机械','Robot','บอท','Robot')
;

INSERT INTO CTS_DataCenter.CustomerCategorySettings(CategoryID ,CategoryGroupID ,ParentID ,IsParallelParentID ,IsMultiCateIDSameParentID ,IsKeepOldCateID ,RemarkTemplateID,ExcludedFromClassifyMM )
VALUES(21800,21800,20000,0,1,1,NULL,0)
	,(26800,21800,20000,0,1,1,NULL,0)
;
