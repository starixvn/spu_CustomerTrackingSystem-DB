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

INSERT INTO CustomerCategoryAgency(CategoryID,CategoryName,CategorySpec,ParentID,RoleID,CustomerClass,CustomerClassName,CategoryGroupID,CategoryPriority,CustomerClassPriority,BusinessCategoryGroupID,IsActive,ScanIntervalInSecond,RelevantCategoryID,IsHedgingReasonMM,IsPAProbation,AFCFraudID,DataSource,CreatedDate,CategoryNameCN,CategoryNameCN3,CategoryNameTHB,CategoryNameIND,CustomerClassNameCN,SabaSportType,OldCategoryID,ColorTypeID,Ext_ABIDangerLevel_Credit,Ext_DangerLevelType,Ext_CategoryGroupID,Ext_EvidenceID_Credit)
VALUES (101010,'VVIP Agent','VVIP Agent',101000,2,999,'Healthy',101010,10,10,30,1,Null,Null,Null,0,Null,Null,NOW(),'超级贵宾',Null,Null,Null,'健康',Null,210,1,Null,1,101010,Null),
(101011,'VVIP (internal)','VVIP',101000,3,999,'Healthy',101010,10,10,30,1,Null,Null,Null,0,Null,Null,NOW(),'超级贵宾',Null,Null,Null,'健康',Null,210,1,Null,1,101010,Null),
(101012,'VVIP (internal)','VVIP',101000,4,999,'Healthy',101010,10,10,30,1,Null,Null,Null,0,Null,Null,NOW(),'超级贵宾',Null,Null,Null,'健康',Null,210,1,Null,1,101010,Null),
(120100,'Group Betting','Group Betting',120000,Null,30000,'Problem',120100,400,400,10,1,Null,125100,Null,0,1,'CTS',NOW(),'群组投注',Null,Null,Null,'问题','1,2',52,6,1,2,120100,41),
(120101,'Group Betting','Group Betting (Evidence)',120000,Null,30000,'Problem',120100,400,400,10,1,Null,125101,Null,0,1,'Evidence',NOW(),'群组投注',Null,Null,Null,'问题','1,2',72,6,1,2,120100,41),
(120102,'Group Betting','Group Betting(M)',120000,Null,30000,'Problem',120100,400,400,10,1,Null,125102,Null,0,1,'NAP',NOW(),'群组投注',Null,Null,Null,'问题','1,2',152,6,1,2,120100,41),
(120103,'Group Betting','Group Betting - Abnormal Account, IssueType:13',120000,Null,30000,'Problem',120100,400,400,10,1,Null,125103,Null,0,1,'NAP',NOW(),'群组投注',Null,Null,Null,'问题','1,2',172,6,1,2,120100,41),
(120200,'Hedging','Hedging',120000,Null,30000,'Problem',120200,400,400,10,1,Null,125200,1,0,2,'CTS',NOW(),'出货群组',Null,Null,Null,'问题','2',53,6,4,2,120200,56),
(120201,'Hedging','Hedging (Evidence)',120000,Null,30000,'Problem',120200,400,400,10,1,Null,125201,1,0,2,'Evidence',NOW(),'出货群组',Null,Null,Null,'问题','2',73,6,4,2,120200,56),
(120202,'Hedging','Hedging(M)',120000,Null,30000,'Problem',120200,400,400,10,1,Null,125202,1,0,2,'NAP',NOW(),'出货群组',Null,Null,Null,'问题','2',153,6,4,2,120200,56),
(120203,'Hedging','Hedging - Abnormal Account, IssueType:13',120000,Null,30000,'Problem',120200,400,400,10,1,Null,125203,1,0,2,'NAP',NOW(),'出货群组',Null,Null,Null,'问题','2',173,6,4,2,120200,56),
(120300,'Arbitrage','Arbitrage',120000,Null,30000,'Problem',120300,400,400,10,1,Null,125300,Null,0,3,'CTS',NOW(),'打水套利',Null,Null,Null,'问题','1,2',54,6,3,2,120300,55),
(120301,'Arbitrage','Arbitrage (Evidence)',120000,Null,30000,'Problem',120300,400,400,10,1,Null,125301,Null,0,3,'Evidence',NOW(),'打水套利',Null,Null,Null,'问题','1,2',74,6,3,2,120300,55),
(120302,'Arbitrage','Arbitrage(M)',120000,Null,30000,'Problem',120300,400,400,10,1,Null,125302,Null,0,3,'NAP',NOW(),'打水套利',Null,Null,Null,'问题','1,2',154,6,3,2,120300,55),
(120303,'Arbitrage','Arbitrage - Abnormal Account, IssueType:13',120000,Null,30000,'Problem',120300,400,400,10,1,Null,125303,Null,0,3,'NAP',NOW(),'打水套利',Null,Null,Null,'问题','1,2',174,6,3,2,120300,55),
(120400,'Fixed Game','Fixed Game',120000,Null,30000,'Problem',120400,400,400,10,1,Null,125400,Null,0,4,'CTS',NOW(),'内定赛事',Null,Null,Null,'问题','2',55,6,2,2,120400,52),
(120401,'Fixed Game','Fixed Game (Evidence)',120000,Null,30000,'Problem',120400,400,400,10,1,Null,125401,Null,0,4,'Evidence',NOW(),'内定赛事',Null,Null,Null,'问题','2',75,6,2,2,120400,52),
(120402,'Fixed Game','Fixed Game(M)',120000,Null,30000,'Problem',120400,400,400,10,1,Null,125402,Null,0,4,'NAP',NOW(),'内定赛事',Null,Null,Null,'问题','2',155,6,2,2,120400,52),
(120403,'Fixed Game','Fixed Game - Abnormal Account, IssueType:13',120000,Null,30000,'Problem',120400,400,400,10,1,Null,125403,Null,0,4,'NAP',NOW(),'内定赛事',Null,Null,Null,'问题','2',175,6,2,2,120400,52),
(120500,'Irrigation Bet','Irrigation Bet',120000,Null,30000,'Problem',120500,400,400,10,1,Null,125500,Null,0,5,'CTS',NOW(),'灌水投注',Null,Null,Null,'问题','1,2',58,6,5,2,120500,57),
(120501,'Irrigation Bet','Irrigation Bet (Evidence)',120000,Null,30000,'Problem',120500,400,400,10,1,Null,125501,Null,0,5,'Evidence',NOW(),'灌水投注',Null,Null,Null,'问题','1,2',78,6,5,2,120500,57),
(120502,'Irrigation Bet','Irrigation Bet(M)',120000,Null,30000,'Problem',120500,400,400,10,1,Null,125502,Null,0,5,'NAP',NOW(),'灌水投注',Null,Null,Null,'问题','1,2',158,6,5,2,120500,57),
(120503,'Irrigation Bet','Irrigation Bet - Abnormal Account, IssueType:13',120000,Null,30000,'Problem',120500,400,400,10,1,Null,125503,Null,0,5,'NAP',NOW(),'灌水投注',Null,Null,Null,'问题','1,2',177,6,5,2,120500,57),
(120600,'Formula Bet','System Formula Bet',120000,Null,30000,'Problem',120600,400,400,10,1,Null,125600,Null,0,6,'CTS',NOW(),'系统计算投注',Null,Null,Null,'问题','2',59,6,6,2,120600,58),
(120601,'Formula Bet','System Formula Bet (Evidence)',120000,Null,30000,'Problem',120600,400,400,10,1,Null,125601,Null,0,6,'Evidence',NOW(),'系统计算投注',Null,Null,Null,'问题','2',79,6,6,2,120600,58),
(120602,'Formula Bet','System Formula Bet(M)',120000,Null,30000,'Problem',120600,400,400,10,1,Null,125602,Null,0,6,'NAP',NOW(),'系统计算投注',Null,Null,Null,'问题','2',159,6,6,2,120600,58),
(120603,'Formula Bet','System Formula Bet - Abnormal Account, IssueType:13',120000,Null,30000,'Problem',120600,400,400,10,1,Null,125603,Null,0,6,'NAP',NOW(),'系统计算投注',Null,Null,Null,'问题','2',178,6,6,2,120600,58),
(120800,'Info Bet','Info Bet',120000,Null,30000,'Problem',120800,400,400,10,1,Null,125800,Null,0,7,'CTS',NOW(),'资讯单',Null,Null,Null,'问题',Null,162,6,9,2,120800,61),
(120801,'Info Bet','Info Bet (Evidence)',120000,Null,30000,'Problem',120800,400,400,10,1,Null,125801,Null,0,7,'Evidence',NOW(),'资讯单',Null,Null,Null,'问题',Null,82,6,9,2,120800,61),
(120802,'Info Bet','Info Bet (M)',120000,Null,30000,'Problem',120800,400,400,10,1,Null,125802,Null,0,7,'NAP',NOW(),'资讯单',Null,Null,Null,'问题',Null,162,6,9,2,120800,61),
(121100,'Robot','Robot',120000,Null,30000,'Problem',121100,400,400,10,1,Null,126100,Null,0,Null,Null,NOW(),'机械',Null,Null,Null,'问题','2',163,6,Null,2,121100,Null),
(125100,'Group Betting (Losing)','Group Betting (Losing)',120000,2,30001,'Problem -',125100,400,400,10,1,Null,120100,Null,1,1,'CTS',NOW(),'群组投注（输钱）',Null,Null,Null,'问题 -','1,2',92,7,1,2,125100,41),
(125101,'Group Betting (Losing)','Group Betting (Evidence - Probation)',120000,2,30001,'Problem -',125100,400,400,10,1,Null,120101,Null,1,1,'Evidence',NOW(),'群组投注 (输钱)',Null,Null,Null,'问题 -','1,2',112,7,1,2,125100,41),
(125102,'Group Betting (Losing)','Group Betting (M - Probation)',120000,2,30001,'Problem -',125100,400,400,10,1,Null,120102,Null,1,1,'NAP',NOW(),'群组投注 (输钱)',Null,Null,Null,'问题 -','1,2',132,7,1,2,125100,41),
(125103,'Group Betting (Losing)','Group Betting (Probation) - Abnormal Account, IssueType:13',120000,2,30001,'Problem -',125100,400,400,10,1,Null,120103,Null,1,1,'NAP',NOW(),'群组投注 (输钱)',Null,Null,Null,'问题 -','1,2',180,7,1,2,125100,41),
(125200,'Hedging (Losing)','Hedging (Losing)',120000,2,30001,'Problem -',125200,400,400,10,1,Null,120200,1,1,2,'CTS',NOW(),'出货群组（输钱）',Null,Null,Null,'问题 -','2',93,7,4,2,125200,56),
(125201,'Hedging (Losing)','Hedging (Evidence - Probation)',120000,2,30001,'Problem -',125200,400,400,10,1,Null,120201,1,1,2,'Evidence',NOW(),'出货群组 (输钱)',Null,Null,Null,'问题 -','2',113,7,4,2,125200,56),
(125202,'Hedging (Losing)','Hedging (M - Probation)',120000,2,30001,'Problem -',125200,400,400,10,1,Null,120202,1,1,2,'NAP',NOW(),'出货群组 (输钱)',Null,Null,Null,'问题 -','2',133,7,4,2,125200,56),
(125203,'Hedging (Losing)','Hedging (Probation) - Abnormal Account, IssueType:13',120000,2,30001,'Problem -',125200,400,400,10,1,Null,120203,1,1,2,'NAP',NOW(),'出货群组 (输钱)',Null,Null,Null,'问题 -','2',181,7,4,2,125200,56),
(125300,'Arbitrage (Losing)','Arbitrage (Losing)',120000,2,30001,'Problem -',125300,400,400,10,1,Null,120300,Null,1,3,'CTS',NOW(),'打水套利（输钱）',Null,Null,Null,'问题 -','1,2',94,7,3,2,125300,55),
(125301,'Arbitrage (Losing)','Arbitrage (Evidence - Probation)',120000,2,30001,'Problem -',125300,400,400,10,1,Null,120301,Null,1,3,'Evidence',NOW(),'打水套利 (输钱)',Null,Null,Null,'问题 -','1,2',114,7,3,2,125300,55),
(125302,'Arbitrage (Losing)','Arbitrage (M - Probation)',120000,2,30001,'Problem -',125300,400,400,10,1,Null,120302,Null,1,3,'NAP',NOW(),'打水套利 (输钱)',Null,Null,Null,'问题 -','1,2',134,7,3,2,125300,55),
(125303,'Arbitrage (Losing)','Arbitrage (Probation) - Abnormal Account, IssueType:13',120000,2,30001,'Problem -',125300,400,400,10,1,Null,120303,Null,1,3,'NAP',NOW(),'打水套利 (输钱)',Null,Null,Null,'问题 -','1,2',182,7,3,2,125300,55),
(125400,'Fixed Game (Losing)','Fixed Game (Losing)',120000,2,30001,'Problem -',125400,400,400,10,1,Null,120400,Null,1,4,'CTS',NOW(),'内定赛事（输钱）',Null,Null,Null,'问题 -','2',95,7,2,2,125400,52),
(125401,'Fixed Game (Losing)','Fixed Game (Evidence - Probation)',120000,2,30001,'Problem -',125400,400,400,10,1,Null,120401,Null,1,4,'Evidence',NOW(),'内定赛事 (输钱)',Null,Null,Null,'问题 -','2',115,7,2,2,125400,52),
(125402,'Fixed Game (Losing)','Fixed Game (M - Probation)',120000,2,30001,'Problem -',125400,400,400,10,1,Null,120402,Null,1,4,'NAP',NOW(),'内定赛事 (输钱)',Null,Null,Null,'问题 -','2',135,7,2,2,125400,52),
(125403,'Fixed Game (Losing)','Fixed Game (Probation) - Abnormal Account, IssueType:13',120000,2,30001,'Problem -',125400,400,400,10,1,Null,120403,Null,1,4,'NAP',NOW(),'内定赛事 (输钱)',Null,Null,Null,'问题 -','2',183,7,2,2,125400,52),
(125500,'Irrigation Bet (Losing)','Irrigation Bet (Losing)',120000,2,30001,'Problem -',125500,400,400,10,1,Null,120500,Null,1,5,'CTS',NOW(),'灌水投注（输钱)',Null,Null,Null,'问题 -','1,2',98,7,5,2,125500,57),
(125501,'Irrigation Bet (Losing)','Irrigation Bet (Evidence - Probation)',120000,2,30001,'Problem -',125500,400,400,10,1,Null,120501,Null,1,5,'Evidence',NOW(),'灌水投注 (输钱)',Null,Null,Null,'问题 -','1,2',118,7,5,2,125500,57),
(125502,'Irrigation Bet (Losing)','Irrigation Bet (M - Probation)',120000,2,30001,'Problem -',125500,400,400,10,1,Null,120502,Null,1,5,'NAP',NOW(),'灌水投注 (输钱)',Null,Null,Null,'问题 -','1,2',138,7,5,2,125500,57),
(125503,'Irrigation Bet (Losing)','Irrigation Bet (Probation) - Abnormal Account, IssueType:13',120000,2,30001,'Problem -',125500,400,400,10,1,Null,120503,Null,1,5,'NAP',NOW(),'灌水投注 (输钱)',Null,Null,Null,'问题 -','1,2',184,7,5,2,125500,57),
(125600,'Formula Bet (Losing)','Formula Bet (Losing)',120000,2,30001,'Problem -',125600,400,400,10,1,Null,120600,Null,1,6,'CTS',NOW(),'系统计算投注（输钱）',Null,Null,Null,'问题 -','2',99,7,6,2,125600,58),
(125601,'Formula Bet (Losing)','System Formula Bet (Evidence - Probation)',120000,2,30001,'Problem -',125600,400,400,10,1,Null,120601,Null,1,6,'Evidence',NOW(),'机械/系统计算投注 (输钱)',Null,Null,Null,'问题 -','2',119,7,6,2,125600,58),
(125602,'Formula Bet (Losing)','System Formula Bet (M - Probation)',120000,2,30001,'Problem -',125600,400,400,10,1,Null,120602,Null,1,6,'NAP',NOW(),'机械/系统计算投注 (输钱)',Null,Null,Null,'问题 -','2',139,7,6,2,125600,58),
(125603,'Formula Bet (Losing)','System Formula Bet (Probation) - Abnormal Account, IssueType:13',120000,2,30001,'Problem -',125600,400,400,10,1,Null,120603,Null,1,6,'NAP',NOW(),'机械/系统计算投注 (输钱)',Null,Null,Null,'问题 -','2',185,7,6,2,125600,58),
(125800,'Info Bet (Losing)','Info Bet (Losing)',120000,2,30001,'Problem -',125800,400,400,10,1,Null,120800,Null,1,7,'CTS',NOW(),'资讯单（输钱）',Null,Null,Null,'问题 -',Null,102,7,9,2,125800,61),
(125801,'Info Bet (Losing)','Info Bet (Evidence - Probation)',120000,2,30001,'Problem -',125800,400,400,10,1,Null,120801,Null,1,7,'Evidence',NOW(),'资讯单投注 (输钱)',Null,Null,Null,'问题 -',Null,122,7,9,2,125800,61),
(125802,'Info Bet (Losing)','Info Bet (M - Probation)',120000,2,30001,'Problem -',125800,400,400,10,1,Null,120802,Null,1,7,'NAP',NOW(),'资讯单投注 (输钱)',Null,Null,Null,'问题 -',Null,142,7,9,2,125800,61),
(126100,'Robot (Losing)','Robot (Losing)',120000,2,30001,'Problem -',126100,400,400,10,1,Null,121100,Null,1,Null,Null,NOW(),'机械（输钱）',Null,Null,Null,'问题 -','2',164,7,Null,2,126100,Null),
(140100,'New Agent','New Agent',140000,2,20000,'New',140100,1000,1000,30,1,Null,Null,Null,0,Null,Null,NOW(),'新代理',Null,Null,Null,'新代理',Null,Null,1,Null,1,140100,Null),
(140200,'Good Agent','Good Agent',140000,2,20001,'High-value',140200,1000,1000,30,1,604800,Null,Null,0,Null,Null,NOW(),'优质代理',Null,Null,Null,'高价值',Null,Null,1,Null,1,140200,Null),
(140300,'Normal Agent','Normal Agent',140000,2,20002,'Suspicious',140300,1000,1000,30,1,604800,Null,Null,0,Null,Null,NOW(),'普通代理',Null,Null,Null,'可疑',Null,Null,1,Null,1,140300,Null),
(140500,'Smart Agent','Smart Agent',140000,2,20004,'Suspicious',140500,1000,1000,30,1,604800,Null,Null,0,Null,Null,NOW(),'精明代理',Null,Null,Null,'可疑',Null,Null,2,Null,1,140500,Null),
(140600,'Risky Agent','Risky Agent',140000,2,20005,'Low-value',140600,1000,1000,30,1,604800,Null,Null,0,Null,Null,NOW(),'高危代理',Null,Null,Null,'低价值',Null,Null,2,Null,1,140600,Null),
(140700,'Inactive Agent','Inactive Agent',140000,2,90000,'Dormant',140700,1000,1000,40,1,Null,Null,Null,0,Null,Null,NOW(),'不活跃代理',Null,Null,Null,'不活跃',Null,Null,8,Null,1,140700,Null),
(140800,'Early Stage Probation Agent','Early Stage Probation Agent',140000,2,20003,'Moderate',140800,1000,1000,30,1,604800,Null,Null,0,Null,Null,NOW(),'前期阶段观察中代理',Null,Null,Null,'中等',Null,Null,2,Null,1,140800,Null);

