/*<info serverAlias="DBVR2-bodb_VR2Model" databaseType="1"></info>*/
/*
Creator:	20240619@Thomas.Nguyen
Task:	 	
Server:  	DBVR2
DBName:		bodb_VR2Model

Revisions: 
		- 20240619@Thomas.Nguyen: Created [Redmine ID: #205317]
Reviewer:
*/

USE bodb_VR2Model;

ALTER TABLE CustomerClassification_Rule
ALTER COLUMN CategoryId INT;

ALTER TABLE CustomerClassification_Rule
ALTER COLUMN CurrentCategory INT;

ALTER TABLE CustomerClassification_BySport_Rule
ALTER COLUMN CategoryId INT;

ALTER TABLE CustomerClassification_BySport_Rule
ALTER COLUMN CurrentCategory INT;

