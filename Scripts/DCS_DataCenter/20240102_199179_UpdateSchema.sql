/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20240102@Jonathan.Doan
	Task:	 	Change Headers datatype [Redmine ID: #199179]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20240102@Jonathan.Doan: Created [Redmine ID: #199179]
	Reviewer:
*/
USE DCS_DataCenter;

ALTER TABLE DCS_DataCenter.BrowserInstance
MODIFY COLUMN Headers varchar(700);