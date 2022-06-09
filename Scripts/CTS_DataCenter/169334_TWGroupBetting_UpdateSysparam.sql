/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220609@Harvey.Nguyen
Task:	 	Update sysparam [Redmine ID: 170468] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
DELETE FROM `CTS_DataCenter`.`SystemParameter` WHERE (`ParameterID` = '78');
UPDATE `CTS_DataCenter`.`SystemParameter` SET `ParameterValue` = '2022-06-08 00:00:00.000' WHERE (`ParameterID` = '77');