INSERT INTO CustomerCategorySettingsAgency(CategoryID,CategoryGroupID,ParentID,IsParallelParentID,IsMultiCateIDSameParentID,IsKeepOldCateID,RemarkTemplateID)
VALUES (101010,101010,101000,0,0,0,Null),
(101011,101010,101000,0,0,0,Null),
(101012,101010,101000,0,0,0,Null),
(120100,120100,120000,0,1,1,Null),
(120101,120100,120000,0,1,1,Null),
(120102,120100,120000,0,1,1,Null),
(120103,120100,120000,0,1,1,Null),
(120200,120200,120000,0,1,1,Null),
(120201,120200,120000,0,1,1,Null),
(120202,120200,120000,0,1,1,Null),
(120203,120200,120000,0,1,1,Null),
(120300,120300,120000,0,1,1,Null),
(120301,120300,120000,0,1,1,Null),
(120302,120300,120000,0,1,1,Null),
(120303,120300,120000,0,1,1,Null),
(120400,120400,120000,0,1,1,Null),
(120401,120400,120000,0,1,1,Null),
(120402,120400,120000,0,1,1,Null),
(120403,120400,120000,0,1,1,Null),
(120500,120500,120000,0,1,1,Null),
(120501,120500,120000,0,1,1,Null),
(120502,120500,120000,0,1,1,Null),
(120503,120500,120000,0,1,1,Null),
(120600,120600,120000,0,1,1,Null),
(120601,120600,120000,0,1,1,Null),
(120602,120600,120000,0,1,1,Null),
(120603,120600,120000,0,1,1,Null),
(120800,120800,120000,0,1,1,Null),
(120801,120800,120000,0,1,1,Null),
(120802,120800,120000,0,1,1,Null),
(121100,121100,120000,0,1,1,Null),
(125100,125100,120000,0,1,1,Null),
(125101,125100,120000,0,1,1,Null),
(125102,125100,120000,0,1,1,Null),
(125103,125100,120000,0,1,1,Null),
(125200,125200,120000,0,1,1,Null),
(125201,125200,120000,0,1,1,Null),
(125202,125200,120000,0,1,1,Null),
(125203,125200,120000,0,1,1,Null),
(125300,125300,120000,0,1,1,Null),
(125301,125300,120000,0,1,1,Null),
(125302,125300,120000,0,1,1,Null),
(125303,125300,120000,0,1,1,Null),
(125400,125400,120000,0,1,1,Null),
(125401,125400,120000,0,1,1,Null),
(125402,125400,120000,0,1,1,Null),
(125403,125400,120000,0,1,1,Null),
(125500,125500,120000,0,1,1,Null),
(125501,125500,120000,0,1,1,Null),
(125502,125500,120000,0,1,1,Null),
(125503,125500,120000,0,1,1,Null),
(125600,125600,120000,0,1,1,Null),
(125601,125600,120000,0,1,1,Null),
(125602,125600,120000,0,1,1,Null),
(125603,125600,120000,0,1,1,Null),
(125800,125800,120000,0,1,1,Null),
(125801,125800,120000,0,1,1,Null),
(125802,125800,120000,0,1,1,Null),
(126100,126100,120000,0,1,1,Null),
(140100,140100,140000,0,0,0,40),
(140200,140200,140000,0,0,0,41),
(140300,140300,140000,0,0,0,41),
(140500,140500,140000,0,0,0,41),
(140600,140600,140000,0,0,0,41),
(140700,140700,140000,0,0,0,18),
(140800,140800,140000,0,0,0,42);

