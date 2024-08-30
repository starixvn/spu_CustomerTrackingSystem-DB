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
	/*Rename columns*/
	---------------------------------
	ALTER TABLE CTSCustomerClassification
	RENAME COLUMN SportGroupID TO ParentID
,	RENAME COLUMN IsDirect TO IsMarkedDirectly;

	---------------------------------
	/*Update new data*/
	---------------------------------
	SELECT ParameterValue
	INTO @lv_Batchsize_Init_Other
	FROM SystemParameter
	WHERE ParameterID = 990;
	
	CALL CTS_DataCenter.Adhoc_Renovate_Phase2_CTS_DC_CustClassification_Update(10000,200,201,402076,140714);
	

---------------------------------
/*2. CTSCustomerClassification_BySport*/
---------------------------------


---------------------------------
/*3. CTSCustomerClassification_History*/
---------------------------------



---------------------------------
/*4. CTSCustomerClassification_BySport_History*/
---------------------------------



---------------------------------
/*5. ArchiveCustomer_CTSCustomer*/
---------------------------------

