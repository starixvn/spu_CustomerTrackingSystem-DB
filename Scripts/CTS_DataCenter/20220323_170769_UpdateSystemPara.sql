/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220331@Aries.Nguyen
    Task:	 	20220331@Aries.Nguyen: Fix performance issue  [Redmine ID: #170769]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
UPDATE CTS_DataCenter.SystemParameter
SET 	ParameterName = 'DailyScan_InactiveNewMember_LastCategoryID'
	,	ParameterDesc = 'Daily Scan Inactive New Member Last CategoryID'
    ,	ParameterDataType = 'INT'
    ,	ParameterValue = '0'
WHERE ParameterID = 80;

UPDATE CTS_DataCenter.SystemParameter
SET 	ParameterName = 'DailyScan_InactiveNewMember_LastCustID'
	,	ParameterDesc = 'Daily Scan Inactive New Member Last CustID'
    ,	ParameterDataType = 'BIGINT UNSIGNED'
    ,	ParameterValue = '0'
WHERE ParameterID = 81;
