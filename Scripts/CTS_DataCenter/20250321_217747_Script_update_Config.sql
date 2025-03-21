/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250318@Logan.Nguyen
Task:	 	script update config
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250318@Logan.Nguyen: Created [Redmine ID: #220539]

Reviewer:
*/

UPDATE CTS_DataCenter.CustomerCategory 
SET IsDangerProbation = 0 
WHERE CategoryID = 40500;
UPDATE CTS_DataCenter.CustomerCategory 
SET IsDangerProbation = 0 
WHERE CategoryID = 40600;
UPDATE CTS_DataCenter.CustomerCategory 
SET IsDangerProbation = 0 
WHERE CategoryID = 40701;
