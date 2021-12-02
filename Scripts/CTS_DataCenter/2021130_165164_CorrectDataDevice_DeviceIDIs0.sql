/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20211130@Casey.Huynh
Task:	 	Correct Device Data
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20211130@Casey.Huynh: Created [Redmine ID: #165164]
Reviewer:
*/
USE DCS_DataCenter;

/***ISSUE01: DeviceID = 0 ************************************************
1. STOP SERVICE
2. Deploy SP
2. Run Script
SELECT COUNT(1)
FROM DCS_DataCenter.DeviceFingerprint df
WHERE DeviceID = 0;
*************************************************************************/
DELETE df
FROM DCS_DataCenter.DeviceFingerprint df
WHERE DeviceID = 0;