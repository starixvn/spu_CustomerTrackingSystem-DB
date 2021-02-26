/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20200107@Casey.Huynh
Task:	 	Init Data for CTSCustomer Data Flow [Redmine ID: 148849] 	
DBName:		CTS_DataCenter
*/

/****Init Data****/
USE CTS_DataCenter;
UPDATE CTS_DataCenter.SystemParameter
SET ParameterName ='CTSCustomer_LastUpdateTimeCustInfo'
WHERE ParameterID = 9;

UPDATE CTS_DataCenter.SystemParameter
SET ParameterName ='CTSCustomer_LastUpdateCustIDCustInfo'
WHERE ParameterID = 10;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES	(11,'CTSCustomer_LastUpdateTimeCustomer', 'Keep the Last Customer_History.UpdateTime', 'DATETIME(3)', NOW())
    ,	(12,'CTSCustomer_LastUpdateCustIDCustomer', 'Keep the Last Customer_History.CustId', 'BIGINT UNSIGNED', 0);
    


