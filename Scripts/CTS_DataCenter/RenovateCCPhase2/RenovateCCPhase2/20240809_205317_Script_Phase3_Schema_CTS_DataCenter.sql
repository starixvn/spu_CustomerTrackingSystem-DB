/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240809@Victoria.Le
Task:	 	Remove - Backup and "Not used" columns
Server:  	
DBName:		CTS_DataCenter

Revisions: 
		- 20240809@Victoria.Le: 		Initial Writing - Phase 3: Schema [Redmine ID: #205317]
										1. CTSCustomerClassification
										2. CTSCustomerClassification_History
										3. CTSCustomerClassification_Log
										4. CTSCustomerClassificationQueue
										5. CTSCustomerClassification_BySport
										6. CTSCustomerClassification_BySport_History
										7. CTSCustomerClassification_BySport_Log
										8. ArchiveCustomer_CTSCustomer
*/

USE CTS_DataCenter;

/* 1. CTSCustomerClassification    */
	ALTER TABLE CTSCustomerClassification
	DROP COLUMN ParentID_new
,	DROP COLUMN CategoryID_new
,	DROP COLUMN CreatedDate_new
,	DROP COLUMN SportGroupID_bk
,	DROP COLUMN CategoryID_bk
,	DROP COLUMN CreatedDate_bk;

/* 2. CTSCustomerClassification_History   */
	ALTER TABLE CTSCustomerClassification_History
	DROP COLUMN ParentID_new
,	DROP COLUMN CategoryID_new
,	DROP COLUMN OldCategoryID_new
,	DROP COLUMN DWCategoryID_new
,	DROP COLUMN SportGroupID_bk
,	DROP COLUMN CategoryID_bk
,	DROP COLUMN FromCategoryID_bk
,	DROP COLUMN ToCategoryID_bk;

/* 3. CTSCustomerClassification_Log   */
	ALTER TABLE CTSCustomerClassification_Log
	DROP COLUMN ParentID_new
,	DROP COLUMN CategoryID_new
,	DROP COLUMN OldCategoryID_new
,	DROP COLUMN DWCategoryID_new
,	DROP COLUMN SportGroupID_bk
,	DROP COLUMN CategoryID_bk
,	DROP COLUMN FromCategoryID_bk
,	DROP COLUMN ToCategoryID_bk;

/* 4. CTSCustomerClassificationQueue   */
	ALTER TABLE CTSCustomerClassificationQueue
	DROP COLUMN CategoryGroupID_new
,	DROP COLUMN CategoryID_new
,	DROP COLUMN CategoryGroup_bk
,	DROP COLUMN CategoryID_bk;

/* 5. CTSCustomerClassification_BySport   */
	ALTER TABLE CTSCustomerClassification_BySport
	DROP COLUMN CategoryID_new 		
,	DROP COLUMN CreatedDate_new
,	DROP COLUMN CategoryID_bk
,	DROP COLUMN CreatedDate_bk;

/* 6. CTSCustomerClassification_BySport_History   */
	ALTER TABLE CTSCustomerClassification_BySport_History
	DROP COLUMN CategoryID_new 			INT  
,	DROP COLUMN CategoryID_bk 			INT;

/* 7. CTSCustomerClassification_BySport_Log   */
	ALTER TABLE CTSCustomerClassification_BySport_Log
	DROP COLUMN CategoryID_new 			INT  
,	DROP COLUMN CategoryID_bk 			INT;

/* 8. ArchiveCustomer_CTSCustomer   */
	ALTER TABLE ArchiveCustomer_CTSCustomer
	ADD COLUMN CategoryID_new 			INT  
,	ADD COLUMN CategoryID_bk 			INT
;

