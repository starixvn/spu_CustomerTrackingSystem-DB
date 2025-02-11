/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Created:	20250107@Victoria.Le
	Task:		Update schema - remove UNSIGNED from some columns in CTSCustomer & CTSCustomerDuplicate
	Server:  	Master
	DBName:		CTS_DataCenter

	Param's Expanation:
	
	Example:
		
	Revisions: 
		- 20250107@Victoria.Le:			Initial Writing [Redmine ID: #214585]
*/

USE CTS_DataCenter;

SET @INSERTEDTIME = NOW();
INSERT IGNORE INTO SystemEventStatus (EventName,Status,LastExecTime)
SELECT 'EV_CTS_DC_Adhoc_CreditSMDirectMember_CheckData','Stop',@INSERTEDTIME;

SELECT MAX(ModifiedTime),MAX(CTSCustID)
INTO @lv_MaxModifiedTime, @lv_MaxCTSCustID
FROM CTSCustomer;

INSERT INTO SystemParameter (ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES (991,'AdhocUpdateDirectMember_CTSCustID_UM','AdhocUpdateDirectMember_CTSCustID_UM','BIGINT',@lv_MaxCTSCustID)
, (990,'AdhocUpdateDirectMember_MaxModifiedTime_UM','AdhocUpdateDirectMember_MaxModifiedTime_UM','DATETIME(4)',@lv_MaxModifiedTime)
;