INSERT INTO CustomerClassificationAgency_Remark (RemarkID,RemarkTemplate,Description)
VALUES (1,'Account has less than 40 bets for first time scan','New: New Customer'),
(2,'Re-scan after 40 bets',''),
(3,'Re-scan on Schedule Date',''),
(13,'VVIP is marked manually | [Remark]','From VVIP'),
(14,'VVIP is unmarked manually','From VVIP'),
(18,'No activity in the last 30 days','Inactive Agent'),
(24,'VVIP tag is affected by Super | [Remark]','Mark VVIP For Downline'),
(25,'VVIP tag is affected by Master | [Remark]','Mark VVIP For Downline'),
(27,'VVIP untag is affected by Super','Remove VVIP For Downline'),
(28,'VVIP untag is affected by Master','Remove VVIP For Downline'),
(30,'VVIP tag is affected by direct upline | [Remark]','New incoming Agent'),
(31,'Problem Account is marked directly | Win loss: [Winloss] | Margin: [Margin] | [Remark]','Problem Account is marked directly'),
(32,'Problem Account is affected by Uplines | Win loss: [Winloss] | Margin: [Margin] | [Remark]','Problem Account is affected by Uplines'),
(33,'Problem Account is unmarked directly | [Remark]','Problem Account is unmarked directly'),
(34,'Unmarking Problem Account is affected by Uplines | [Remark]','Unmarking Problem Account is affected by Uplines'),
(40,'Bet Count: [BetCount]','New Agent'),
(41,'1-year Win loss: [1yWinloss] | Margin: [1yMargin] | Bet Count: [1yBetCount]<br/>2-months Win loss: [2mWinloss] | Margin: [2mMargin] | Bet Count: [2mBetCount]','Good/Normal/Smart/Risky Agent'),
(42,'Win loss: [Winloss] | Margin: [Margin] | Bet Count: [BetCount]','Early Stage Probation Agent');

