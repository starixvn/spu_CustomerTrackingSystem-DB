/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230628@Jonathan.Doan
	Task:	 	Correct Data UserAgent [Redmine ID: #190382]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20230628@Jonathan.Doan: Created [Redmine ID: #190382]
	Reviewer:
*/
USE DCS_DataCenter;
 
UPDATE DCS_DataCenter.UserAgent
SET DeviceTypeID = 3
WHERE OSID = 4
	AND BrowserID = 17
	AND DeviceTypeID = 4;
