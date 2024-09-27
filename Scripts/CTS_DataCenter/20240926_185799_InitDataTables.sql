/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240926@Thomas.Nguyen
Task:	 	script init data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240926@Thomas.Nguyen: Created [Redmine ID: #185799]
Reviewer:
*/

USE CTS_DataCenter;

INSERT INTO CustomerCategorySMA(CategoryID,CategoryName,CategorySpec,ParentID,CustomerClass,CustomerClassName,CategoryGroupID,CategoryPriority,CustomerClassPriority,BusinessCategoryGroupID,IsActive,ScanIntervalInSecond,RelevantCategoryID,IsPAProbation,AFCFraudID,DataSource,CreatedDate,CategoryNameCN,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CustomerClassNameCN,SabaSportType,OldCategoryID,ColorTypeID,Ext_ABIDangerLevel_Licensee,Ext_ABIDangerLevel_Credit,Ext_DangerLevelType,Ext_CategoryGroupID,Ext_EvidenceID_Licensee,Ext_EvidenceID_Credit,Ext_SabaIntelligentRiskLevel,Ext_SabaIntelligentRiskLevelTCN,Ext_SabaIntelligentRiskLevelSCN,Ext_SabaIntelligentRiskLevelCN3,Ext_SabaIntelligentRiskLevelTHB,Ext_SabaIntelligentRiskLevelIND)
VALUES(101,'VVIP Agent','VVIP Agent',100,999,'Healthy',101,10,10,20,1,Null,Null,0,Null,'',NOW(),'超级贵宾',Null,Null,Null,'健康','',101,1,Null,Null,1,Null,Null,Null,'VIP','VIP玩家','VIP玩家','VIP','VIP','VIP'),
(1010,'Group Betting','Group Betting',1000,30000,'Problem',1010,200,200,10,1,Null,1510,0,1,'NAP',NOW(),'群组投注',Null,Null,Null,'问题','1,2',1010,6,11,1,2,Null,43,41,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1020,'Hedging','Hedging',1000,30000,'Problem',1020,200,200,10,1,Null,1520,0,2,'NAP',NOW(),'出货群组',Null,Null,Null,'问题','2',1020,6,14,4,2,Null,46,56,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1030,'Arbitrage','Arbitrage',1000,30000,'Problem',1030,200,200,10,1,Null,1530,0,3,'NAP',NOW(),'打水套利',Null,Null,Null,'问题','1,2',1030,6,13,3,2,Null,45,55,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1040,'Fixed Game','Fixed Game',1000,30000,'Problem',1040,200,200,10,1,Null,1540,0,4,'NAP',NOW(),'内定赛事',Null,Null,Null,'问题','2',1040,6,12,2,2,Null,44,52,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1050,'Irrigation Bet','Irrigation Bet',1000,30000,'Problem',1050,200,200,10,1,Null,1550,0,5,'NAP',NOW(),'灌水投注',Null,Null,Null,'问题','1,2',1050,6,15,5,2,Null,47,57,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1060,'Formula Bet','Formula Bet',1000,30000,'Problem',1060,200,200,10,1,Null,1560,0,6,'NAP',NOW(),'系统计算投注',Null,Null,Null,'问题','2',1060,6,16,6,2,Null,48,58,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1070,'Info Bet','Info Bet',1000,30000,'Problem',1070,200,200,10,1,Null,1570,0,7,'NAP',NOW(),'资讯单',Null,Null,Null,'问题','',1070,6,19,9,2,Null,51,61,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1080,'Robot','Robot',1000,30000,'Problem',1080,200,200,10,1,Null,1580,0,Null,'',NOW(),'机械',Null,Null,Null,'问题','2',1080,6,Null,Null,2,Null,Null,Null,'Robot','機械','机械','Robot','บอท','Robot'),
(1510,'Group Betting (Losing)','Group Betting (Losing)',1000,30001,'Problem -',1510,200,200,10,1,Null,1010,1,1,'NAP',NOW(),'群组投注（输钱）',Null,Null,Null,'问题 -','1,2',1510,7,11,1,2,Null,43,41,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1520,'Hedging (Losing)','Hedging (Losing)',1000,30001,'Problem -',1520,200,200,10,1,Null,1020,1,2,'NAP',NOW(),'出货群组（输钱）',Null,Null,Null,'问题 -','2',1520,7,14,4,2,Null,46,56,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1530,'Arbitrage (Losing)','Arbitrage (Losing)',1000,30001,'Problem -',1530,200,200,10,1,Null,1030,1,3,'NAP',NOW(),'打水套利（输钱）',Null,Null,Null,'问题 -','1,2',1530,7,13,3,2,Null,45,55,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1540,'Fixed Game (Losing)','Fixed Game (Losing)',1000,30001,'Problem -',1540,200,200,10,1,Null,1040,1,4,'NAP',NOW(),'内定赛事（输钱）',Null,Null,Null,'问题 -','2',1540,7,12,2,2,Null,44,52,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1550,'Irrigation Bet (Losing)','Irrigation Bet (Losing)',1000,30001,'Problem -',1550,200,200,10,1,Null,1050,1,5,'NAP',NOW(),'灌水投注（输钱',Null,Null,Null,'问题 -','1,2',1550,7,15,5,2,Null,47,57,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1560,'Formula Bet (Losing)','Formula Bet (Losing)',1000,30001,'Problem -',1560,200,200,10,1,Null,1060,1,6,'NAP',NOW(),'系统计算投注（输钱）',Null,Null,Null,'问题 -','2',1560,7,16,6,2,Null,48,58,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1570,'Info Bet (Losing)','Info Bet (Losing)',1000,30001,'Problem -',1570,200,200,10,1,Null,1070,1,7,'NAP',NOW(),'资讯单（输钱）',Null,Null,Null,'问题 -','',1570,7,19,9,2,Null,51,61,'Problems','問題','问题','Vấn đề','ปัญหา','Masalah'),
(1580,'Robot (Losing)','Robot (Losing)',1000,30001,'Problem -',1580,200,200,10,1,Null,1080,1,Null,'',NOW(),'机械（输钱）',Null,Null,Null,'问题 -','2',1580,7,Null,Null,2,Null,Null,Null,'Robot','機械','机械','Robot','บอท','Robot'),
(2010,'New Agent','New Agent',2000,20000,'New',2010,800,800,20,1,Null,Null,0,Null,'',NOW(),'新代理',Null,Null,Null,'新代理','',2010,1,Null,Null,1,Null,Null,Null,'New','新玩家','新玩家','Mới','นักเดิมพันใหม่','Baru'),
(2020,'Good Agent','Good Agent',2000,20001,'High-value',2020,800,800,20,1,604800,Null,0,Null,'',NOW(),'优质代理',Null,Null,Null,'高价值','',2020,1,Null,Null,1,Null,Null,Null,'Healthy','健康','健康','Tốt','ดี','Baik'),
(2030,'Normal Agent','Normal Agent',2000,20002,'Suspicious',2030,800,800,20,1,604800,Null,0,Null,'',NOW(),'普通代理',Null,Null,Null,'可疑','',2030,1,Null,Null,1,Null,Null,Null,'Healthy','健康','健康','Tốt','ดี','Baik'),
(2040,'Early Stage Probation Agent','Early Stage Probation Agent',2000,20003,'Moderate',2040,800,800,20,1,604800,Null,0,Null,'',NOW(),'前期阶段观察中代理',Null,Null,Null,'中等','',2040,2,Null,Null,1,Null,Null,Null,'Suspicious','可疑','可疑','Đáng ngờ','น่าสงสัย','Mencurigakan'),
(2050,'Smart Agent','Smart Agent',2000,20004,'Suspicious',2050,800,800,20,1,604800,Null,0,Null,'',NOW(),'精明代理',Null,Null,Null,'可疑','',2050,2,Null,Null,1,Null,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya'),
(2060,'Risky Agent','Risky Agent',2000,20005,'Low-value',2060,800,800,20,1,604800,Null,0,Null,'',NOW(),'高危代理',Null,Null,Null,'低价值','',2060,2,Null,Null,1,Null,Null,Null,'Dangerous','危險','危险','Nguy hiểm','อันตราย','Berbahaya'),
(2070,'Inactive Agent','Inactive Agent',2000,90000,'Dormant',2070,800,800,30,1,86400,Null,0,Null,'',NOW(),'不活跃代理',Null,Null,Null,'不活跃','',2070,8,Null,Null,1,Null,Null,Null,'','','','','','');

INSERT INTO CustomerCategorySettingsSMA(CategoryID,CategoryGroupID,ParentID,IsParallelParentID,IsMultiCateIDSameParentID,IsKeepOldCateID,RemarkTemplateID)
VALUES(101,101,100,0,0,0,Null),
(1010,1010,1000,0,1,1,Null),
(1020,1020,1000,0,1,1,Null),
(1030,1030,1000,0,1,1,Null),
(1040,1040,1000,0,1,1,Null),
(1050,1050,1000,0,1,1,Null),
(1060,1060,1000,0,1,1,Null),
(1070,1070,1000,0,1,1,Null),
(1080,1080,1000,0,1,1,Null),
(1510,1510,1000,0,1,1,Null),
(1520,1520,1000,0,1,1,Null),
(1530,1530,1000,0,1,1,Null),
(1540,1540,1000,0,1,1,Null),
(1550,1550,1000,0,1,1,Null),
(1560,1560,1000,0,1,1,Null),
(1570,1570,1000,0,1,1,Null),
(1580,1580,1000,0,1,1,Null),
(2010,2010,2000,0,0,0,11),
(2020,2020,2000,0,0,0,12),
(2030,2030,2000,0,0,0,13),
(2040,2040,2000,0,0,0,14),
(2050,2050,2000,0,0,0,13),
(2060,2060,2000,0,0,0,12),
(2070,2070,2000,0,0,0,15);


INSERT INTO CustomerClassificationSMA_Remark (RemarkID,RemarkTemplate,Description)
VALUES 
(1,'VVIP is marked manually | [Remark]','From VVIP'),
(2,'VVIP is unmarked manually','From VVIP'),
(3,'VVIP tag is affected by Super | [Remark]','Mark VVIP For Downline'),
(4,'VVIP tag is affected by Master | [Remark]','Mark VVIP For Downline'),
(5,'VVIP untag is affected by Super','Remove VVIP For Downline'),
(6,'VVIP untag is affected by Master','Remove VVIP For Downline'),
(7,'Problem Account is marked directly | Win loss: [Winloss] | [Remark]','Problem Account is marked directly'),
(8,'Problem Account is affected by Uplines | Win loss: [Winloss] | [Remark]','Problem Account is affected by Uplines'),
(9,'Problem Account is unmarked directly | [Remark]','Problem Account is unmarked directly'),
(10,'Unmarking Problem Account is affected by Uplines | [Remark]','Unmarking Problem Account is affected by Uplines'),
(11,'Bet Count = [BetCount]','New Agent'),
(12,'Bet Count = [BetCount] | 1-year Margin = [1yearMargin] | 2-months Margin = [2monthsMargin]','Good/Risky Agent'),
(13,'Bet Count = [BetCount] | 1-year Margin = [1yearMargin] | 2-months Margin = [2monthsMargin] | 1-year Win loss = [1yearWinloss] | 2-months Win loss = [2monthsWinloss]','Normal/Smart Agent'),
(14,'Bet Count = [BetCount] | Margin = [Margin]','Early Stage Probation Agent'),
(15,'No activity in the last 30 days','Inactive Agent');
