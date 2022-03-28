/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220328@Long.Luu
Task:	 	Init New Categories for Losing PA [Redmine ID: 170468] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (92,'Group Betting (Probation)','Group Betting (Probation)',50,255,1,0,NOW(),'群组投注 (观察中)',52);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (94,'Arbitrage (Probation)','Arbitrage (Probation)',50,255,1,0,NOW(),'打水套利 (观察中）',54);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (98,'Irrigation Bet (Probation)','Irrigation Bet (Probation)',50,255,1,0,NOW(),'灌水投注 (观察中)',58);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (95,'Fixed Game (Probation)','Fixed Game (Probation)',50,255,1,0,NOW(),'内定赛事 (观察中)',55);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (99,'System Formula Bet (Probation)','System Formula Bet (Probation)',50,255,1,0,NOW(),'机械/系统计算投注 (观察中）',59);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (93,'Hedging (Probation)','Hedging (Probation)',50,255,1,0,NOW(),'出货群组 (观察中）',53);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (100,'Bonus Hunter (Probation)','Bonus Hunter (Probation)',50,255,1,0,NOW(),'赏金猎人 (观察中）',60);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (102,'Info Bet (Probation)','Info Bet (Probation)',50,255,1,0,NOW(),'资讯单投注 (观察中）',62);

INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (112,'Group Betting (Probation)','Group Betting (Evidence - Probation)',50,255,1,0,NOW(),'群组投注 (观察中)',52);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (114,'Arbitrage (Probation)','Arbitrage (Evidence - Probation)',50,255,1,0,NOW(),'打水套利 (观察中）',54);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (118,'Irrigation Bet (Probation)','Irrigation Bet (Evidence - Probation)',50,255,1,0,NOW(),'灌水投注 (观察中)',58);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (115,'Fixed Game (Probation)','Fixed Game (Evidence - Probation)',50,255,1,0,NOW(),'内定赛事 (观察中)',55);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (119,'System Formula Bet (Probation)','System Formula Bet (Evidence - Probation)',50,255,1,0,NOW(),'机械/系统计算投注 (观察中）',59);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (113,'Hedging (Probation)','Hedging (Evidence - Probation)',50,255,1,0,NOW(),'出货群组 (观察中）',53);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (120,'Bonus Hunter (Probation)','Bonus Hunter (Evidence - Probation)',50,255,1,0,NOW(),'赏金猎人 (观察中）',60);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (122,'Info Bet (Probation)','Info Bet (Evidence - Probation)',50,255,1,0,NOW(),'资讯单投注 (观察中）',62);

INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (132,'Group Betting (Probation)','Group Betting (M - Probation)',50,255,1,0,NOW(),'群组投注 (观察中)',52);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (134,'Arbitrage (Probation)','Arbitrage (M - Probation)',50,255,1,0,NOW(),'打水套利 (观察中）',54);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (138,'Irrigation Bet (Probation)','Irrigation Bet (M - Probation)',50,255,1,0,NOW(),'灌水投注 (观察中)',58);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (135,'Fixed Game (Probation)','Fixed Game (M - Probation)',50,255,1,0,NOW(),'内定赛事 (观察中)',55);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (139,'System Formula Bet (Probation)','System Formula Bet (M - Probation)',50,255,1,0,NOW(),'机械/系统计算投注 (观察中）',59);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (133,'Hedging (Probation)','Hedging (M - Probation)',50,255,1,0,NOW(),'出货群组 (观察中）',53);
INSERT INTO CustomerCategory(CategoryID,CategoryName,CategorySpec,ParentID,DisplayOrder,IsActive,IsUsedManually,CreatedDate,CategoryNameCN,CategoryGroup)
VALUES (142,'Info Bet (Probation)','Info Bet (M - Probation)',50,255,1,0,NOW(),'资讯单投注 (观察中）',62);

INSERT INTO CategoryToCustomerClass(CategoryID,CustomerClass)
VALUES (92,86), (94,96), (98,96), (95,106), (99,106), (93,106), (100,116), (102,126);
INSERT INTO CategoryToCustomerClass(CategoryID,CustomerClass)
VALUES (112,86), (114,96), (118,96), (115,106), (119,106), (113,106), (120,116), (122,126);
INSERT INTO CategoryToCustomerClass(CategoryID,CustomerClass)
VALUES (132,86), (134,96), (138,96), (135,106), (139,106), (133,106), (140,116), (142,126);

INSERT INTO CategoryToDangerLevel(CategoryID, IsLicensee, TypeID, DangerLevel)
VALUES (92,0,2,1),(92,1,2,11),(94,0,2,3),(94,1,2,13),(98,0,2,5),(98,1,2,15),(95,0,2,2),(95,1,2,12),(99,0,2,6),(99,1,2,16),(93,0,2,4),(93,1,2,14),(100,1,2,18),(102,0,2,9),(102,1,2,19);
INSERT INTO CategoryToDangerLevel(CategoryID, IsLicensee, TypeID, DangerLevel)
VALUES (112,0,2,1),(112,1,2,11),(114,0,2,3),(114,1,2,13),(118,0,2,5),(118,1,2,15),(115,0,2,2),(115,1,2,12),(119,0,2,6),(119,1,2,16),(113,0,2,4),(113,1,2,14),(120,1,2,18),(122,0,2,9),(122,1,2,19);
INSERT INTO CategoryToDangerLevel(CategoryID, IsLicensee, TypeID, DangerLevel)
VALUES (132,0,2,1),(132,1,2,11),(134,0,2,3),(134,1,2,13),(138,0,2,5),(138,1,2,15),(135,0,2,2),(135,1,2,12),(139,0,2,6),(139,1,2,16),(133,0,2,4),(133,1,2,14),(140,1,2,18),(142,0,2,9),(142,1,2,19);
