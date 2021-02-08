/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210204@Long.Luu
Task:	 	Init data for table StaticList [Redmine ID: #148719]
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,`Status`,`Description`,CreatedDate)
VALUES(8,1,'CustEvidenceQueue','CustEvidenceQueue','Insert evidence from file','Insert evidence from file',1,1,'Insert evidence from file',NOW())
,(8,2,'CustEvidenceQueue','CustEvidenceQueue','Override evidence from file','Override evidence from file',2,1,'Override evidence from file',NOW())
,(8,3,'CustEvidenceQueue','CustEvidenceQueue','Clear evidence from web function','Clear evidence from web function',3,1,'Clear evidence from web function',NOW());