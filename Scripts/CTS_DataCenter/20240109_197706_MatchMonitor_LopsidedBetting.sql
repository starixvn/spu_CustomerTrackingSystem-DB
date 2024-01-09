/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator:	20221118@Aries.Nguyen
    Task:	 	Match Monitor Irrigation
    Server:  	Master
    DBName:		CTS_DataCenter

    Revisions: 
		    - 20221118@Aries.Nguyen: Init data tbl StaticList [Redmine ID: #179499]
    Reviewer:
*/
USE CTS_DataCenter;

#=====================MM Reason List=====================================
INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,PriorityOrder,Status,CreatedDate)
Values (16,100,'Match Monitor User Comment Reason', 'Reason', 'Lopsided Betting', 'LB','4','1',6,1,NOW());

SELECT * FROM CTS_DataCenter.StaticList WHERE ListID = 16;
#======================User Comment==========================
INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,PriorityOrder,Status,CreatedDate)
VALUES 	(21,1,'Match Monitor User Comment Reason', 'Reason', 'Arbitrage', 'Arbitrage','2','1',1,1,NOW()),
		(21,2,'Match Monitor User Comment Reason', 'Reason', 'Fixed Game', 'Fixed Game','3','1',2,1,NOW()),
        (21,3,'Match Monitor User Comment Reason', 'Reason', 'Formula Bet', 'Formula Bet','59','1',3,1,NOW()),
        (21,4,'Match Monitor User Comment Reason', 'Reason', 'Group Betting', 'Group Betting','0','1',4,1,NOW()),
		(21,5,'Match Monitor User Comment Reason', 'Reason', 'Hedging', 'Hedging','1','1',5,1,NOW()),
		(21,6,'Match Monitor User Comment Reason', 'Reason', 'Info Bet', 'Info Bet','82','1',6,1,NOW()),
		(21,7,'Match Monitor User Comment Reason', 'Reason', 'Irrigation Bet', 'Irrigation Bet','58','1',7,1,NOW()),    
        (21,8,'Match Monitor User Comment Reason', 'Reason', 'Lopsided Betting', 'Lopsided Betting','4','1',8,1,NOW()),
		(21,9,'Match Monitor User Comment Reason', 'Reason', 'Robot User', 'Robot User','163','1',9,1,NOW());

SELECT * FROM CTS_DataCenter.StaticList WHERE ListID = 21;

