/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220328@Long.Luu
Task:	 	Init New Categories for Losing PA [Redmine ID: 170468] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (92,'Group Betting (Probation)','Group Betting (Probation)',50,1,1,0,NOW(),'群组投注 (观察中)',52);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (94,'Arbitrage (Probation)','Arbitrage (Probation)',50,2,1,0,NOW(),'打水套利 (观察中）',54);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (98,'Irrigation Bet (Probation)','Irrigation Bet (Probation)',50,3,1,0,NOW(),'灌水投注 (观察中)',58);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (95,'Fixed Game (Probation)','Fixed Game (Probation)',50,4,1,0,NOW(),'内定赛事 (观察中)',55);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (99,'System Formula Bet (Probation)','System Formula Bet (Probation)',50,5,1,0,NOW(),'机械/系统计算投注 (观察中）',59);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (93,'Hedging (Probation)','Hedging (Probation)',50,6,1,0,NOW(),'出货群组 (观察中）',53);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (100,'Bonus Hunter (Probation)','Bonus Hunter (Probation)',50,7,1,0,NOW(),'赏金猎人 (观察中）',60);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (102,'Info Bet (Probation)','Info Bet (Probation)',50,8,1,0,NOW(),'资讯单投注 (观察中）',62);

INSERT INTO CategoryToCustomerClass(CategoryID,CustomerClass)
VALUES (92,86), (94,96), (98,96), (95,106), (99,106), (93,106), (100,116), (102,126);

INSERT INTO CategoryToDangerLevel(CategoryID, IsLicensee, TypeID, DangerLevel)
VALUES (92,0,2,1),(92,1,2,11),(94,0,2,3),(94,1,2,13),(98,0,2,5),(98,1,2,15),(95,0,2,2),(95,1,2,12),(99,0,2,6),(99,1,2,16),(93,0,2,4),(93,1,2,14),(100,1,2,18),(102,0,2,9),(102,1,2,19);
