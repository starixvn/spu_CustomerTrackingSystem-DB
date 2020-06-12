DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_API_GetFlaggedCustomers $$

CREATE PROCEDURE CTS_DC_API_GetFlaggedCustomers (IN ip_CustIds VARCHAR(21845))
BEGIN
	/*
		Created:	20200610@Harvey
		Task:		Get flagged customer for AI Ghost [Redmine ID: 135649]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
        
        CALL CTS_DC_API_GetFlaggedCustomers ('3698310,910137,1176070,1176083');
	*/
    
    DROP TEMPORARY TABLE IF EXISTS flaggedCustomers;
    CREATE TEMPORARY TABLE flaggedCustomers (
		CTSCustID		BIGINT
		,CustId 		INT
		,EviID			SMALLINT
        ,EvidenceCode 	VARCHAR(10)
        ,EvidenceName 	VARCHAR(50)
        ,Level			TINYINT
        ,FromCTSCustID	BIGINT
        ,CreatedDate 	DATETIME
    );

	DROP TEMPORARY TABLE IF EXISTS tempCustID;
    CREATE TEMPORARY TABLE tempCustID (
		CustID INT PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO tempCustID (CustID) VALUES ('", REPLACE(ip_CustIds, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    INSERT INTO flaggedCustomers
	SELECT cevi.CTSCustID
		,cust.CustID
		,cevi.EvidenceID
		,evi.EvidenceCode
        ,evi.EvidenceName
		,cevi.LEVEL
		,cevi.FromCustID
		,cevi.CreatedDate
	FROM CustEvidence cevi
		INNER JOIN Evidence evi ON cevi.EvidenceID = evi.EvidenceID
		INNER JOIN CTSCustomer cust ON cust.CTSCustID = cevi.CTSCustID
		INNER JOIN tempCustID tcust ON cust.CustID = tcust.CustID;

    -- remove because of exception
    DELETE fc
	FROM flaggedCustomers fc
	INNER JOIN CustException cex ON LEAST(fc.CTSCustID, fc.FromCTSCustID) = cex.LeastCTSCustID_Order
		AND GREATEST(fc.CTSCustID, fc.FromCTSCustID) = cex.GreatestCTSCustID_Order;
        
	-- remove because retracted evidence
    DELETE fc
	FROM flaggedCustomers fc
	INNER JOIN CustRetractEvidence cre ON fc.CTSCustID = cre.CTSCustID
		AND fc.EviID = cre.EvidenceID
        AND fc.LEVEL = 2;
        
    SELECT CustId
		,EvidenceCode 
        ,EvidenceName
		,MIN(CreatedDate) AS 'CreatedDate'
	FROM flaggedCustomers
    GROUP BY CustId, EvidenceCode, EvidenceName;
    
END$$
DELIMITER ;