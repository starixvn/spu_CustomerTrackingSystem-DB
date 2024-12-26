/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20241217@Victoria.Le
	Task:		Update schema - remove UNSIGNED from some columns in CTSCustomer & CTSCustomerDuplicate
	Server:  	Master
	DBName:		CTS_DataCenter

	Param's Expanation:
	
	Example:
		
	Revisions: 
		- 20241217@Victoria.Le:			Initial Writing [Redmine ID: #214585]
*/

USE CTS_DataCenter;

/*1. CTSCustomer*/
ALTER TABLE CTSCustomer
	ADD COLUMN MRecommend_new INT
,	ADD COLUMN Recommend_new INT
;

/*
ALTER TABLE CTSCustomer
	ADD COLUMN MRecommend_new INT AFTER SRecommend
,	ADD COLUMN Recommend_new INT AFTER MRecommend_new
;
*/

SET @INSERTEDTIME = NOW();
INSERT IGNORE INTO SystemEventStatus (EventName,Status,LastExecTime)
SELECT 'EV_CTS_DC_Adhoc_CreditSMDirectMember_Update','Stop',@INSERTEDTIME;

INSERT IGNORE INTO SystemEventStatus (EventName,Status,LastExecTime)
SELECT 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckDIFF','Stop',@INSERTEDTIME;

SELECT MAX(ModifiedTime)
INTO @lv_MaxModifiedTime
FROM CTSCustomer;

INSERT INTO SystemParameter (ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES (995,'AdhocUpdateDirectMember_CTSCustomer_Batchsize','AdhocUpdateDirectMember_CTSCustomer_Batchsize','BIGINT','4000')
, (994,'AdhocUpdateDirectMember_CTSCustomer_CTSCustID','AdhocUpdateDirectMember_CTSCustomer_CTSCustID','BIGINT','0')
, (993,'AdhocUpdateDirectMember_CTSCustomer_TotalCallSP','AdhocUpdateDirectMember_CTSCustomer_TotalCallSP','BIGINT','0')
, (992,'AdhocUpdateDirectMember_CTSCustomer_MaxModifiedTime','AdhocUpdateDirectMember_CTSCustomer_MaxModifiedTime','DATETIME(4)',@lv_MaxModifiedTime)
;


