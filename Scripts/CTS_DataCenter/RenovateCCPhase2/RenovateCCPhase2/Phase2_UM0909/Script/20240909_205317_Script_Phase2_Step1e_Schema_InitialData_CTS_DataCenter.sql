/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20240829@Victoria.Le
	Task :	Initial Data
	DB:			
	
	Description: 

	Revisions:	
		- 20240829@Victoria.Le: 	Initial Writing [Redmine ID: #205317]
									Tables:
										1. CTSCustomerClassification
										2. CTSCustomerClassification_BySport
										3. CTSCustomerClassification_History
										4. CTSCustomerClassification_BySport_History
										5. ArchiveCustomer_CTSCustomer

		
	Param's Explanation (filtered by):

	Example:
*/

USE CTS_DataCenter;

---------------------------------
/*1. CTSCustomerClassification*/
---------------------------------
/* STEP 3.1.5 */

	---------------------------------
	/*Initialize and Backup - Probation - FIRST*/
	/* STEP 3.1.5.a */
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Probation
	FROM SystemParameter
	WHERE ParameterID = 992;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation(@lv_Batchsize_Init_Probation,200,206,402076,140714);
	
	---------------------------------
	/*Initialize and Backup - Other*/
	/* STEP 3.1.5.b */
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Other
	FROM SystemParameter
	WHERE ParameterID = 991;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,206,402076,140714);

	---------------------------------
	/*Update new data*/
	/* STEP 3.1.5.c */
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Update
	FROM SystemParameter
	WHERE ParameterID = 990;
	
	-- PROBATION
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,201,402076,140714);
	
	-- OTHER >> INSERT SOURCE TABLE
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,201,402076,140714);
	
	-- OPTION 1: RENAME AND ONLY UPDATE CreatedDate/LastScannedDate for PROBATION
	ALTER TABLE CTSCustomerClassification
	RENAME COLUMN CategoryID 		TO CategoryID_arc
,	RENAME COLUMN SportGroupID 		TO SportGroupID_arc
,	RENAME COLUMN ParentID_new 		TO ParentID
,	RENAME COLUMN CategoryID_new  	TO CategoryID
,	RENAME COLUMN IsDirect 			TO IsMarkedDirectly;

	ALTER TABLE CTSCustomerClassification DROP PRIMARY KEY,
	ADD PRIMARY KEY (CustID,ParentID,CategoryID);
	
	ALTER TABLE CTSCustomerClassification 
	DROP INDEX IX_CTSCustomerClassification_CustSportGroup
,	DROP INDEX IX_CTSCustomerClassification_SubscriberID_SportGroupID
,	DROP INDEX IX_CTSCustomerClassification_SportGroupID_CreatedDate
,	DROP INDEX IX_CTSCustomerClassification_CategoryID_CustID
	;
	
	ALTER TABLE CTSCustomerClassification 
	MODIFY COLUMN SportGroupID_arc INT DEFAULT NULL
,	MODIFY COLUMN CategoryID_arc INT DEFAULT NULL
;
	
	ALTER TABLE CTSCustomerClassification 
	ADD INDEX IX_CTSCC_CTSCustID_ParentID_LastModifiedDate (CTSCustID,ParentID,LastModifiedDate)
,	ADD INDEX IX_CTSCC_SubscriberID_ParentID (SubscriberID,ParentID)
,	ADD INDEX IX_CTSCC_ParentID_CreatedDate (ParentID,CreatedDate)
,	ADD INDEX IX_CTSCC_CategoryID_CustID_LastScannedDate (CategoryID,CustID,LastScannedDate)
	;
	
	/*
	-- OPTION 2: UPDATE COLUMNS suffix _new >> existing
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,201,402076,140714);
	*/

---------------------------------
/*3. CTSCustomerClassification_History*/
---------------------------------
/* STEP 3.1.6 */

	---------------------------------
	/*Initialize and Backup*/
	/* STEP 3.1.6.a */
	---------------------------------
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CC_History_Init(@op_History_General_NextID);

	---------------------------------
	/*Rename columns*/
	/* STEP 3.1.6.b */
	---------------------------------
	ALTER TABLE CTSCustomerClassification_History
	RENAME COLUMN CategoryID 		TO CategoryID_arc
