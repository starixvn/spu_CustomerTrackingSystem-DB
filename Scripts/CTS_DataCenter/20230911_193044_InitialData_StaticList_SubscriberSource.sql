/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20230911@Victoria.Le
Task:	 	ManageSubscriber SubscriberSource
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230911@Victoria.Le: Initial Writing [Redmine ID: #193044]          

*/

USE CTS_DataCenter;

SET @CreatedDate := NOW();

INSERT INTO StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,Description,CreatedDate)
VALUES 
	(19,0,'Subscriber Source Name','Subscriber Source Name','Others','Others',NULL,NULL,NULL,1,1,'ManageSubscriber',@CreatedDate)
, 	(19,1,'Subscriber Source Name','Subscriber Source Name','Direct API','Direct API',NULL,NULL,NULL,1,1,'ManageSubscriber',@CreatedDate)
, 	(19,2,'Subscriber Source Name','Subscriber Source Name','Oddsfeed','Oddsfeed',NULL,NULL,NULL,1,1,'ManageSubscriber',@CreatedDate)
;


