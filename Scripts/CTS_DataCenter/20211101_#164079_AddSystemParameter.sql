/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20211101@Aries.Nguyen
    Task:	 	Add System Parameter
    DBName:		CTS_DataCenter
*/
USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES  (64, 'AFC scan PA Last Cust', 'AFC scan PA Last Cust', 'INT', '0'),
		(65, 'AFC scan PA Batch Size', 'Batch Size', 'INT', '1000');