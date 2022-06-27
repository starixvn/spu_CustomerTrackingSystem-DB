/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220628@Long.Luu
    Task:	 	20220628@Long.Luu: Rename Category  [Redmine ID: #174430]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
CREATE TEMPORARY TABLE Temp_CustomerCategory (
		CategoryID		SMALLINT UNSIGNED PRIMARY KEY
	,	CategoryName	VARCHAR(50)
    ,	CategoryNameCN	VARCHAR(50)
    ,	IsOnlyCN		BIT DEFAULT 0
);

INSERT INTO Temp_CustomerCategory(CategoryID,CategoryName,CategoryNameCN,IsOnlyCN)
VALUES  (257,'','观察中群组投注玩家',1)
	,	(258,'','观察中资讯投注玩家',1)
	,	(267,'','精明群组投注玩家',1)
	,	(268,'','精明资讯投注玩家',1)
	,	(277,'','高危群组投注玩家',1)
	,	(278,'','高危资讯投注玩家',1)
	,	(92,'Group Betting (Losing)','群组投注 (输钱)',0)
	,	(112,'Group Betting (Losing)','群组投注 (输钱)',0)
	,	(132,'Group Betting (Losing)','群组投注 (输钱)',0)
	,	(94,'Arbitrage (Losing)','打水套利 (输钱)',0)
	,	(114,'Arbitrage (Losing)','打水套利 (输钱)',0)
	,	(134,'Arbitrage (Losing)','打水套利 (输钱)',0)
	,	(98,'Irrigation Bet (Losing)','灌水投注 (输钱)',0)
	,	(118,'Irrigation Bet (Losing)','灌水投注 (输钱)',0)
	,	(138,'Irrigation Bet (Losing)','灌水投注 (输钱)',0)
	,	(95,'Fixed Game (Losing)','内定赛事 (输钱)',0)
	,	(115,'Fixed Game (Losing)','内定赛事 (输钱)',0)
	,	(135,'Fixed Game (Losing)','内定赛事 (输钱)',0)
	,	(99,'Formula Bet (Losing)','机械/系统计算投注 (输钱)',0)
	,	(119,'Formula Bet (Losing)','机械/系统计算投注 (输钱)',0)
	,	(139,'Formula Bet (Losing)','机械/系统计算投注 (输钱)',0)
	,	(93,'Hedging (Losing)','出货群组 (输钱)',0)
	,	(113,'Hedging (Losing)','出货群组 (输钱)',0)
	,	(133,'Hedging (Losing)','出货群组 (输钱)',0)
	#,	(,'AB Bet (Losing)','AB投注 (输钱)',0)
	,	(100,'Bonus Hunter (Losing)','赏金猎人 (输钱)',0)
	,	(120,'Bonus Hunter (Losing)','赏金猎人 (输钱)',0)
	,	(102,'Info Bet (Losing)','资讯单投注 (输钱)',0)
	,	(122,'Info Bet (Losing)','资讯单投注 (输钱)',0)
	,	(142,'Info Bet (Losing)','资讯单投注 (输钱)',0);
    
select * from Temp_CustomerCategory;  
  
UPDATE CustomerCategory AS c
	INNER JOIN Temp_CustomerCategory AS t ON c.CategoryID = t.CategoryID
SET 	c.CategoryName = t.CategoryName
	,	c.CategoryNameCN = t.CategoryNameCN
WHERE t.IsOnlyCN = 0;

UPDATE CustomerCategory AS c
	INNER JOIN Temp_CustomerCategory AS t ON c.CategoryID = t.CategoryID
SET 	c.CategoryNameCN = t.CategoryNameCN
WHERE t.IsOnlyCN = 1;

