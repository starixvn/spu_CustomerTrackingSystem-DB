/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20210929@Casey.Huynh
Task:	 	Adjust Match Monitor
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20210929@Casey.Huynh: Created [#161528]
Reviewer:

*/
USE DCS_DataCenter;

CREATE TABLE SumRawTransaction(
		TransDate		DATETIME NOT NULL
	,	SubscriberID	INT NOT NULL
	,	TransTotal		INT UNSIGNED
	,	PRIMARY KEY PK_SumRawTransaction(TransDate, SubscriberId)
) ENGINE=InnoDB;

CREATE TABLE SumTransaction(
		TransDate					DATETIME NOT NULL
	,	SubscriberID				INT NOT NULL
	,	ValidTotal					INT UNSIGNED
    ,	ValidTotalDevice			INT UNSIGNED
    ,	ValidDeviceStatusNew		INT UNSIGNED
	,	ValidDeviceStatusOld		INT UNSIGNED
	,	ValidDeviceStatusRecover	INT UNSIGNED
	,	ValidBrowserless			INT UNSIGNED
    ,	LastTransID					BIGINT UNSIGNED
	
	,	PRIMARY KEY PK_SumTransaction(TransDate, SubscriberId)
) ENGINE=InnoDB;

INSERT INTO DCS_DataCenter.SystemSetting(ID,VGroup,VName,VValue,UpdatedTime)
VALUES(11,'SumTransaction','SumTransactionLastTransID','0',NOW());