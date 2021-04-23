/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20200107@Casey.Huynh
Task:	 	Init Data for CTSCustomer Data Flow [Redmine ID: 148849] 	
DBName:		CTS_DataCenter
*/

/****Init Data****/

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES	(18,'CTSCustomer_LastUpdateTimeCustProductStatus', 'Keep the Last CustProductStatus_History.UpdateTime', 'DATETIME(3)', NOW())
    ,	(19,'CTSCustomer_LastUpdateCustIDCustProductStatus', 'Keep the Last CustProductStatus_History.CustId', 'BIGINT UNSIGNED', 0);
    


