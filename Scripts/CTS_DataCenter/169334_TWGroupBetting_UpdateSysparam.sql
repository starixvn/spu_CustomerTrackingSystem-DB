/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220808@Harvey.Nguyen
Task:	 	Update sysparam [Redmine ID: 170468] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

UPDATE `CTS_DataCenter`.`SystemParameter` SET `ParameterDesc` = 'TWGroupBetting_LastScanTransSec', `ParameterDataType` = 'BIGINT', `ParameterValue` = '18835199' WHERE (`ParameterID` = '77');
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('78', 'TWGroupBetting_SkipTransCount', 'TWGroupBetting_SkipTransCount', 'INT', '169');
UPDATE `CTS_DataCenter`.`SystemParameter` SET `ParameterValue` = '115864624909' WHERE (`ParameterID` = '90');
