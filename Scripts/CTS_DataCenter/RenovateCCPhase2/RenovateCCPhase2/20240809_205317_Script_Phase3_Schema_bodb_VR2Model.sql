/*<info serverAlias="DBVR2-bodb_VR2Model" databaseType="1"></info>*/
/*
Creator:	20240809@Victoria.Le
Task:	 	Remove - Backup and "Not used" columns
Server:  	
DBName:		bodb_VR2Model

Revisions: 
		- 20240809@Victoria.Le: 		Initial Writing - Phase 3: Schema [Redmine ID: #205317]
										1. [Existing] 	CustomerClassification_Rule 
										2. [Existing] 	CustomerClassification_BySport_Rule 
										3. [Existing] 	CustomerClassification 
										4. [Existing] 	CustomerClassification_bysport
*/
USE bodb_VR2Model;

/* 1. [Existing] 	CustomerClassification_Rule   */
	ALTER TABLE CustomerClassification_Rule DROP COLUMN
		CategoryID_new
	,	CurrentCategory_new
	,	CategoryID_bk
	,	CurrentCategory_bk;

/* 2. [Existing] 	CustomerClassification_BySport_Rule   */
	ALTER TABLE CustomerClassification_BySport_Rule DROP COLUMN
		CategoryID_new
	,	CurrentCategory_new
	,	CategoryID_bk
	,	CurrentCategory_bk;

/* 3. [Existing] 	CustomerClassification   */
	ALTER TABLE CustomerClassification DROP COLUMN
		CategoryID_new
	,	CurrentCategoryId_new
	,	CategoryID_bk
	,	CurrentCategoryID_bk;

/* 4. [Existing] 	CustomerClassification_bysport  */
	ALTER TABLE CustomerClassification_bysport DROP COLUMN
		CategoryID_new
	,	CurrentCategoryId_new
	,	CategoryID_bk
	,	CurrentCategoryID_bk;