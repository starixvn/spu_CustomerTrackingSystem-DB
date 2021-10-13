/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20210929@Casey.Huynh
Task:	 	Transaction Monitor
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20210929@Casey.Huynh: Created [Redmine ID: #161528]
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
    ,	ValidNoDevice				INT UNSIGNED
    ,	ValidDeviceStatusNew		INT UNSIGNED
	,	ValidDeviceStatusOld		INT UNSIGNED
	,	ValidDeviceStatusRecover	INT UNSIGNED
	,	ValidBrowserless			INT UNSIGNED
    ,	LastTransID					BIGINT UNSIGNED
	
	,	PRIMARY KEY PK_SumTransaction(TransDate, SubscriberId)
) ENGINE=InnoDB;

INSERT INTO DCS_DataCenter.SystemSetting(ID,VGroup,VName,VValue,UpdatedTime)
VALUES(11,'SumTransaction','SumTransaction_LastTransID','0',NOW())
	, (12,'ServiceSumTransaction','BatchSize DCS_DC_SumTransaction_Get','5000',NOW());