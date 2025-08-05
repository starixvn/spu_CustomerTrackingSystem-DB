/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250804@Lando.Vu [Redmine ID: #233405]
	Task: Update schema Mobile App for Device Detail
	DB: DCS_DataCenter
*/
USE DCS_DataCenter;

ALTER TABLE DCS_DataCenter.MBRawTransaction
ADD DeviceDetail JSON;

ALTER TABLE DCS_DataCenter.MBProcessedTransaction
ADD DeviceDetail JSON;