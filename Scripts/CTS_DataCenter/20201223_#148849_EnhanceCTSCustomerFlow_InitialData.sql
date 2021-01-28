/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20200107@Casey.Huynh
Task:	 	Init Data for CTSCustomer Data Flow [Redmine ID: 148849] 	
DBName:		CTS_DataCenter
*/

/****Init Data****/
USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES	(7,'CTSCustomer_LastInsertCustID', 'Keep the Last CustID in CTSCustomer table', 'BIGINT UNSIGNED', 0)
    ,	(8,'CTSCustomer_LastInsertCustSubID', 'Keep the Last CustSubID in CTSCustomer table', 'BIGINT UNSIGNED', 0)
    ,	(9,'CTSCustomer_LastUpdateTime', 'Keep the Last CustInfo_History.UpdateTime', 'DATETIME(3)', NOW())
    ,	(10,'CTSCustomer_LastUpdateCustID', 'Keep the Last CustInfo_History.CustId', 'BIGINT UNSIGNED', 0);
    
  
UPDATE 	CTS_DataCenter.SystemParameter AS s
SET 	s.ParameterValue = (SELECT MAX(c.CustID) FROM CTS_DataCenter.CTSCustomer AS c)
WHERE	s.ParameterID = 7 AND s.ParameterName = 'CTSCustomer_LastInsertCustID';

/* GET @LastInsertCustSubID FROM Slave Sever because  CTS_DataCenter.CTSCustomer doesn't have Index on CustSubID*/
SET @LastInsertCustSubID = (SELECT MAX(c.CustSubID) FROM CTS_DataCenter.CTSCustomer AS c);

USE CTS_DataCenter;
UPDATE 	CTS_DataCenter.SystemParameter AS s
SET 	s.ParameterValue = @LastInsertCustSubID
WHERE	s.ParameterID = 8 AND s.ParameterName = 'CTSCustomer_LastInsertCustSubID';

