/*<info serverAlias="DBVR2-bodb_VR2Model" databaseType="1"></info>*/
/*
Creator:	20240809@Victoria.Le
Task:	 	Add/Edit Schema
Server:  	
DBName:		bodb_VR2Model

Revisions: 
		- 20240809@Victoria.Le: 		Initial Writing - Phase 1-a: Schema [Redmine ID: #205317]
										I. Create table:
										II. Alter table:
											1. [Existing] 	CustomerClassification_Rule 
											2. [Existing] 	CustomerClassification_BySport_Rule 
											3. [Existing] 	CustomerClassification 
											4. [Existing] 	CustomerClassification_bysport
*/

USE bodb_VR2Model;
/************************* I. Create table ******************************/

/************************* II. Alter table ******************************/
/* 1. [Existing] 	CustomerClassification_Rule  */
	ALTER TABLE CustomerClassification_Rule ADD 
		CategoryID_new					INT	
	,	CurrentCategory_new				INT	
	,	CategoryID_bk					INT	
	,	CurrentCategory_bk				INT	;

	ALTER TABLE CustomerClassification_Rule ALTER COLUMN CategoryId INT;
	DROP INDEX [CIX_CustomerClassification_Rule_CurrentCategory_RuleGroupId] ON [dbo].[CustomerClassification_Rule];
	 
	ALTER TABLE CustomerClassification_Rule ALTER COLUMN CurrentCategory INT;
	 
	CREATE NONCLUSTERED INDEX [IX_CCRule_CurrentCategory_RuleGroupId] ON [dbo].[CustomerClassification_Rule]
	(
		CurrentCategory,
		RuleGroupId
	);

/* 2. [Existing] 	CustomerClassification_BySport_Rule  */
	ALTER TABLE CustomerClassification_BySport_Rule ADD 
		CategoryID_new					INT	
	,	CurrentCategory_new				INT	
	,	CategoryID_bk					INT	
	,	CurrentCategory_bk				INT	;

	ALTER TABLE CustomerClassification_BySport_Rule ALTER COLUMN CategoryId INT;
	
	DROP INDEX [IX_CustomerClassification_BySport_Rule_SportId_RuleGroupId_CurrentCategory] ON [dbo].[CustomerClassification_BySport_Rule];

	ALTER TABLE CustomerClassification_BySport_Rule ALTER COLUMN CurrentCategory INT;

	CREATE NONCLUSTERED INDEX [CIX_CCBySportRule_CurrentCategory_RuleGroupId] ON [dbo].[CustomerClassification_BySport_Rule]
	(
		SportId,
		RuleGroupId,
		CurrentCategory
	);

/* 3. [Existing] 	CustomerClassification  */
	ALTER TABLE CustomerClassification ADD 
		CategoryID_new					INT	
	,	CurrentCategoryId_new			INT	
	,	CategoryID_bk					INT	
	,	CurrentCategoryID_bk			INT	;

	ALTER TABLE CustomerClassification ALTER COLUMN CategoryId INT;
	ALTER TABLE CustomerClassification ALTER COLUMN CurrentCategoryId INT;

/* 4. [Existing] 	CustomerClassification_bysport */
	ALTER TABLE CustomerClassification_bysport ADD 
		CategoryID_new					INT	
	,	CurrentCategoryId_new			INT	
	,	CategoryID_bk					INT	
	,	CurrentCategoryID_bk			INT	;

	ALTER TABLE CustomerClassification_bysport ALTER COLUMN CategoryId INT;
	ALTER TABLE CustomerClassification_bysport ALTER COLUMN CurrentCategoryId INT;
