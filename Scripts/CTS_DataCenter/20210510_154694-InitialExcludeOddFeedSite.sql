/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	202105100@Casey.Huynh
Task:	 	Initial Odd Feed Site [Redmine ID: 154694] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT IGNORE INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,Status,Description,CreatedDate)
VALUES	(11,192,'Exclude Category SiteID','Exclude Category SiteID','NextBet','NextBet',1,'Site is excluded set category',NOW())
	,	(11,283,'Exclude Category SiteID','Exclude Category SiteID','9wickets','9wickets',1,'Site is excluded set category',NOW())
	,	(11,463,'Exclude Category SiteID','Exclude Category SiteID','9wsports','9wsports',1,'Site is excluded set category',NOW());
    
SELECT * FROM MappingSubscriberSite WHERE SiteID IN (192,283,463);
