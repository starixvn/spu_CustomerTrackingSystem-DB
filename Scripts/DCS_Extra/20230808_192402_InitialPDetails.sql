/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2"></info>*/
/*
Creator:	20230808@Casey.Huynh
Task:	 	Initial IP Details
Server:  	Master
DBName:		DCS_Extra

Revisions: 
		- 20230808@Casey.Huynh: Created [Redmine ID: #192402]
Reviewer:
*/
USE DCS_Extra;
INSERT INTO SystemSetting(ID,VGroup,VName,VValue,UpdatedTime)
VALUE (1001, 'Initial IP Details', 'LastTransID', 0, NOW())
	, (1002, 'Initial IP Details', 'LastCreatedDate', '2023-01-01', NOW());

#Intial SCHEMA TABLES