/*SELECT ag.CategoryName, mb.CategoryName, CONCAT(',(',ag.CategoryID,',', 2,',', mb.CategoryID ,',', 1 ,')')
FROM CustomerCategoryAgency AS ag
	LEFT JOIN CustomerCategory AS mb ON ag.CategoryID = mb.CategoryID + 100000
WHERE ag.ParentID = 120000;
*/

INSERT INTO CustomerCategoryDownlineMapping(FromCategoryID,FromRoleID,ToCategoryID,ToRoleID)
VALUES (101011,4,101010,3)
	,(101011,4,101010,2)
    ,(101010,4,1010,1)
	,(101011,3,101010,2)
    ,(101011,3,101010,1)
	,(101010,2,1010,1)
	,(120100,2,20100,1)
	,(120101,2,20101,1)
	,(120102,2,20102,1)
	,(120103,2,20103,1)
	,(120200,2,20200,1)
	,(120201,2,20201,1)
	,(120202,2,20202,1)
	,(120203,2,20203,1)
	,(120300,2,20300,1)
	,(120301,2,20301,1)
	,(120302,2,20302,1)
	,(120303,2,20303,1)
	,(120400,2,20400,1)
	,(120401,2,20401,1)
	,(120402,2,20402,1)
	,(120403,2,20403,1)
	,(120500,2,20500,1)
	,(120501,2,20501,1)
	,(120502,2,20502,1)
	,(120503,2,20503,1)
	,(120600,2,20600,1)
	,(120601,2,20601,1)
	,(120602,2,20602,1)
	,(120603,2,20603,1)
	,(120800,2,20800,1)
	,(120801,2,20801,1)
	,(120802,2,20802,1)
	,(121100,2,21100,1)
	,(125100,2,25100,1)
	,(125101,2,25101,1)
	,(125102,2,25102,1)
	,(125103,2,25103,1)
	,(125200,2,25200,1)
	,(125201,2,25201,1)
	,(125202,2,25202,1)
	,(125203,2,25203,1)
	,(125300,2,25300,1)
	,(125301,2,25301,1)
	,(125302,2,25302,1)
	,(125303,2,25303,1)
	,(125400,2,25400,1)
	,(125401,2,25401,1)
	,(125402,2,25402,1)
	,(125403,2,25403,1)
	,(125500,2,25500,1)
	,(125501,2,25501,1)
	,(125502,2,25502,1)
	,(125503,2,25503,1)
	,(125600,2,25600,1)
	,(125601,2,25601,1)
	,(125602,2,25602,1)
	,(125603,2,25603,1)
	,(125800,2,25800,1)
	,(125801,2,25801,1)
	,(125802,2,25802,1)
	,(126100,2,26100,1);

INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(175,'DailyScan_Agency_Normal_BatchSize','DailyScan_Agency_Normal_BatchSize','INT','500');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(176,'DailyScan_Agency_Normal_LastCategoryID','DailyScan_Agency_Normal_LastCategoryID','INT','0');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(177,'DailyScan_Agency_Normal_LastCustID','DailyScan_Agency_Normal_LastCustID','BIGINT','0');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(178,'InactiveNewAgency_LastCategoryID','InactiveNewAgency_LastCategoryID','INT','0');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(179,'InactiveNewAgency_LastCustID','InactiveNewAgency_LastCustID','INT','0');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(180,'ReScanNewMemberAgency_LastCTSCustID','ReScanNewMemberAgency_LastCTSCustID','INT','0');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(181,'InactiveNewAgency_BatchSize','BatchSize Config for Inactive New Agency Scan','INT','500');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(182,'DailyScan_InactiveNewAgency_LastCategoryID','Daily Scan Inactive New Agency Last CategoryID','INT','140100');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(183,'DailyScan_InactiveNewAgency_LastCustID','Daily Scan Inactive New Agency Last CustID','BIGINT UNSIGNED','0');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(184,'ReScanNewAgent_LastCTSCustID','ReScanNewMember_LastCTSCustID','BIGINT UNSIGNED','0');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(185,'ReScanNewAgent_BatchSize','ReScanNewMember_BatchSize','INT','5000');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(186,'SabaDangerLevel_Agency_LastHistoryID','SabaDangerLevel_Agency_LastHistoryID','BIGINT','0');
INSERT INTO SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) VALUES(187,'SabaDangerLevel_Agency_ScanBatchSize','SabaDangerLevel_Agency_ScanBatchSize','INT','1000');

UPDATE SystemParameter
SET ParameterValue = (SELECT ParameterValue FROM SystemParamer WHERE ParameterID = 92)
WHERE ParameterID = 184;