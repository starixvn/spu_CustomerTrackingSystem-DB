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

CREATE TABLE CTSCustomerClassificationVVIPQueue(
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
		,	InsertTime				DATETIME(3)

		,	PRIMARY KEY PK_Temp_Customer(ID)
		,	INDEX IX_Temp_Customer_CustID(CustID)
		,	INDEX IX_Temp_Customer_CTSCustID(CTSCustID)
);

USE CTS_DataCenter;
CREATE TABLE CTSCustomerClassificationVVIP(
		  	CTSCustID 				BIGINT UNSIGNED
		,	CustID					BIGINT UNSIGNED
		,	RoleID					TINYINT
		,	SubscriberID 			INT UNSIGNED
		,	CreatedBy				BIGINT UNSIGNED
		,	Remark					VARCHAR(300)
		,	CategoryID				SMALLINT UNSIGNED
		,	IsAffectToDownline 		BOOLEAN
		,	InsertTime				DATETIME(3)

		,	PRIMARY KEY PK_Temp_Customer(CTSCustID)
		,	INDEX IX_Temp_Customer_CustID(CustID)
		,	INDEX IX_Temp_Customer_IsAffectToDownline(IsAffectToDownline)
);

USE CTS_DataCenter;
INSERT INTO SystemParameter (ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue) 
VALUES ('91', 'QueueCustomerClassificationDownline_PackSize', 'QueueCustomerClassificationDownline_PackSize', 'INT', '500');

USE CTS_DataCenter;
INSERT INTO CTS_DataCenter.StaticList(ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES (4,24,'Classification Source Type','Classification Source Type','VVIP tag is affected by Super','VVIP tag is affected by Super',24,1,'Mark VVIP For Downline',NOW())
	, (4,25,'Classification Source Type','Classification Source Type','VVIP tag is affected by Master','VVIP tag is affected by Master',25,1,'Mark VVIP For Downline',NOW())
    , (4,26,'Classification Source Type','Classification Source Type','VVIP untag is affected by Master','VVIP tag is affected by Agent',26,1,'Mark VVIP For Downline',NOW())
    , (4,27,'Classification Source Type','Classification Source Type','VVIP untag is affected by Super','VVIP untag is affected by Super',27,1,'Remove VVIP For Downline',NOW())
	, (4,28,'Classification Source Type','Classification Source Type','VVIP untag is affected by Master','VVIP untag is affected by Master',28,1,'Remove VVIP For Downline',NOW())
    , (4,29,'Classification Source Type','Classification Source Type','VVIP untag is affected by Master','VVIP untag is affected by Agent',29,1,'Remove VVIP For Downline',NOW())