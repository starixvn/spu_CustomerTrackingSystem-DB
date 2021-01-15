/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20200107@Casey.Huynh
Task:	 	Init Data CTSCustomer Data Flow
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
Reviewer:
*/

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES	(7,'CTSCustomer_LastInsertCustID', 'Keep the Last CustID in CTSCustomer table', 'BIGINT UNSIGNED', 0)
    ,	(8,'CTSCustomer_LastInsertCustSubID', 'Keep the Last CustSubID in CTSCustomer table', 'BIGINT UNSIGNED', 0)
    ,	(9,'CTSCustomer_LastUpdateTime', 'Keep the Last CustInfo_History.UpdateTime', 'BIGINT UNSIGNED', NOW())
    ,	(10,'CTSCustomer_LastUpdateCustID', 'Keep the Last CustInfo_History.CustId', 'BIGINT UNSIGNED', 0);

UPDATE 	CTS_DataCenter.SystemParameter AS s
SET 	s.ParameterValue = (SELECT MAX(c.CustID) FROM CTS_DataCenter.CTSCustomer AS c)
WHERE	s.ParameterID = 7 AND s.ParameterName = 'CTSCustomer_LastInsertCustID';

UPDATE 	CTS_DataCenter.SystemParameter AS s
SET 	s.ParameterValue = (SELECT MAX(c.CustSubID) FROM CTS_DataCenter.CTSCustomer AS c)
WHERE	s.ParameterID = 8 AND s.ParameterName = 'CTSCustomer_LastInsertCustSubID';

