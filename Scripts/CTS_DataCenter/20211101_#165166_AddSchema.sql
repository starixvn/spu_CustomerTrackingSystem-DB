/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20211207@Aries.Nguyen
    Task:	 	Add DCS tables into archive customer process [Redmine ID: #165001]
    DBName:		CTS_DataCenter
*/
USE DCS_DataCenter;
CREATE TABLE `ArchiveCustomer_Device` (
   `AccountID` bigint unsigned,
   `DeviceID` bigint unsigned,
   PRIMARY KEY (`AccountID`, `DeviceID`),
   KEY `IX_ArchiveCustomer_Device_DeviceID` (`DeviceID`)
 ) ENGINE=InnoDB;