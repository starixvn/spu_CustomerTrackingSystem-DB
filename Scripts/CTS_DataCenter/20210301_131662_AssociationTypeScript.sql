/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210322@CaseyHuynh
Task:	 	Init New Association 'IP' [Redmine ID: 131662] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

DROP PROCEDURE `CTS_DC_Association_Profile_GetStat`;

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES(2,4,'Association Type','Association Type','IP','IP',4,1,'IP Association Type',NOW());
    


