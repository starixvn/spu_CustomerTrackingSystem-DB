/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220617@Harvey.Nguyen
Task:	 	Update sysparam [Redmine ID: 170468] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

UPDATE `CTS_DataCenter`.`SystemParameter` SET `ParameterValue` = '2022-06-16 00:00:00.000' WHERE (`ParameterID` = '77');
UPDATE `CTS_DataCenter`.`SystemParameter` SET `ParameterValue` = '0' WHERE (`ParameterID` = '90');