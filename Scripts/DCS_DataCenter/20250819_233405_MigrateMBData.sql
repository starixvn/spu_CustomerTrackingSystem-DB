/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250806@Jonathan.Doan [Redmine ID: #233405]
	Task: Migrate MBData
	DB: DCS_DataCenter
*/

USE CTS_Adhoc;

/* Backup DCS_DataCenter.MBProcessedTransaction to CTS_Adhoc.MBProcessedTransaction_bk */
SET sql_safe_updates = 0;
CALL CTS_Adhoc.Adhoc_DCS_DC_Backup_MBProcessedTransaction(10000);

/* TRUNCATE ALL Mobile App data */
TRUNCATE TABLE MBAccount;
TRUNCATE TABLE MBAssociation;
TRUNCATE TABLE MBDevice;
TRUNCATE TABLE MBDeviceCodeMachine;
TRUNCATE TABLE MBDeviceCodeMachineAccount;
TRUNCATE TABLE MBDeviceCodeMachineMedia;
TRUNCATE TABLE MBDeviceCodeMediaDRM;
TRUNCATE TABLE MBDeviceCodeTagging;
TRUNCATE TABLE MBDeviceMapping;
TRUNCATE TABLE MBDeviceModel;
TRUNCATE TABLE MBOS;
TRUNCATE TABLE MBProcessedTransaction;
TRUNCATE TABLE MBRawTransaction;
TRUNCATE TABLE MBRawTransactionIOS;
TRUNCATE TABLE MBTransaction;
TRUNCATE TABLE MBTransaction07;
TRUNCATE TABLE MBUserSetting;

/* Load initial data into MBRawTransaction */
SET sql_safe_updates = 0;
CALL CTS_Adhoc.Adhoc_DCS_DC_Initial_MBRawTransaction(10000);