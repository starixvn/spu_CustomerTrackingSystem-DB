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

/*STEP 1: Update LastTicketDate for Agents (Init + migrate) having LastTicketDate = NULL*/
DROP TEMPORARY TABLE IF EXISTS Temp_Cust; 
CREATE TEMPORARY TABLE Temp_Cust 
(	CTSCustID bigint unsigned NOT NULL
	, CustID bigint unsigned NOT NULL
    , LastTicketDate datetime NULL
	, PRIMARY KEY (CTSCustID)
);

INSERT INTO CTS_DataCenter.Adhoc_AgentLastTKDate (CustID, CTSCustID)
SELECT cus.CustID
		,arc.CTSCustID
FROM CTS_Archive.CTSCustomerAssociationStatus AS arc
    INNER JOIN CTS_DataCenter.CTSCustomer AS cus
ON cus.CTSCustID = arc.CTSCustID AND cus.CustSubID = 0 AND cus.RoleID = 2
WHERE arc.LastTicketDate IS NULL;

INSERT INTO Temp_Cust(CustID, CTSCustID, LastTicketDate)
SELECT ag.CustID, ag.CTSCustID, MAX(arc.LastTicketDate)
FROM CTS_DataCenter.Adhoc_AgentLastTKDate AS ag
    INNER JOIN CTS_DataCenter.CTSCustomer AS me ON ag.CustID = me.recommend AND me.RoleID = 1
    INNER JOIN CTS_Archive.CTSCustomerAssociationStatus AS arc ON me.CTSCustID = arc.CTSCustID AND arc.LastTicketDate IS NOT NULL
GROUP BY ag.CustID,ag.CTSCustID;

UPDATE CTS_DataCenter.Adhoc_AgentLastTKDate AS ag
	INNER JOIN Temp_Cust AS tmp ON tmp.CTSCustID = ag.CTSCustID
SET ag.LastTicketDate = tmp.LastTicketDate;

UPDATE CTS_Archive.CTSCustomerAssociationStatus AS arc
    INNER JOIN CTS_DataCenter.Adhoc_AgentLastTKDate AS ag
        ON ag.CTSCustID = arc.CTSCustID
SET arc.LastTicketDate = ag.LastTicketDate
WHERE IFNULL(arc.LastTicketDate, 0) < IFNULL(ag.LastTicketDate,0) AND ag.LastTicketDate IS NOT NULL;

/*STEP 2: Insert LastTicketDate for Agents (Init + migrate) having LastTicketDate = NULL*/
/*Insert into CTSCustomerAssociationStatus with LastTicketDate NULL*/
INSERT INTO CTS_Archive.CTSCustomerAssociationStatus(CTSCustID, CustID, LastTicketDate)
SELECT	cus.CTSCustID
	,	cus.CustID
	,	NULL
FROM CTS_DataCenter.CTSCustomer AS cus
WHERE cus.RoleID = 2 AND cus.CustSubID = 0
    AND NOT EXISTS (SELECT 1 FROM CTS_Archive.CTSCustomerAssociationStatus AS arc  WHERE arc.CTSCustID = cus.CTSCustID);
