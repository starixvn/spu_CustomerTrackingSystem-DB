/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20210929@Casey.Huynh
Task:	 	Adjust Match Monitor
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20210929@Casey.Huynh: Created [#161528]
Reviewer:

*/
USE CTS_DataCenter;

CREATE TABLE RawTransactionSum(
		TransDate		DATETIME NOT NULL
	,	SubscriberId	INT NOT NULL
	,	TransTotal		INT
	,	PRIMARY KEY PK_RawTransactionSum(TransDate, SubscriberId)
) ENGINE=InnoDB;

CREATE TABLE Transaction07Sum(
		TransDate				DATETIME NOT NULL
	,	SubscriberId			INT NOT NULL
	,	ValidTransTotal			INT
	,	ValidTransBrowserless	INT
	,	ValidTransNoDevice		INT
	,	ValidTransOldDevice		INT
	,	ValidTransRecoverDevice	INT
	,	ValidTransNewDevice		INT
	,	PRIMARY KEY TransactionSum(TransDate, SubscriberId)
) ENGINE=InnoDB;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES(49,'Transaction07Sum_LastTransID','Transaction07Sum_LastTransID','BIGINT UNSIGNED','0');
