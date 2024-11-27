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

/*STEP 5: Update LastTicketDate for Agents (<> (165k + 8811) Has place bet ) having LastTicketDate = NULL*/
DROP TEMPORARY TABLE IF EXISTS Temp_Cust; 
CREATE TEMPORARY TABLE Temp_Cust 
(	CustID bigint unsigned NOT NULL
    , LastTicketDate datetime NULL
	, PRIMARY KEY (CustID)
);

INSERT INTO Temp_Cust(CustID, LastTicketDate)
SELECT ag.CustID, MAX(arc.LastTicketDate)
FROM CTS_DataCenter.Adhoc_OldAgentPlaceBet AS ag
    INNER JOIN CTS_DataCenter.CTSCustomer AS me ON ag.CustID = me.recommend AND me.RoleID = 1
    INNER JOIN CTS_Archive.CTSCustomerAssociationStatus AS arc ON me.CTSCustID = arc.CTSCustID AND arc.LastTicketDate IS NOT NULL
GROUP BY ag.CustID;

UPDATE CTS_Archive.CTSCustomerAssociationStatus AS arc
    INNER JOIN Temp_Cust AS ag
        ON ag.CustID = arc.CustID
SET arc.LastTicketDate = ag.LastTicketDate
WHERE IFNULL(arc.LastTicketDate, 0) < IFNULL(ag.LastTicketDate,0) AND ag.LastTicketDate IS NOT NULL;

