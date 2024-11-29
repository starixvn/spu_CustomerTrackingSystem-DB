/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20241126@Thomas.Nguyen
Task:	 	Customer Classification Agent
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20241126@Thomas.Nguyen: Created [Redmine ID: #185799]
Reviewer:
*/
USE CTS_DataCenter;

CREATE TABLE Adhoc_AgentLastTKDate 
(	
    CTSCustID bigint unsigned NOT NULL
	, CustID bigint unsigned NOT NULL
    , LastTicketDate datetime NULL
	, PRIMARY KEY (CTSCustID)
    , INDEX IX_Adhoc_AgentLastTKDate_CustID (CustID)
);