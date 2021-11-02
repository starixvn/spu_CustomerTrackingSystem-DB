/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20211101@Aries.Nguyen
    Task:	 	Add System Parameter
    DBName:		CTS_DataCenter
*/
USE CTS_DataCenter;
INSERT IGNORE INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES  (61, 'Cust Evidence Insert From Association Batch Size', 'Batch Size', 'INT', '1500');