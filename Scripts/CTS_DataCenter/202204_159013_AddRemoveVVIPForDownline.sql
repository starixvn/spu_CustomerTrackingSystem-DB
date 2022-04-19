/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	202204190@Casey.Huynh
Task:	 	Add/Remove VVIP For Downline
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20220419@Casey.Huynh: Created [Redmine ID: #159013]
Reviewer:
*/

USE CTS_DataCenter;
CREATE TABLE QueueCustomerClassificationDownline(
			ID						BIGINT UNSIGNED	AUTO_INCREMENT
		,  	CTSCustID 				BIGINT UNSIGNED
		,	CustID					BIGINT UNSIGNED
		,	RoleID					TINYINT
		,	SubscriberID 			INT UNSIGNED
		,	CreatedBy				BIGINT UNSIGNED
		,	Remark					VARCHAR(300)
		,	CategoryID				SMALLINT UNSIGNED
		,	LastDownlineCTSCustID 	BIGINT UNSIGNED
        ,	ActionType				TINYINT
		,	InsertTime		DATETIME(3)

		,	PRIMARY KEY PK_Temp_Customer(ID)
		,	INDEX IX_Temp_Customer_CustID(CustID)
		,	INDEX IX_Temp_Customer_CTSCustID(CTSCustID)
);

USE CTS_DataCenter;
INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue) 
VALUES ('91', 'QueueCustomerClassificationDownline_PackSize', 'QueueCustomerClassificationDownline_PackSize', 'INT', '500');