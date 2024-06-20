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

UPDATE cr WITH(ROWLOCK, UPDLOCK)
SET cr.CategoryID 		= CASE cr.CategoryID 
							WHEN 201 THEN 40100
							WHEN 202 THEN 40300
							WHEN 203 THEN 40500
							WHEN 204 THEN 40600
							WHEN 205 THEN 40200
							WHEN 206 THEN 40400 END
,	cr.CurrentCategory	= CASE cr.CurrentCategory 
							WHEN 201 THEN 40100
							WHEN 202 THEN 40300
							WHEN 203 THEN 40500
							WHEN 204 THEN 40600
							WHEN 205 THEN 40200
							WHEN 206 THEN 40400 
							WHEN 1001 THEN 40700
							WHEN 1002 THEN 40701 END
FROM CustomerClassification_Rule AS cr;

UPDATE cbr WITH(ROWLOCK, UPDLOCK)
SET cbr.CategoryID 		= CASE cbr.CategoryID 
							WHEN 201 THEN 40100
							WHEN 202 THEN 40300
							WHEN 203 THEN 40500
							WHEN 204 THEN 40600
							WHEN 205 THEN 40200
							WHEN 206 THEN 40400 END
,	cbr.CurrentCategory = CASE cbr.CurrentCategory 
							WHEN 201 THEN 40100
							WHEN 202 THEN 40300
							WHEN 203 THEN 40500
							WHEN 204 THEN 40600
							WHEN 205 THEN 40200
							WHEN 206 THEN 40400 END
FROM CustomerClassification_BySport_Rule AS cbr;