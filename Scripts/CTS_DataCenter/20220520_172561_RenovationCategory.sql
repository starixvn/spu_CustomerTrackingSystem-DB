/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220520@Casey.Huynh
    Task:	 	20220520@Casey.Huynh: Missing ArchiveCust  [Redmine ID: #172561]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

SELECT * FROM CTS_DataCenter.StaticList WHERE ListID = 4 ORDER BY ItemID DESC;

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (4,31,'Classification Source Type','Classification Source Type','Problem Account is marked directly','Problem Account is marked directly',31,1,'Problem Account is marked directly',NOW())
	, (4,32,'Classification Source Type','Classification Source Type','Problem Account is affected by Uplines','Problem Account is affected by Uplines',32,1,'Problem Account is affected by Uplines',NOW())
    , (4,33,'Classification Source Type','Classification Source Type','Problem Account is unmarked directly','Problem Account is unmarked directly',33,1,'Problem Account is unmarked directly',NOW())
    , (4,34,'Classification Source Type','Classification Source Type','Unmarking Problem Account is affected by Uplines','Unmarking Problem Account is affected by Uplines',34,1,'Unmarking Problem Account is affected by Uplines',NOW());