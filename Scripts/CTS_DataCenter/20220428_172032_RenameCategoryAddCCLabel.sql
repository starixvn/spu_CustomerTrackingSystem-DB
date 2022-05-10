/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220428@Casey.Huynh
    Task:	 	20220428@Casey.Huynh: Rename Category Add CC Label  [Redmine ID: #172032]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
ALTER TABLE CustomerCategory
	ADD COLUMN CustomerClassName VARCHAR(50) AFTER CustomerClass
,	ADD COLUMN CustomerClassNameCN VARCHAR(50) AFTER CustomerClassName;

CREATE TABLE CustomerCategory_BK LIKE CustomerCategory;
INSERT INTO CustomerCategory_BK SELECT * FROM CustomerCategory;
/*
ALTER TABLE CategoryToCustomerClass
	ADD COLUMN CustomerClassName VARCHAR(50) AFTER CustomerClass
,	ADD COLUMN CustomerClassNameCN VARCHAR(50) AFTER CustomerClassName;

CREATE TABLE CategoryToCustomerClass_BK LIKE CategoryToCustomerClass;
INSERT INTO CategoryToCustomerClass_BK SELECT * FROM CategoryToCustomerClass;
*/

DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
CREATE TEMPORARY TABLE Temp_CustomerCategory (
  `CategoryID` smallint unsigned PRIMARY KEY,
  `CategoryName` varchar(50),
  `CategoryNameCN` varchar(50) ,
  `CustomerClassName` varchar(50),
  `CustomerClassNameCN` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL
);

INSERT INTO Temp_CustomerCategory (CategoryID, CategoryName, CategoryNameCN, CustomerClassName, CustomerClassNameCN)
VALUES (56,'AB Bet','AB投注','Problems','問題')
,(76,'AB Bet','AB投注','Problems','問題')
,(156,'AB Bet','AB投注','Problems','問題')
,(51,'Abnormal','非正常','','')
,(151,'Abnormal','非正常','','')
,(54,'Arbitrage','打水套利','Problems','問題')
,(74,'Arbitrage','打水套利','Problems','問題')
,(154,'Arbitrage','打水套利','Problems','問題')
,(94,'Arbitrage (low)','打水套利 (观察中)','Problems -','問題-')
,(114,'Arbitrage (low)','打水套利 (观察中)','Problems -','問題-')
,(134,'Arbitrage (low)','打水套利 (观察中)','Problems -','問題-')
,(163,'Bad Robot User','非正常机械玩家','Robot','機械')
,(60,'Bonus Hunter','赏金猎人','Problems','問題')
,(80,'Bonus Hunter','赏金猎人','Problems','問題')
,(100,'Bonus Hunter (low)','赏金猎人 (观察中)','Problems -','問題-')
,(120,'Bonus Hunter (low)','赏金猎人 (观察中)','Problems -','問題-')
,(55,'Fixed Game','内定赛事','Problems','問題')
,(75,'Fixed Game','内定赛事','Problems','問題')
,(155,'Fixed Game','内定赛事','Problems','問題')
,(95,'Fixed Game (low)','内定赛事 (观察中)','Problems -','問題-')
,(115,'Fixed Game (low)','内定赛事 (观察中)','Problems -','問題-')
,(135,'Fixed Game (low)','内定赛事 (观察中)','Problems -','問題-')
,(205,'Good','优质会员','Healthy +','健康+')
,(211,'Good linked Group','优质会员关联群组投注会员','Healthy -','健康-')
,(212,'Good linked PA','优质会员关联问题会员','Healthy -','健康-')
,(213,'Good linked Robot','优质会员关联机械投注会员','Healthy -','健康-')
,(164,'Good Robot User','正常机械玩家','Robot','機械')
,(52,'Group Betting','群组投注','Problems','問題')
,(72,'Group Betting','群组投注','Problems','問題')
,(152,'Group Betting','群组投注','Problems','問題')
,(92,'Group Betting (low)','群组投注 (观察中)','Problems -','問題-')
,(112,'Group Betting (low)','群组投注 (观察中)','Problems -','問題-')
,(132,'Group Betting (low)','群组投注 (观察中)','Problems -','問題-')
,(53,'Hedging','出货群组','Problems','問題')
,(73,'Hedging','出货群组','Problems','問題')
,(153,'Hedging','出货群组','Problems','問題')
,(93,'Hedging (low)','出货群组 (观察中)','Problems -','問題-')
,(113,'Hedging (low)','出货群组 (观察中)','Problems -','問題-')
,(133,'Hedging (low)','出货群组 (观察中)','Problems -','問題-')
,(204,'Risky','高危玩家','Dangerous','危險')
,(274,'Risky (Lic Sub)','高风险玩家','Dangerous','危險')
,(271,'Risky linked Group','高危玩家关联群组投注会员','Dangerous +','危險+')
,(272,'Risky linked PA','高危玩家关联问题会员','Dangerous +','危險+')
,(273,'Risky linked Robot','高危玩家关联机械投注会员','Dangerous +','危險+')
,(277,'Risky Group Betting','怀疑群组投注高危玩家','Dangerous +','危險+')
,(278,'Risky High Rejected','怀疑资讯投注高危玩家','Dangerous +','危險+')
,(62,'Info Bet','资讯单','Problems','問題')
,(82,'Info Bet','资讯单','Problems','問題')
,(162,'Info Bet','资讯单','Problems','問題')
,(102,'Info Bet (low)','资讯单投注 (观察中)','Problems -','問題-')
,(122,'Info Bet (low)','资讯单投注 (观察中)','Problems -','問題-')
,(142,'Info Bet (low)','资讯单投注 (观察中)','Problems -','問題-')
,(58,'Irrigation Bet','灌水投注','Problems','問題')
,(78,'Irrigation Bet','灌水投注','Problems','問題')
,(158,'Irrigation Bet','灌水投注','Problems','問題')
,(98,'Irrigation Bet (low)','灌水投注 (观察中)','Problems -','問題-')
,(118,'Irrigation Bet (low)','灌水投注 (观察中)','Problems -','問題-')
,(138,'Irrigation Bet (low)','灌水投注 (观察中)','Problems -','問題-')
,(201,'New','新会员','New','新會員')
,(231,'New linked Group','新会员关联群组投注会员','Suspicious','可疑')
,(232,'New linked PA','新会员关联问题会员','Suspicious','可疑')
,(233,'Good linked Robot','新会员关联机械投注会员','Suspicious +','可疑+')
,(234,'New (Lic Sub)','新注册玩家','New','新會員')
,(202,'Normal','普通会员','Healthy','健康')
,(221,'Normal linked Group','普通会员关联群组投注会员','Moderate','中等')
,(222,'Normal linked PA','普通会员关联问题会员','Moderate -','中等-')
,(223,'Normal linked Robot','普通会员关联机械投注会员','Moderate +','中等+')
,(1001,'Normal (inactive)','不活跃正常会员','Healthy','健康')
,(160,'Others','NULL','','')
,(1002,'Smart (inactive)','不活跃精明玩家','Dangerous -','危險-')
,(206,'Probation','观察中玩家','Suspicious','可疑')
,(254,'Prob (Lic Sub)','观察中玩家','Suspicious','可疑')
,(251,'Prob linked Group','观察中玩家关联群组投注会员','Suspicious +','可疑+')
,(252,'Prob linked PA','观察中玩家关联问题会员','Suspicious +','可疑+')
,(253,'Prob linked Robot','观察中玩家关联机械投注会员','Suspicious +','可疑+')
,(257,'Prob Group Betting','怀疑群组投注观察中玩家','Suspicious -','可疑-')
,(258,'Prob High Rejected','怀疑资讯投注观察中玩家','Suspicious -','可疑-')
,(57,'Robot Betting','机器人投注','Robot','機械')
,(157,'Robot Betting','机器人投注','Robot','機械')
,(61,'Robot User','机械用户','Robot','機械')
,(81,'Robot User','机械用户','Robot','機械')
,(161,'Robot User','机械用户','Robot','機械')
,(203,'Smart','精明玩家','Dangerous','危險')
,(264,'Smart (Lic Sub)','精明玩家','Dangerous','危險')
,(261,'Smart linked Group','精明玩家关联群组投注会员','Dangerous +','危險+')
,(262,'Smart linked PA','精明玩家关联问题会员','Dangerous +','危險+')
,(263,'Smart linked Robot','精明玩家关联机械投注会员','Dangerous +','危險+')
,(267,'Smart Group Betting','怀疑群组投注精明玩家','Dangerous -','危險-')
,(268,'Smart High Rejected','怀疑资讯投注精明玩家','Dangerous -','危險-')
,(59,'Formula Bet','系统计算投注','Problems','問題')
,(79,'Formula Bet','系统计算投注','Problems','問題')
,(159,'Formula Bet','系统计算投注','Problems','問題')
,(99,'Formula Bet (low)','机械/系统计算投注 (观察中）','Problems -','問題-')
,(119,'Formula Bet (low)','机械/系统计算投注 (观察中）','Problems -','問題-')
,(139,'Formula Bet (low)','机械/系统计算投注 (观察中）','Problems -','問題-')
,(210,'VVIP (internal)','超级贵宾','Healthy +','健康+');

#========Update CustomerCategory#=========================
UPDATE CustomerCategory AS cc
INNER JOIN Temp_CustomerCategory AS tmp ON cc.CategoryID = tmp.CategoryID AND tmp.CategoryName <> ''
SET 	cc.CategoryName = TRIM(tmp.CategoryName)
	,	cc.CategoryNameCN = TRIM(tmp.CategoryNameCN)
    ,	cc.CustomerClassName = TRIM(tmp.CustomerClassName)
	,	cc.CustomerClassNameCN = TRIM(tmp.CustomerClassNameCN);

/*
#========Update CategoryToCustomerClass#=========================
UPDATE CategoryToCustomerClass AS cc
INNER JOIN Temp_CustomerCategory AS tmp ON cc.CategoryID = tmp.CategoryID AND tmp.CategoryName <> ''
SET 	
    	cc.CustomerClassName = tmp.CustomerClassName
	,	cc.CustomerClassNameCN = tmp.CustomerClassNameCN;
*/