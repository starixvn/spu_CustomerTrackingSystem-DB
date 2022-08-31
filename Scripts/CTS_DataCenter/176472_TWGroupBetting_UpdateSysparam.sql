/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220823@Harvey.Nguyen
Task:	 	Update sysparam [Redmine ID: 170468] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

UPDATE `CTS_DataCenter`.`SystemParameter` SET `ParameterName` = 'TWGroupBetting_LastSequenceId', `ParameterDesc` = 'TWGroupBetting_LastSequenceId', `ParameterValue` = '116007808596' WHERE (`ParameterID` = '90');
