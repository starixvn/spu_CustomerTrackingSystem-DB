/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240212@Casey.Huynh	
Task:	 	Hotfix Protential Risk Cannot be Classified to System Detect GB
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240212@Casey.Huynh: Created [Redmine ID: #214567]
Reviewer:
*/

USE CTS_DataCenter;

ALTER TABLE CustomerCategorySettings
ADD COLUMN ExcludedClassifyMM TINYINT DEFAULT 0 COMMENT 'Exclude Classify From MM';

UPDATE CustomerCategorySettings
SET ExcludedClassifyMM = 1
WHERE ParentID = 20000 
	AND CategoryID NOT IN (
		21600,21700,21100,26100,21200,26200,21103 #CONST_CATEID_ROBOTBETTING, CONST_CATEID_ROBOTOLD, CONST_CATEID_ROBOTUSER, CONST_CATEID_ROBOTUSERLOSING, CONST_CATEID_ROBOTOCRD, CONST_CATEID_ROBOTOCRDLOSING, CONST_CATEID_ROBOTUSERABNORMAL
	,	30100,30200,30300,35100,35200,35300	 #PROTENTIAL RISK CATEGORY
        );
