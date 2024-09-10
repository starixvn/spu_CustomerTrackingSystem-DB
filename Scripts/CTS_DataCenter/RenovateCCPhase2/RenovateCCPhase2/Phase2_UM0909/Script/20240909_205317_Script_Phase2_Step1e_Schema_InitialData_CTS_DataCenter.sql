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
	UPDATE SystemParameter
	SET ParameterValue = 5000
	WHERE ParameterID = 992;
	
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Probation
	FROM SystemParameter
	WHERE ParameterID = 992;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation(@lv_Batchsize_Init_Probation,200,206,402076,81674);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation(@lv_Batchsize_Init_Probation,200,251,24685093,5087);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation(@lv_Batchsize_Init_Probation,200,252,10391941,5257);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation(@lv_Batchsize_Init_Probation,200,253,47899769,5102);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation(@lv_Batchsize_Init_Probation,200,257,16714629,10322);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Probation(@lv_Batchsize_Init_Probation,200,258,29098350,5105);

	---------------------------------
	/*Initialize and Backup - Other*/
	/* STEP 3.1.5.b */
	---------------------------------
	UPDATE SystemParameter
	SET ParameterValue = 5000
	WHERE ParameterID = 991;
	
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Other
	FROM SystemParameter
	WHERE ParameterID = 991;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,52,40020714,11218);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,53,146112864,5003);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,54,153270837,5041);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,55,15500461,6278);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,59,96528816,5460);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,63,38434923,6846);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,64,109227130,6146);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,92,16212735,5736);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,93,103527567,5001);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,94,155906278,5003);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,95,49515093,5260);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,98,160039466,5001);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,99,85856456,5120);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,103,14552348,5111);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,104,109610285,5012);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,163,4236991,10513);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,164,818791,6297);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,0,165,94237367,5019);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,100,4,17801735,5594);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,100,3,24810178,5414);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,100,2,161257971,5004);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,150,105,97034009,5281);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,150,65,97757889,21924);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,150,107,122621879,5010);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,150,106,100406543,5060);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,150,66,60098850,9477);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,150,67,100577770,6190);
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,271,48296782,5002);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,267,97467001,5004);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,262,104934592,5005);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,211,13773331,5009);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,213,64614808,5050);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,277,45878174,5050);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,273,22864384,5064);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,212,6390066,5066);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,221,22470879,5076);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,221,22470879,5076);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,231,40136892,5090);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,272,78992405,5162);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,233,4381434,5163);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,203,15178022,5218);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,232,21593964,5283);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,223,4830508,5338);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,223,4830508,5338);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,222,19139016,5541);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,222,19139016,5541);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,204,87903,8617);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,205,1607482,13238);

	UPDATE SystemParameter
	SET ParameterValue = 10000
	WHERE ParameterID = 991;
	
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Other
	FROM SystemParameter
	WHERE ParameterID = 991;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,1002,4792566,44282);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,202,1110739,130058);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,202,1110739,130058);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Other(@lv_Batchsize_Init_Other,200,201,2008294,6084541);

	---------------------------------
	/*Update new data*/
	/* STEP 3.1.5.c */
	---------------------------------
	UPDATE SystemParameter
	SET ParameterValue = 5000
	WHERE ParameterID = 990;
	
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Update
	FROM SystemParameter
	WHERE ParameterID = 990;
	
	-- PROBATION
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,206,402076,81674);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,251,24685093,5087);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,252,10391941,5257);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,253,47899769,5102);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,257,16714629,10322);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,200,258,29098350,5105);
	
	-- Batchsize
	UPDATE SystemParameter
	SET ParameterValue = 5000
	WHERE ParameterID = 990;
	
	-- CTS_DC_CC_History_RobotTW_MinID
	UPDATE SystemParameter
	SET ParameterValue = 246518005
	WHERE ParameterID = 890;
	
	-- CTS_DC_CC_History_RobotTW_MaxID
	UPDATE SystemParameter
	SET ParameterValue = 1098915526
	WHERE ParameterID = 889;
	
	-- CTS_DC_CC_History_RobotCTS_MinID
	UPDATE SystemParameter
	SET ParameterValue = 248195688
	WHERE ParameterID = 888;
	
	-- CTS_DC_CC_History_RobotCTS_MaxID
	UPDATE SystemParameter
	SET ParameterValue = 1086227015
	WHERE ParameterID = 887;
	
	-- OTHER >> INSERT SOURCE TABLE
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,163,115770,79855);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,164,44424,33091);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,52,894437,89876);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,53,10672823,11715);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,54,2268412,11376);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,55,623436,63209);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,58,11646775,10206);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,59,1424466,21358);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,92,937400,27020);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,93,964209,10785);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,94,1018105,10295);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,95,61146,19014);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,98,8524996,10119);
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(@lv_Batchsize_Init_Update,0,99,4873246,13124);
	
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
	-- CTS_DC_CC_History_Init_Batchsize
	UPDATE SystemParameter
	SET ParameterValue = 10000
	WHERE ParameterID = 896;
	
	SELECT ParameterValue
	INTO @lv_InitForCCHistory_General
	FROM SystemParameter
	WHERE ParameterID = 779;
	
	-- CTS_DC_CC_History_Init_HistoryID
	UPDATE SystemParameter
	SET ParameterValue = @lv_InitForCCHistory_General
	WHERE ParameterID = 895;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CC_History_Init(@op_History_General_NextID_0);
	-- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CC_History_Init(@op_History_General_NextID_1);
	-- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CC_History_Init(@op_History_General_NextID_2);
	-- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CC_History_Init(@op_History_General_NextID_3);
	-- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CC_History_Init(@op_History_General_NextID_4);
	-- CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CC_History_Init(@op_History_General_NextID_5);

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

