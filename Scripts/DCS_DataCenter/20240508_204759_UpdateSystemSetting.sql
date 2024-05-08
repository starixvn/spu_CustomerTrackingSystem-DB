/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20240508@Jonathan.Doan
Task:	 	Update SystemSetting to re-run tranform transaction
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240508@Jonathan.Doan: Created [#204759]
Reviewer:
*/

USE DCS_DataCenter;

UPDATE DCS_DataCenter.SystemSetting
SET VValue = '2024-01-01'
WHERE ID = 2;