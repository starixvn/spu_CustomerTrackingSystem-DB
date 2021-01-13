/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20201207@Irena.Vo
	Task: 	 145951-Init data for View History  [Redmine ID: #145951]
	DB: 	 CTS_DataCenter
    
     Revisions: 
	 -	[20201207@Irena.Vo]: Insert data in table: Static List for View History
*/
-- Insert item list for Source Type for category
INSERT INTO CTS_DataCenter.StaticList
(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES
(4,1, 'Classification Source Type','Classification Source Type','Account has less than 10 bets for first time scan','Account has less than 10 bets for first time scan',1,1,'New: New Customer',CURRENT_TIME()),
(4,2, 'Classification Source Type','Classification Source Type','Re-scan after 10 bets','Re-scan after 10 bets',2,1,'Other: From New To Normal,VIP/VIP,Normal,Probation,Smart,High Risk...Probation: From New To Probation,Smart,High Risk',CURRENT_TIME()),
(4,3, 'Classification Source Type','Classification Source Type','Re-scan on Schedule Date','Re-scan on Schedule Date',3,1,'Other: From Normal,VIP To VIP,Normal/ From Probation To Normal,VIP/ From Smart,High Risk To High Risk,Smart...Probation: From Normal,VIP To Probation,Smart,High Risk',CURRENT_TIME()),
(4,4, 'Classification Source Type','Classification Source Type','Pass 20 days Probation','Pass 20 days Probation',4,1,'Other: From Probation To Smart,High Risk',CURRENT_TIME()),
(4,5, 'Classification Source Type','Classification Source Type','Cannot pass Probation','Cannot pass Probation',5,1,'Probation: From Probation To Probation',CURRENT_TIME()),
(4,6, 'Classification Source Type','Classification Source Type','Add from NAP CM manually','Add from NAP CM manually',6,1,'From NapCM',CURRENT_TIME()),
(4,7, 'Classification Source Type','Classification Source Type','Add from Evidence manually','Add from Evidence manually',7,1,'From Evidence',CURRENT_TIME()),
(4,8, 'Classification Source Type','Classification Source Type','Remove from NAP CM manually','Remove Problem Account manually',8,1,'From PA',CURRENT_TIME()),
(4,9, 'Classification Source Type','Classification Source Type','Remove from Evidence manually','Remove Problem Account manually',9,1,'From Evidence',CURRENT_TIME()),
(4,10, 'Classification Source Type','Classification Source Type','Add Customer Class manually','Add Customer Class manually',10,1,'From Special CC',CURRENT_TIME()),
(4,11, 'Classification Source Type','Classification Source Type','Change Customer Class by Robot Icon','Change Customer Class by Robot Icon',11,1,'From Robot',CURRENT_TIME()),
(4,12, 'Classification Source Type','Classification Source Type','Remove Customer Class manually','Remove Customer Class manually',12,1,'From CC',CURRENT_TIME()),
(4,13, 'Classification Source Type','Classification Source Type','Add VVIP manually','Add VVIP manually',13,1,'From VVIP',CURRENT_TIME()),
(4,14, 'Classification Source Type','Classification Source Type','Remove VVIP manually','Remove VVIP manually',14,1,'From VVIP',CURRENT_TIME()),
(4,15, 'Classification Source Type','Classification Source Type','Re-scan from NAP CM by Customer','Re-scan Problem Account by Customer',15,1,'From PA',CURRENT_TIME()),
(4,16, 'Classification Source Type','Classification Source Type','Re-scan from Evidence by Customer','Re-scan Problem Account by Customer',16,1,'From Evidence',CURRENT_TIME()),
(4,17, 'Classification Source Type','Classification Source Type','Re-scan Normal Account by Customer','Re-scan Normal Account by Customer',17,1,'From Normal',CURRENT_TIME());

-- Insert item list for Action Type for category
INSERT INTO CTS_DataCenter.StaticList 
(ListID, ItemID, ListName, ListNameDisplay, ItemName, ItemNameDisplay, PriorityOrder, Status, CreatedDate) 
VALUES 
(5, 0, 'Classification Action Type', 'Classification Action Type', 'Insert New Classification', 'Insert New Classification', 0, 1,CURRENT_TIME()),
(5, 1, 'Classification Action Type', 'Classification Action Type', 'Update Classification', 'Update Classification', 1, 1,CURRENT_TIME()),
(5, 2, 'Classification Action Type', 'Classification Action Type', 'Remove Problem Accounts', 'Remove Problem Accounts', 2, 1,CURRENT_TIME()),
(5, 3, 'Classification Action Type', 'Classification Action Type', 'Ignore Existed Category', 'Ignore Existed Category', 3, 1,CURRENT_TIME()),
(5, 4, 'Classification Action Type', 'Classification Action Type', 'Ignore PIN Category', 'Ignore PIN Category', 4, 1,CURRENT_TIME());

-- Insert item list for Sport Group for category
INSERT INTO CTS_DataCenter.StaticList 
(ListID, ItemID, ListName, ListNameDisplay, ItemName, ItemNameDisplay, PriorityOrder, Status, CreatedDate) 
VALUES 
(6, 0, 'Classification Sport Group', 'Classification Sport Group', 'Problem Account Sport', 'Problem Account Sport', 0, 1,CURRENT_TIME()),
(6, 200, 'Classification Sport Group', 'Classification Sport Group', 'Normal Account Sport', 'Normal Account Sport', 200, 1,CURRENT_TIME());

-- Insert item list for Customer for category
INSERT INTO CTS_DataCenter.StaticList 
(ListID, ItemID, ListName, ListNameDisplay, ItemName, ItemNameDisplay, PriorityOrder, Status, CreatedDate) 
VALUES 
(7, -99, 'Classification Customer', 'Classification Customer', 'For No mapping Customer Class', 'For No mapping Customer Class', -99, 1,CURRENT_TIME()),
(7, -1, 'Classification Customer', 'Classification Customer', 'For Removed Problem Account', 'For Removed Problem Account', -1, 1,CURRENT_TIME());