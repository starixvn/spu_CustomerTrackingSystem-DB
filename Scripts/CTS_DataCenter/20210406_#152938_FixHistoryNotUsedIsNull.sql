/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Created: 20210406@Irena.Vo
	Task: Archive History Data are not used. Initial Clean ID [Redmine ID: #152938] 
	DB: CTS_Adhoc
*/
-- Create schema for History Data are not used.
CREATE TABLE CTS_Adhoc.BK152938_ClassHistoryNotUsed LIKE CTS_DataCenter.CTSCustomerClassification_History;

ALTER TABLE CTS_Adhoc.BK152938_ClassHistoryNotUsed
ADD COLUMN TargetDangerLevel1 SMALLINT;

ALTER TABLE CTS_Adhoc.BK152938_ClassHistoryNotUsed
ADD COLUMN IsAppliedDangerLevel1 BIT DEFAULT b'0'; 

-- Initial Clean ID.
UPDATE CTS_DataCenter.SystemParameter
SET ParameterValue = 13173448
WHERE ParameterID = 15; 