/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2"></info>*/
/*
	Creator:	20230821@Jonathan.Doan
	Task:	 	Add field StaticList.GroupID [Redmine ID: #195332]
	Server:  	Master
	DBName:		DCS_Extra
    
	Revisions: 
			- 20230803@Jonathan.Doan: Created [Redmine ID: #191960]
	Reviewer:
*/
USE DCS_Extra;

ALTER TABLE `DCS_Extra`.`StaticList` 
ADD COLUMN `GroupID` SMALLINT NULL;

UPDATE DCS_Extra.StaticList
SET GroupID = 1
WHERE ListID = 1
	AND ItemID = 1;

UPDATE DCS_Extra.StaticList
SET GroupID = 2
WHERE ListID = 1
	AND ItemID BETWEEN 2 AND 8;

UPDATE DCS_Extra.StaticList
SET GroupID = 3
WHERE ListID = 1
	AND ItemID > 8;