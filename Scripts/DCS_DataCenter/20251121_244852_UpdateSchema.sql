/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20251121@Jonathan.Doan
Task:	 	Change recover by F4
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20251121@Jonathan.Doan: Created [Redmine ID: #244852]
Reviewer:
*/

USE DCS_DataCenter;

ALTER TABLE `DeviceFPPattern`
	DROP PRIMARY KEY,
	ADD PRIMARY KEY (`FPPatternID`, `DeviceID`),
	DROP INDEX `IX_FPPattern_FPPatternTypeFPPatternID`,
	ADD INDEX `IX_FPPattern_DeviceIDFPPatternID` (`DeviceID`, `FPPatternID`);
