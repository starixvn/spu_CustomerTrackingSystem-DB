/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20241101@Jonathan.Doan [Redmine ID: #212696]
	Task: Log more info for consumer service
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

INSERT INTO `DCS_DataCenter`.`StaticList` (`ListID`, `ItemID`, `ListCode`, `ListName`, `ItemCode`, `ItemName`, `Status`, `CreatedDate`) VALUES ('3', '4', 'DCSConsumer_LogType', 'DCSConsumer_LogType', 'SessionKeyColon', 'SessionKey does not contain a colon', '1', NOW());
INSERT INTO `DCS_DataCenter`.`StaticList` (`ListID`, `ItemID`, `ListCode`, `ListName`, `ItemCode`, `ItemName`, `Status`, `CreatedDate`) VALUES ('3', '5', 'DCSConsumer_LogType', 'DCSConsumer_LogType', 'SessionKeyParse', 'SessionKey cannot be parsed', '1', NOW());
INSERT INTO `DCS_DataCenter`.`StaticList` (`ListID`, `ItemID`, `ListCode`, `ListName`, `ItemCode`, `ItemName`, `Status`, `CreatedDate`) VALUES ('3', '6', 'DCSConsumer_LogType', 'DCSConsumer_LogType', 'TaggingLength', 'Tagging has a length > 32', '1', NOW());

