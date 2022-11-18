/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220125@Harvey.Nguyen
Task:	 	Add columns [Redmine ID: 179398] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

ALTER TABLE `CTS_DataCenter`.`AssociatedGroup` 
ADD COLUMN `Danger1` SMALLINT NULL DEFAULT NULL AFTER `ABI`,
ADD COLUMN `PACategoryID` SMALLINT NULL DEFAULT NULL AFTER `ModifiedBy`,
ADD COLUMN `PACreditSites` TEXT NULL DEFAULT NULL AFTER `PACategoryID`,
ADD COLUMN `PALicenseeSites` TEXT NULL DEFAULT NULL AFTER `PACreditSites`

USE CTS_Admin;
ALTER TABLE UserLog
ADD Column EventName
