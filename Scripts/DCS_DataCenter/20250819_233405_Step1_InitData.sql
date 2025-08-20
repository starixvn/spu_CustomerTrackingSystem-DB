/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250806@Jonathan.Doan [Redmine ID: #233405]
	Task: Change device rule 
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

INSERT IGNORE INTO DCS_DataCenter.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
VALUES 	(4, 'DCS_MBDevice_Transform', 'MaxMBTransaction07IDCompleted', 0, NOW())
	,	(1002, 'AdhocInitialMBData', 'LastMBProcessedTransaction_bkID', 0, NOW());

UPDATE DCS_DataCenter.SystemSetting
SET VValue = 0,
    VName = 'MBTransaction07.TransID'
WHERE ID = 102;

UPDATE DCS_DataCenter.SystemSetting
SET VValue = 0
WHERE ID = 30;

UPDATE DCS_DataCenter.StaticList
SET 	ItemCode = 'MBDeviceCodeMachineAccount' 
	,	ItemName = 'Recover By MBDeviceCodeMachineAccount'
WHERE ListID = 7
	AND ItemID = 2;

UPDATE DCS_DataCenter.StaticList 
SET 	ItemCode = 'MBDeviceCodeMachineMedia' 
	,	ItemName = 'Recover By MBDeviceCodeMachineMedia'
WHERE ListID = 7
	AND ItemID = 3;
    
UPDATE DCS_DataCenter.StaticList 
SET 	ItemCode = 'RecoverByMBDeviceCodeTagging'
	,	ItemName = 'Recover By MBDeviceCodeTagging'
WHERE ListID = 7
	AND ItemID = 1;