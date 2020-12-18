/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20201216@Long.Luu
Task:	 	Schema for new request
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
	-	[20201216@Long.Luu][147210]: Get all categories of Customer Class
Reviewer:
*/

UPDATE CTS_DataCenter.CustomerCategory
SET CategoryGroup = CategoryID
WHERE CategoryID > 50 AND CategoryID NOT IN (160,200);

UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 51 WHERE CategoryID IN (71,151);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 52 WHERE CategoryID IN (72,152);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 53 WHERE CategoryID IN (73,153);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 54 WHERE CategoryID IN (74,154);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 55 WHERE CategoryID IN (75,155);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 56 WHERE CategoryID IN (76,156);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 57 WHERE CategoryID IN (77,157);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 58 WHERE CategoryID IN (78,158);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 59 WHERE CategoryID IN (79,159);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryGroup = 60 WHERE CategoryID IN (80);

UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = NULL WHERE CategoryID IN (51,71,151);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "群组投注" WHERE CategoryID IN (52,72,152);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "出货群组" WHERE CategoryID IN (53,73,153);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "打水套利" WHERE CategoryID IN (54,74,154);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "内定赛事" WHERE CategoryID IN (55,75,155);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = NULL WHERE CategoryID IN (56,76,156);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "机器人投注" WHERE CategoryID IN (57,77,157);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "灌水投注" WHERE CategoryID IN (58,78,158);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "系统计算投注" WHERE CategoryID IN (59,79,159);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = NULL WHERE CategoryID IN (60,80);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "新注册玩家" WHERE CategoryID IN (201);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "正常玩家" WHERE CategoryID IN (202);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "高风险玩家" WHERE CategoryID IN (203);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "精明玩家" WHERE CategoryID IN (204);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "VIP" WHERE CategoryID IN (205);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "观察中玩家" WHERE CategoryID IN (206);
UPDATE CTS_DataCenter.CustomerCategory SET CategoryNameCN = "VVIP" WHERE CategoryID IN (213);
