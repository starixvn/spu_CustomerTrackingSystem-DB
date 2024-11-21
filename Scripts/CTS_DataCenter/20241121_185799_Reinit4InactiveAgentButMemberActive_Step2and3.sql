/************************************************* STEP 2 *******************************************************/
DROP TEMPORARY TABLE IF EXISTS Temp_Cust; 
CREATE TEMPORARY TABLE Temp_Cust 
(	CTSCustID bigint unsigned NOT NULL
	, CustID bigint unsigned NOT NULL
    , LastTicketDate datetime NULL
	, PRIMARY KEY (CTSCustID)
);

INSERT INTO Temp_Cust (CTSCustID, CustID)
SELECT cus.CTSCustID, cus.CustID
FROM CTS_DataCenter.Adhoc_Agent2Init AS ad
INNER JOIN CTS_DataCenter.CTSCustomer AS cus
ON cus.CustID = ad.CustID AND cus.CustSubID = 0 AND cus.RoleID = 2;

INSERT IGNORE INTO Temp_Cust (CTSCustID, CustID)
SELECT DISTINCT mg.CTSCustID, mg.CustID
FROM CTS_DataCenter.Adhoc_F185799Mig_CTSCustomerClassification as mg
INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = mg.CustID
WHERE mg.Migrate_IsMove = 1 AND cus.CustSubID = 0 AND cus.RoleID = 2;

/*CTSCustomerAssociationStatus */
INSERT INTO CTS_Archive.CTSCustomerAssociationStatus(CTSCustID, CustID, LastTicketDate)
SELECT	tmp.CTSCustID
	,	tmp.CustID
	,	NULL
FROM Temp_Cust AS tmp
WHERE NOT EXISTS (SELECT 1 FROM CTS_Archive.CTSCustomerAssociationStatus AS arc  WHERE arc.CTSCustID = tmp.CTSCustID);

WITH cteAgent AS (
SELECT agCC.CustID AS AgentCustID, agCC.CTSCustID AS AgentCTSCustID, MAX(arc.LastTicketDate) AS MAXLastTicketDate
FROM CTS_Archive.CTSCustomerAssociationStatus AS arc
    INNER JOIN CTS_DataCenter.CTSCustomer AS me ON me.CTSCustID = arc.CTSCustID AND me.RoleID = 1
    INNER JOIN CTS_DataCenter.Adhoc_Reinit4InactiveAgentButMemberActive AS ag ON ag.CustID = me.recommend
    INNER JOIN CTS_DataCenter.CTSCustomerClassificationAgency AS agCC 
        ON agCC.ParentID = 140000 AND agCC.CategoryID = 140700 AND agCC.CustID = ag.CustID 
GROUP BY AgentCustID, AgentCTSCustID
)
UPDATE Temp_Cust AS tmp
    INNER JOIN cteAgent as t ON t.AgentCTSCustID = tmp.CTSCustID
SET tmp.LastTicketDate = t.MAXLastTicketDate
WHERE DATEDIFF(DATE(CURRENT_DATE()), DATE(t.MAXLastTicketDate)) <= 30;

UPDATE CTS_Archive.CTSCustomerAssociationStatus AS arc
    INNER JOIN Temp_Cust AS tmp
        ON tmp.CTSCustID = arc.CTSCustID
SET arc.LastTicketDate = tmp.LastTicketDate
WHERE IFNULL(arc.LastTicketDate, 0) < IFNULL(tmp.LastTicketDate,0) AND tmp.LastTicketDate IS NOT NULL;

/************************************************* STEP 3 *******************************************************/
DROP TEMPORARY TABLE IF EXISTS Temp_Customer; 
CREATE TEMPORARY TABLE Temp_Customer 
(	CustID bigint unsigned NOT NULL
	, PRIMARY KEY (CustID)
);

INSERT INTO Temp_Customer (CustID)
SELECT ag.CustID
FROM CTS_DataCenter.Adhoc_Reinit4InactiveAgentButMemberActive AS ag
INNER JOIN CTS_DataCenter.CTSCustomerClassificationAgency AS agCC 
    ON agCC.ParentID = 140000 AND agCC.CategoryID = 140700 AND agCC.CustID = ag.CustID; 

/*CTSCustomerClassificationAgency*/
DELETE cls
FROM CTS_DataCenter.CTSCustomerClassificationAgency AS cls
INNER JOIN Temp_Customer AS tmp ON tmp.CustID = cls.CustID;

/*CTSCustomerClassificationAgency_History*/
DELETE his
FROM CTS_DataCenter.CTSCustomerClassificationAgency_History AS his
INNER JOIN Temp_Customer AS tmp ON tmp.CustID = his.CustID;



