/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210907@Long.Luu
Task:	 	Update Robot Users Rules [Redmine ID: #161232]
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
/*
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History 
CHANGE LastXDaysMargin RobotCounter SMALLINT;
*/
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History 
ADD RobotCounter SMALLINT;

UPDATE CTS_DataCenter.SystemParameter
SET 	ParameterName = 'LastScannedRobotUsersTimeStamp'
	,	ParameterDesc = 'Keep the last scanned time-stamp of getting robot users'
    ,	ParameterDataType = 'BIGINT'
    ,	ParameterValue = '0'
WHERE ParameterID = 3;