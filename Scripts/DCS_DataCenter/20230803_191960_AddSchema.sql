/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230803@Jonathan.Doan
	Task:	 	Add Column BotComponent.isHuman [Redmine ID: #191960]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20230803@Jonathan.Doan: Created [Redmine ID: #191960]
	Reviewer:
*/
USE DCS_DataCenter;
 
ALTER TABLE `DCS_DataCenter`.`BotComponent` 
ADD COLUMN `IsHuman` TINYINT(1) NULL;
