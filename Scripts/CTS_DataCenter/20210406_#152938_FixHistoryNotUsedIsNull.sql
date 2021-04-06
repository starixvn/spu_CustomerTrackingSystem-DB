/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
	Created: 20210406@Irena.Vo
	Task: Initial Clean ID [Redmine ID: #152938] 
	DB: CTS_Adhoc
*/
-- Initial Clean ID.
UPDATE CTS_DataCenter.SystemParameter
SET ParameterValue = 13173448
WHERE ParameterID = 15; 