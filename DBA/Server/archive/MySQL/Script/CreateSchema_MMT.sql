USE MonDB;
CREATE TABLE `Monitor_MMTMetric` (
   `JobID` bigint unsigned NOT NULL,
   `ServerID` bigint unsigned NOT NULL,
   `Created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
   `ObjectName` varchar(64) NOT NULL,
   `Total` bigint unsigned DEFAULT NULL,
   `IsProcessed` tinyint NOT NULL,
   `MinTransDate` datetime DEFAULT NULL,
   `MaxTransDate` datetime DEFAULT NULL,
   `MinInsertTime` datetime DEFAULT NULL,
   `MaxInsertTime` datetime DEFAULT NULL,
   PRIMARY KEY (`ServerID`,`JobID`,`Created`,`ObjectName`,`IsProcessed`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


 CREATE TABLE `MMTJob` (
   `ID` int unsigned NOT NULL AUTO_INCREMENT,
   `ServerID` int unsigned DEFAULT NULL,
   `DBName` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
   `Name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
   `Query` longtext COLLATE utf8_unicode_ci,
   `IsActive` tinyint DEFAULT '1',
   `Created` datetime DEFAULT CURRENT_TIMESTAMP,
   `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

 /*
 WITH CTE AS
 (
   	SELECT 	MatchID
 		,	TotalScore
 		,	BettypeID
 		,	Betteam
 		,	BetID
 		,	GroupID
 		,	COUNT(1) AS Total
 		,	MIN(TransDate) AS MinTransDate
 		,	MAX(TransDate) AS MaxTransDate
         ,	MIN(InsertTime) AS MinInsertTime
         ,	MAX(InsertTime) AS MaxInsertTime
 		,	1 AS IsProcessed
 	FROM CTS_DataCenter.MatchMonitorStagingLive03
 	WHERE SequenceID > (SELECT ParameterValue FROM SystemParameter WHERE ParameterID = 47)
 	GROUP BY MatchID
 		,	 TotalScore
 		,	 BettypeID
 		,	 Betteam
 		,    BetID
         ,	 GroupID
 	UNION ALL 
 	SELECT 	MatchID
 		,	TotalScore
 		,	BettypeID
 		,	Betteam
 		,	BetID
 		,	GroupID
 		,	COUNT(1) AS Total
 		,	MIN(TransDate) AS MinTransDate
 		,	MAX(TransDate) AS MaxTransDate
         ,	MIN(InsertTime) AS MinInsertTime
         ,	MAX(InsertTime) AS MaxInsertTime
 		,	0 AS IsProcessed
 	FROM CTS_DataCenter.MatchMonitorStagingLive03
 	WHERE SequenceID <= (SELECT ParameterValue FROM SystemParameter WHERE ParameterID = 47)
 	GROUP BY MatchID
 		,	 TotalScore
 		,	 BettypeID
 		,	 Betteam
 		,    BetID
         ,	 GroupID
 )
 SELECT JSON_ARRAYAGG(JSON_OBJECT(
 		'ObjectName', CONCAT(MatchID,"*",TotalScore,"*",BettypeID,"*",Betteam,"*",BetID,"*",GroupID,"*") 
 	,	'Total',Total
     ,	'IsProcessed',IsProcessed
     ,	'MinTransDate',MinTransDate
     ,	'MaxTransDate',MaxTransDate
     ,	'MinInsertTime',MinInsertTime
     ,	'MaxInsertTime',MaxInsertTime)) AS Metric
 FROM CTE;

 */