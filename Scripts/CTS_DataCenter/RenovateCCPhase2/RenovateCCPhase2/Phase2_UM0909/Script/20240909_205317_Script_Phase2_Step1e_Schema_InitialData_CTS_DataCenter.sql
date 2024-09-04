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
	---------------------------------
	/*Initialize and Backup - Probation - FIRST*/
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Probation
	FROM SystemParameter
	WHERE ParameterID = 992;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation(@lv_Batchsize_Init_Probation,200,206,402076,140714);
	
	---------------------------------
	/*Initialize and Backup - Other*/
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Other
	FROM SystemParameter
	WHERE ParameterID = 991;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,206,402076,140714);

	---------------------------------
	/*Update new data*/
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Update
	FROM SystemParameter
	WHERE ParameterID = 990;
	
	-- OPTION 1: RENAME AND ONLY UPDATE CreatedDate/LastScannedDate for PROBATION
	ALTER TABLE CTSCustomerClassification
	DROP PRIMARY KEY;

	ALTER TABLE CTSCustomerClassification
	RENAME COLUMN CategoryID 		TO CategoryID_arc
,	RENAME COLUMN SportGroupID 		TO SportGroupID_arc
,	RENAME COLUMN ParentID_new 		TO ParentID
,	RENAME COLUMN CategoryID_new  	TO CategoryID
,	RENAME COLUMN IsDirect 			TO IsMarkedDirectly;

	ALTER TABLE CTSCustomerClassification
	ADD PRIMARY KEY (CustID,ParentID,CategoryID);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,201,402076,140714);
	
	-- OPTION 2: UPDATE COLUMNS suffix _new >> existing
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,201,402076,140714);
	

---------------------------------
/*2. CTSCustomerClassification_BySport*/
---------------------------------
	/*Initialize and Backup - Probation - FIRST*/
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_BySport_Init_Probation
	FROM SystemParameter
	WHERE ParameterID = 899;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_BySport_Probation(@lv_Batchsize_BySport_Init_Probation,1,206,402076,140714);
	
	---------------------------------
	/*Initialize and Backup - Other*/
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_BySport_Init_Other
	FROM SystemParameter
	WHERE ParameterID = 898;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_BySport_Other(@lv_Batchsize_BySport_Init_Other,1,201,402076,140714);

	---------------------------------
	/*Update new data*/
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_BySport_Init_Update
	FROM SystemParameter
	WHERE ParameterID = 897;
	
	-- OPTION 1: RENAME AND ONLY UPDATE CreatedDate/LastScannedDate for PROBATION
	ALTER TABLE CTSCustomerClassification_BySport
	DROP PRIMARY KEY;

	ALTER TABLE CTSCustomerClassification_BySport
	RENAME COLUMN CategoryID 		TO CategoryID_arc
,	RENAME COLUMN CategoryID_new  	TO CategoryID;

	ALTER TABLE CTSCustomerClassification_BySport
	ADD PRIMARY KEY (CustID,SportID,ParentID,CategoryID);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_BySport_Update(@lv_Batchsize_BySport_Init_Update,200,201,402076,140714);
	
	-- OPTION 2: UPDATE COLUMNS suffix _new >> existing
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_BySport_Update(@lv_Batchsize_BySport_Init_Update,200,201,402076,140714);
	
---------------------------------
/*3. CTSCustomerClassification_History*/
---------------------------------
	---------------------------------
	/*Initialize and Backup*/
	---------------------------------
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CC_History_Init(@op_History_General_NextID);

	---------------------------------
	/*Rename columns*/
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

---------------------------------
/*4. CTSCustomerClassification_BySport_History*/
---------------------------------
	---------------------------------
	/*Initialize and Backup*/
	---------------------------------
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CC_BySport_History_Init(@op_History_BySport_NextID);

	---------------------------------
	/*Rename columns*/
	---------------------------------
	ALTER TABLE CTSCustomerClassification_BySport_History
	RENAME COLUMN CategoryID 		TO CategoryID_arc
,	RENAME COLUMN CategoryID_new  	TO CategoryID;

---------------------------------
/*5. ArchiveCustomer_CTSCustomer*/
---------------------------------
	---------------------------------
	/*Initialize and Backup*/
	---------------------------------
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_ArchiveCustomer_Init(@op_ArchiveCustomer_NextID);

	---------------------------------
	/*Rename columns*/
	---------------------------------
	ALTER TABLE ArchiveCustomer_CTSCustomer
	RENAME COLUMN CategoryID 		TO CategoryID_arc
,	RENAME COLUMN CategoryID_new  	TO CategoryID;

