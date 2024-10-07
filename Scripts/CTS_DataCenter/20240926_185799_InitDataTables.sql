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

INSERT INTO CustomerCategoryAgency(CategoryID,CategoryName,CategorySpec,ParentID,RoleID,CustomerClass,CustomerClassName,CategoryGroupID,CategoryPriority,CustomerClassPriority,BusinessCategoryGroupID,IsActive,ScanIntervalInSecond,RelevantCategoryID,IsPAProbation,AFCFraudID,DataSource,CreatedDate,CategoryNameCN,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CustomerClassNameCN,SabaSportType,OldCategoryID,ColorTypeID,Ext_ABIDangerLevel_Credit,Ext_DangerLevelType,Ext_CategoryGroupID,Ext_EvidenceID_Credit)
VALUES (101010,'VVIP Agent','VVIP Agent',101000,2,999,'Healthy',101010,10,10,30,1,Null,Null,0,Null,'',NOW(),'超级贵宾',Null,Null,Null,'健康','',210,1,Null,1,101010,Null),
(101011,'VVIP (internal)','VVIP',101000,3,999,'Healthy',101010,10,10,30,1,Null,Null,0,Null,'',NOW(),'超级贵宾',Null,Null,Null,'健康','',210,1,Null,1,101010,Null),
(101012,'VVIP (internal)','VVIP',101000,4,999,'Healthy',101010,10,10,30,1,Null,Null,0,Null,'',NOW(),'超级贵宾',Null,Null,Null,'健康','',210,1,Null,1,101010,Null),
(120100,'Group Betting','Group Betting',120000,Null,30000,'Problem',120100,400,400,10,1,Null,125100,0,1,'NAP',NOW(),'群组投注',Null,Null,Null,'问题','1,2',52,6,1,2,120100,41),
(120200,'Hedging','Hedging',120000,Null,30000,'Problem',120200,400,400,10,1,Null,125200,0,2,'NAP',NOW(),'出货群组',Null,Null,Null,'问题','2',53,6,4,2,120200,56),
(120300,'Arbitrage','Arbitrage',120000,Null,30000,'Problem',120300,400,400,10,1,Null,125300,0,3,'NAP',NOW(),'打水套利',Null,Null,Null,'问题','1,2',54,6,3,2,120300,55),
(120400,'Fixed Game','Fixed Game',120000,Null,30000,'Problem',120400,400,400,10,1,Null,125400,0,4,'NAP',NOW(),'内定赛事',Null,Null,Null,'问题','2',55,6,2,2,120400,52),
(120500,'Irrigation Bet','Irrigation Bet',120000,Null,30000,'Problem',120500,400,400,10,1,Null,125500,0,5,'NAP',NOW(),'灌水投注',Null,Null,Null,'问题','1,2',58,6,5,2,120500,57),
(120600,'Formula Bet','Formula Bet',120000,Null,30000,'Problem',120600,400,400,10,1,Null,125600,0,6,'NAP',NOW(),'系统计算投注',Null,Null,Null,'问题','2',59,6,6,2,120600,58),
(120800,'Info Bet','Info Bet',120000,Null,30000,'Problem',120800,400,400,10,1,Null,125800,0,7,'NAP',NOW(),'资讯单',Null,Null,Null,'问题','',162,6,9,2,120800,61),
(121100,'Robot','Robot',120000,Null,30000,'Problem',121100,400,400,10,1,Null,126100,0,Null,'',NOW(),'机械',Null,Null,Null,'问题','2',163,6,Null,2,121100,Null),
(125100,'Group Betting (Losing)','Group Betting (Losing)',120000,Null,30001,'Problem -',125100,400,400,10,1,Null,120100,1,1,'NAP',NOW(),'群组投注（输钱）',Null,Null,Null,'问题 -','1,2',92,7,1,2,125100,41),
(125200,'Hedging (Losing)','Hedging (Losing)',120000,Null,30001,'Problem -',125200,400,400,10,1,Null,120200,1,2,'NAP',NOW(),'出货群组（输钱）',Null,Null,Null,'问题 -','2',93,7,4,2,125200,56),
(125300,'Arbitrage (Losing)','Arbitrage (Losing)',120000,Null,30001,'Problem -',125300,400,400,10,1,Null,120300,1,3,'NAP',NOW(),'打水套利（输钱）',Null,Null,Null,'问题 -','1,2',94,7,3,2,125300,55),
(125400,'Fixed Game (Losing)','Fixed Game (Losing)',120000,Null,30001,'Problem -',125400,400,400,10,1,Null,120400,1,4,'NAP',NOW(),'内定赛事（输钱）',Null,Null,Null,'问题 -','2',95,7,2,2,125400,52),
(125500,'Irrigation Bet (Losing)','Irrigation Bet (Losing)',120000,Null,30001,'Problem -',125500,400,400,10,1,Null,120500,1,5,'NAP',NOW(),'灌水投注（输钱)',Null,Null,Null,'问题 -','1,2',98,7,5,2,125500,57),
(125600,'Formula Bet (Losing)','Formula Bet (Losing)',120000,Null,30001,'Problem -',125600,400,400,10,1,Null,120600,1,6,'NAP',NOW(),'系统计算投注（输钱）',Null,Null,Null,'问题 -','2',99,7,6,2,125600,58),
(125800,'Info Bet (Losing)','Info Bet (Losing)',120000,Null,30001,'Problem -',125800,400,400,10,1,Null,120800,1,7,'NAP',NOW(),'资讯单（输钱）',Null,Null,Null,'问题 -','',102,7,9,2,125800,61),
(126100,'Robot (Losing)','Robot (Losing)',120000,Null,30001,'Problem -',126100,400,400,10,1,Null,121100,1,Null,'',NOW(),'机械（输钱）',Null,Null,Null,'问题 -','2',164,7,Null,2,126100,Null),
(140100,'New Agent','New Agent',140000,2,20000,'New',140100,1000,1000,30,1,Null,Null,0,Null,'',NOW(),'新代理',Null,Null,Null,'新代理','',Null,1,Null,1,140100,Null),
(140200,'Good Agent','Good Agent',140000,2,20001,'High-value',140200,1000,1000,30,1,604800,Null,0,Null,'',NOW(),'优质代理',Null,Null,Null,'高价值','',Null,1,Null,1,140200,Null),
(140300,'Normal Agent','Normal Agent',140000,2,20002,'Suspicious',140300,1000,1000,30,1,604800,Null,0,Null,'',NOW(),'普通代理',Null,Null,Null,'可疑','',Null,1,Null,1,140300,Null),
(140400,'Early Stage Probation Agent','Early Stage Probation Agent',140000,2,20003,'Moderate',140400,1000,1000,30,1,604800,Null,0,Null,'',NOW(),'前期阶段观察中代理',Null,Null,Null,'中等','',Null,2,Null,1,140400,Null),
(140500,'Smart Agent','Smart Agent',140000,2,20004,'Suspicious',140500,1000,1000,30,1,604800,Null,0,Null,'',NOW(),'精明代理',Null,Null,Null,'可疑','',Null,2,Null,1,140500,Null),
(140600,'Risky Agent','Risky Agent',140000,2,20005,'Low-value',140600,1000,1000,30,1,604800,Null,0,Null,'',NOW(),'高危代理',Null,Null,Null,'低价值','',Null,2,Null,1,140600,Null),
(140700,'Inactive Agent','Inactive Agent',140000,2,90000,'Dormant',140700,1000,1000,40,1,86400,Null,0,Null,'',NOW(),'不活跃代理',Null,Null,Null,'不活跃','',Null,8,Null,1,140700,Null);