,	RENAME COLUMN SportGroupID 		TO SportGroupID_arc
,	RENAME COLUMN FromCategoryID	TO FromCategoryID_arc
,	RENAME COLUMN ToCategoryID 		TO ToCategoryID_arc
,	RENAME COLUMN ParentID_new 		TO ParentID
,	RENAME COLUMN CategoryID_new  	TO CategoryID
,	RENAME COLUMN OldCategoryID_new	TO OldCategoryID
,	RENAME COLUMN DWCategoryID_new 	TO DWCategoryID
,	RENAME COLUMN IsDirect 			TO IsMarkedDirectly;


	ALTER TABLE CTSCustomerClassification_History 
	DROP INDEX IX_CTSCustomerClassification_History_CustID_Infor
	;
	
	ALTER TABLE CTSCustomerClassification_History 
	ADD INDEX IX_CTSCC_History_CustID_Infor (CustID,ParentID,LastModifiedDate,IsDataChanged)
	;

---------------------------------
/*2. CTSCustomerClassification_BySport*/
---------------------------------
/* STEP 3.1.7 */
	
	---------------------------------
	/*Initialize and Backup - Probation - FIRST*/
	/* STEP 3.1.7.a */
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_BySport_Init_Probation
	FROM SystemParameter
	WHERE ParameterID = 899;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CCMain_BySport_Probation(@lv_Batchsize_BySport_Init_Probation,1,206,402076,140714);
	
	---------------------------------
	/*Initialize and Backup - Other*/
	/* STEP 3.1.7.b */
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_BySport_Init_Other
	FROM SystemParameter
	WHERE ParameterID = 898;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CCMain_BySport_Other(@lv_Batchsize_BySport_Init_Other,1,201,402076,140714);

	---------------------------------
	/*Update new data*/
	/* STEP 3.1.7.c */
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_BySport_Init_Update
	FROM SystemParameter
	WHERE ParameterID = 897;
	
	-- OPTION 1: RENAME AND ONLY UPDATE CreatedDate/LastScannedDate for PROBATION
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CCMain_BySport_Update(@lv_Batchsize_BySport_Init_Update,200,201,402076,140714);
	
	ALTER TABLE CTSCustomerClassification_BySport
	RENAME COLUMN CategoryID 		TO CategoryID_arc
,	RENAME COLUMN CategoryID_new  	TO CategoryID;

	ALTER TABLE CTSCustomerClassification_BySport DROP PRIMARY KEY,
	ADD PRIMARY KEY (CustID,SportID,ParentID,CategoryID);
	
	ALTER TABLE CTSCustomerClassification_BySport 
	DROP INDEX IX_CTSCustomerClassification_BySport_CategoryID_CustID
	;
	
	ALTER TABLE CTSCustomerClassification_BySport 
	MODIFY COLUMN CategoryID_arc INT DEFAULT NULL
	;
	
	ALTER TABLE CTSCustomerClassification_BySport 
	ADD INDEX IX_CTSCC_BySport_CategoryID_CustID_LastScannedDate (CategoryID,CustID,LastScannedDate)
	;
	
	/*
	-- OPTION 2: UPDATE COLUMNS suffix _new >> existing
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_BySport_Update(@lv_Batchsize_BySport_Init_Update,200,201,402076,140714);
	*/


---------------------------------
/*4. CTSCustomerClassification_BySport_History*/
---------------------------------
/* STEP 3.1.8 */

	---------------------------------
	/*Initialize and Backup*/
	/* STEP 3.1.8.a */
	---------------------------------
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CC_BySport_History_Init(@op_History_BySport_NextID);

	---------------------------------
	/*Rename columns*/
	/* STEP 3.1.8.b */
	---------------------------------
	ALTER TABLE CTSCustomerClassification_BySport_History
	RENAME COLUMN CategoryID 		TO CategoryID_arc
,	RENAME COLUMN CategoryID_new  	TO CategoryID;

---------------------------------
/*5. ArchiveCustomer_CTSCustomer*/
/* STEP 3.1.9 */
---------------------------------
	---------------------------------
	/*Initialize and Backup*/
	/* STEP 3.1.9.a */
	---------------------------------
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_ArchiveCustomer_Init(@op_ArchiveCustomer_NextID);

	---------------------------------
	/*Rename columns*/
	/* STEP 3.1.9.b */
	---------------------------------
	ALTER TABLE ArchiveCustomer_CTSCustomer
	RENAME COLUMN CategoryID 		TO CategoryID_arc
,	RENAME COLUMN CategoryID_new  	TO CategoryID;

