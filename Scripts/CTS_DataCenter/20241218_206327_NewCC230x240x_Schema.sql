/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241218@Thomas.Nguyen
Task:	 	script init data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241218@Thomas.Nguyen: Created [Redmine ID: #206327]
Reviewer:
*/

USE CTS_DataCenter;

DELETE FROM CustomerCategory WHERE CategoryID = 40104;
DELETE FROM CustomerCategorySettings WHERE CategoryID = 40104;

INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,CustomerClass,CustomerClassName,CategoryGroupID,CategoryPriority,CustomerClassPriority,BusinessCategoryGroupID,IsActive,ScanIntervalInSecond,ScanTaggingIntervalInSecond,RelevantCategoryID,IsHedgingReasonMM,TVSReasonID,IsPAProbation,IsDangerProbation,AFCFraudID,DataSource,CreatedDate,CategoryNameCN,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CustomerClassNameCN,SabaSportType,TaggingID,TaggingType,RootTaggingID,OldCategoryID,ColorTypeID,Ext_ABIDangerLevel_Licensee,Ext_ABIDangerLevel_Credit,Ext_DangerLevelType,Ext_CategoryGroupID,Ext_EvidenceID_Licensee,Ext_EvidenceID_Credit,Ext_SabaIntelligentRiskLevel,Ext_SabaIntelligentRiskLevelTCN,Ext_SabaIntelligentRiskLevelSCN,Ext_SabaIntelligentRiskLevelCN3,Ext_SabaIntelligentRiskLevelTHB,Ext_SabaIntelligentRiskLevelIND)
VALUES
(40104,'New Group Betting','New Member',40000,2300,'Suspicious',40100,600,600,30,1,Null,86400,Null,Null,Null,0,1,Null,Null,'2024/12/17 13:46:36','新群组投注玩家','Nhóm Cược Mới','กลุ่มเดิมพันใหม่','Grup Taruhan Baru','可疑',Null,7,2,Null,Null,1,Null,Null,1,201,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan'),
(40204,'Good Group Betting','Good Member',40000,2301,'Suspicious',40200,600,600,30,1,604800,86400,Null,Null,Null,0,1,Null,Null,'2024/12/17 13:46:36','优质群组投注玩家','Nhóm Cược Tốt','นักเดิมพันการเดิมพันกลุ่มที่ดี','Pemain Taruhan Grup Berkualitas','可疑',Null,7,2,Null,Null,1,Null,Null,1,205,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan'),
(40304,'Normal Group Betting','Normal Account',40000,2302,'Suspicious',40300,600,600,30,1,1209600,86400,Null,Null,Null,0,1,Null,Null,'2024/12/17 13:46:36','普通群组投注玩家','Nhóm Cược Thường','นักเดิมพันกลุ่มปกติ','Pemain Taruhan Grup Biasa','可疑',Null,7,2,Null,Null,1,Null,Null,1,202,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan'),
(40105,'New High Rejected','New Member',40000,2400,'Suspicious',40100,750,750,30,1,Null,86400,Null,Null,Null,0,1,Null,Null,'2024/12/17 13:46:36','新资讯投注玩家','Nhóm Mới Cao Bị Từ Chối','นักเดิมพันข้อมูลใหม่','Pemain Taruhan Informasi Baru','可疑',Null,8,2,Null,Null,1,Null,Null,1,201,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan'),
(40205,'Good High Rejected','Good Member',40000,2401,'Suspicious',40200,750,750,30,1,604800,86400,Null,Null,Null,0,1,Null,Null,'2024/12/17 13:46:36','优质资讯投注玩家','Nhóm Tốt Cao Bị Từ Chối','นักเดิมพันข้อมูลคุณภาพสูงที่ถูกปฏิเสธ','Pemain Taruhan dengan Informasi Berkualitas','可疑',Null,8,2,Null,Null,1,Null,Null,1,205,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan'),
(40305,'Normal High Rejected','Normal Account',40000,2402,'Suspicious',40300,750,750,30,1,1209600,86400,Null,Null,Null,0,1,Null,Null,'2024/12/17 13:46:36','普通资讯投注玩家','Nhóm Thường Cao Bị Từ Chối','นักเดิมพันข้อมูลทั่วไปที่ถูกปฏิเสธ','Pemain Taruhan Informasi Normal','可疑',Null,8,2,Null,Null,1,Null,Null,1,202,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan');

INSERT INTO CustomerCategorySettings(CategoryID,CategoryGroupID,ParentID,IsParallelParentID,IsMultiCateIDSameParentID,IsKeepOldCateID,RemarkTemplateID,ExcludedFromClassifyMM,FlowNormalDgrAssociation)
VALUES
(40104,40100,40000,0,0,0,44,0,0),
(40204,40200,40000,0,0,0,57,0,0),
(40304,40300,40000,0,0,0,44,0,0),
(40105,40100,40000,0,0,0,45,0,0),
(40205,40200,40000,0,0,0,58,0,0),
(40305,40300,40000,0,0,0,45,0,0);

INSERT INTO CustomerClassification_Remark (RemarkID,RemarkTemplate,Description)
VALUES
(57,'Turnover: [TurnOver] | Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount] | Active Day: [ActiveDays] | Group Betting Percent: [TWGBRate]',Null),
(58,'Turnover: [TurnOver] | Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount] | Active Day: [ActiveDays] | Desktop Percent: [TWDesktopUsageRate] | Reject Percent: [TWTicketRejectRate]',Null);