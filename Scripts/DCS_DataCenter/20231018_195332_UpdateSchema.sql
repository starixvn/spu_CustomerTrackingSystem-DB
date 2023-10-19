/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230927@Jonathan.Doan
	Task:	 	Correct BotD for TV&Console, NotificationPermissions Rule, IOS ver 10/11/12 [Redmine ID: #194559]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20230927@Jonathan.Doan: Created [Redmine ID: #194559]
	Reviewer:
*/
USE DCS_DataCenter;

ALTER TABLE `DCS_DataCenter`.`StaticList` 
ADD COLUMN `GroupItem` SMALLINT NULL;

UPDATE DCS_DataCenter.StaticList
SET GroupItem = 1
WHERE ListID = 1
	AND ItemID = 1;

UPDATE DCS_DataCenter.StaticList
SET GroupItem = 2
WHERE ListID = 1
	AND ItemID BETWEEN 2 AND 8;

UPDATE DCS_DataCenter.StaticList
SET GroupItem = 3
WHERE ListID = 1
	AND ItemID > 8;