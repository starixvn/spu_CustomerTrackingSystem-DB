/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210105@Aries.Nguyen
	Task: 	 Add association type Betting Pattern [Redmine ID: #149940]
	DB: 	 CTS_DataCenter
*/

USE CTS_DataCenter;
UPDATE CTS_DataCenter.StaticList SET ItemName = 'Betting Pattern', ItemNameDisplay = 'Betting Pattern' WHERE ListID = 2 AND ItemID = 2;
