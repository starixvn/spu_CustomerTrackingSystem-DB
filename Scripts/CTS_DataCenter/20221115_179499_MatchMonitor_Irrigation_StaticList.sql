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
ALTER TABLE CTS_DataCenter.StaticList ADD ItemValue VARCHAR(50) AFTER ItemNameDisplay;
ALTER TABLE CTS_DataCenter.StaticList ADD ItemDefaultValue VARCHAR(50) AFTER ItemValue;
ALTER TABLE CTS_DataCenter.StaticList ADD ItemParentItemID INT AFTER ItemDefaultValue;

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,PriorityOrder,Status,CreatedDate)
VALUES (16,1,'Match Monitor Reason', 'Reason', 'Group Betting', 'Group Betting','0','1',1,1,NOW()),
	   (16,2,'Match Monitor Reason', 'Reason', 'Hedging', 'Hedging','1','1',2,1,NOW()),
       (16,3,'Match Monitor Reason', 'Reason', 'Arbitrage', 'Arbitrage','2','1',3,1,NOW()),
       (16,4,'Match Monitor Reason', 'Reason', 'Fixed Game', 'Fixed Game','3','1',4,1,NOW()),
       (16,5,'Match Monitor Reason', 'Reason', 'Irrigation', 'Irrigation ','58','1',4,1,NOW());

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,PriorityOrder,Status,CreatedDate)
VALUES (17,1,'Match Monitor Sport', 'Sport', 'Soccer', 'Soccer','1','1',1,1,NOW()),
	   (17,2,'Match Monitor Sport', 'Sport', 'Basketball', 'Basketball','2','0',2,1,NOW()),
       (17,3,'Match Monitor Sport', 'Sport', 'E-Sports', 'E-Sports','43','0',3,1,NOW());

INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,ItemValue,ItemDefaultValue,ItemParentItemID,PriorityOrder,Status,CreatedDate)
VALUES (18,1,'Match Monitor BetType', 'BetType', 'HDP', 'HDP','{"BetTypeID":1, "BetID":0}','1',1,1,1,NOW()),
	   (18,2,'Match Monitor BetType', 'BetType', 'O/U', 'O/U','{"BetTypeID":3, "BetID":0}','1',1,2,1,NOW()),
	   (18,3,'Match Monitor BetType', 'BetType', '1st HDP', '1st HDP','{"BetTypeID":7, "BetID":0}','1',1,3,1,NOW()),
       (18,4,'Match Monitor BetType', 'BetType', '1st O/U', '1st O/U','{"BetTypeID":8, "BetID":0}','1',1,4,1,NOW()),
       
       
       (18,5,'Match Monitor BetType', 'BetType', 'HDP', 'HDP','{"BetTypeID":1, "BetID":0}','0',2,5,1,NOW()),
	   (18,6,'Match Monitor BetType', 'BetType', 'O/U', 'O/U','{"BetTypeID":3, "BetID":0}','0',2,6,1,NOW()),
	   (18,7,'Match Monitor BetType', 'BetType', '1st HDP', '1st HDP','{"BetTypeID":7, "BetID":0}','0',2,7,1,NOW()),
       (18,8,'Match Monitor BetType', 'BetType', '1st O/U', '1st O/U','{"BetTypeID":8, "BetID":0}','0',2,8,1,NOW()),
       
	   (18,9,'Match Monitor BetType', 'BetType', 'Moneyline', 'Moneyline','{"BetTypeID":20, "BetID":0}','0',2,9,1,NOW()),
       
       (18,10,'Match Monitor BetType', 'BetType', 'Quarter 1 HDP', 'Quarter 1 HDP','{"BetTypeID":609, "BetID":801}','0',2,10,1,NOW()),
       (18,11,'Match Monitor BetType', 'BetType', 'Quarter 2 HDP', 'Quarter 2 HDP','{"BetTypeID":609, "BetID":802}','0',2,11,1,NOW()),
	   (18,12,'Match Monitor BetType', 'BetType', 'Quarter 3 HDP', 'Quarter 3 HDP','{"BetTypeID":609, "BetID":803}','0',2,12,1,NOW()),
       (18,13,'Match Monitor BetType', 'BetType', 'Quarter 4 HDP', 'Quarter 4 HDP','{"BetTypeID":609, "BetID":804}','0',2,13,1,NOW()),
       
       (18,14,'Match Monitor BetType', 'BetType', 'Quarter 1 O/U', 'Quarter 1 O/U','{"BetTypeID":610, "BetID":801}','0',2,14,1,NOW()),
       (18,15,'Match Monitor BetType', 'BetType', 'Quarter 2 O/U', 'Quarter 2 O/U','{"BetTypeID":610, "BetID":802}','0',2,15,1,NOW()),
	   (18,16,'Match Monitor BetType', 'BetType', 'Quarter 3 O/U', 'Quarter 3 O/U','{"BetTypeID":610, "BetID":803}','0',2,16,1,NOW()),
       (18,17,'Match Monitor BetType', 'BetType', 'Quarter 4 O/U', 'Quarter 4 O/U','{"BetTypeID":610, "BetID":804}','0',2,17,1,NOW()),
       
       (18,18,'Match Monitor BetType', 'BetType', 'Quarter 1 Moneyline', 'Quarter 1 HDP','{"BetTypeID":612, "BetID":801}','0',2,18,1,NOW()),
       (18,19,'Match Monitor BetType', 'BetType', 'Quarter 2 Moneyline', 'Quarter 2 HDP','{"BetTypeID":612, "BetID":802}','0',2,19,1,NOW()),
	   (18,20,'Match Monitor BetType', 'BetType', 'Quarter 3 Moneyline', 'Quarter 3 HDP','{"BetTypeID":612, "BetID":803}','0',2,20,1,NOW()),
       (18,21,'Match Monitor BetType', 'BetType', 'Quarter 4 Moneyline', 'Quarter 4 HDP','{"BetTypeID":612, "BetID":804}','0',2,21,1,NOW()),
       
       (18,22,'Match Monitor BetType', 'BetType', 'HDP', 'HDP','{"BetTypeID":1, "BetID":0}','0',43,22,1,NOW()),
	   (18,23,'Match Monitor BetType', 'BetType', 'O/U', 'O/U','{"BetTypeID":3, "BetID":0}','0',43,23,1,NOW()),
       (18,24,'Match Monitor BetType', 'BetType', 'Moneyline', 'Moneyline','{"BetTypeID":20, "BetID":0}','0',43,24,1,NOW());