INSERT INTO CustomerCategorySettingsAgency(CategoryID,CategoryGroupID,ParentID,IsParallelParentID,IsMultiCateIDSameParentID,IsKeepOldCateID,RemarkTemplateID)
VALUES (101010,101010,101000,0,0,0,Null),
(101011,101010,101000,0,0,0,Null),
(101012,101010,101000,0,0,0,Null),
(120100,120100,120000,0,1,1,Null),
(120200,120200,120000,0,1,1,Null),
(120300,120300,120000,0,1,1,Null),
(120400,120400,120000,0,1,1,Null),
(120500,120500,120000,0,1,1,Null),
(120600,120600,120000,0,1,1,Null),
(120800,120800,120000,0,1,1,Null),
(121100,121100,120000,0,1,1,Null),
(125100,125100,120000,0,1,1,Null),
(125200,125200,120000,0,1,1,Null),
(125300,125300,120000,0,1,1,Null),
(125400,125400,120000,0,1,1,Null),
(125500,125500,120000,0,1,1,Null),
(125600,125600,120000,0,1,1,Null),
(125800,125800,120000,0,1,1,Null),
(126100,126100,120000,0,1,1,Null),
(140100,140100,140000,0,0,0,1),
(140200,140200,140000,0,0,0,2),
(140300,140300,140000,0,0,0,3),
(140400,140400,140000,0,0,0,4),
(140500,140500,140000,0,0,0,3),
(140600,140600,140000,0,0,0,2),
(140700,140700,140000,0,0,0,5);


INSERT INTO CustomerClassificationAgency_Remark (RemarkID,RemarkTemplate,Description)
VALUES (1,'Bet Count = [BetCount]','New Agent'),
(2,'Bet Count = [BetCount] | 1-year Margin = [1yMargin] | 2-months Margin = [2mMargin]','Good/Risky Agent'),
(3,'Bet Count = [BetCount] | 1-year Margin = [1yMargin] | 2-months Margin = [2mMargin] | 1-year Win loss = [1yWinloss] | 2-months Win loss = [2mWinloss]','Normal/Smart Agent'),
(4,'Bet Count = [BetCount] | Margin = [Margin]','Early Stage Probation Agent'),
(5,'No activity in the last 30 days','Inactive Agent'),
(13,'VVIP is marked manually | [Remark]','From VVIP'),
(14,'VVIP is unmarked manually','From VVIP'),
(24,'VVIP tag is affected by Super | [Remark]','Mark VVIP For Downline'),
(25,'VVIP tag is affected by Master | [Remark]','Mark VVIP For Downline'),
(27,'VVIP untag is affected by Super','Remove VVIP For Downline'),
(28,'VVIP untag is affected by Master','Remove VVIP For Downline'),
(31,'Problem Account is marked directly | Win loss: [Winloss] | [Remark]','Problem Account is marked directly'),
(32,'Problem Account is affected by Uplines | Win loss: [Winloss] | [Remark]','Problem Account is affected by Uplines'),
(33,'Problem Account is unmarked directly | [Remark]','Problem Account is unmarked directly'),
(34,'Unmarking Problem Account is affected by Uplines | [Remark]','Unmarking Problem Account is affected by Uplines');
