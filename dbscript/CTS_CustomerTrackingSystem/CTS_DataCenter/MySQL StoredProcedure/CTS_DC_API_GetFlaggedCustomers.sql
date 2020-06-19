DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_API_GetFlaggedCustomers $$

CREATE PROCEDURE CTS_DC_API_GetFlaggedCustomers (IN ip_CustIds LONGTEXT)
BEGIN
	/*
		Created:	20200610@Harvey
		Task:		Get flagged customer for AI Ghost [Redmine ID: 135649]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200619@Harvey: only get FLAGGED customer (has evidence level 0)
        
		Param's Explanation (filtered by):
        
        CALL CTS_DC_API_GetFlaggedCustomers ('3698310,910137,1176070,1176083');
	*/
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
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
	FROM tempCustID tcust
		INNER JOIN CTSCustomer cust ON cust.CustID = tcust.CustID AND cust.CustSubID = 0
        INNER JOIN CustEvidence cevi ON cust.CTSCustID = cevi.CTSCustID AND cust.SubscriberID = cevi.SubscriberID
        INNER JOIN Evidence evi ON cevi.EvidenceID = evi.EvidenceID
	WHERE cevi.LEVEL = 0;
    
    /*
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
		INNER JOIN CTSCustomer cust ON cust.CTSCustID = cevi.CTSCustID AND cust.SubscriberID = cevi.SubscriberID
		INNER JOIN tempCustID tcust ON cust.CustID = tcust.CustID;
    */

    SELECT CustId
		,EvidenceCode 
        ,EvidenceName
		,CreatedDate
	FROM flaggedCustomers;
    
END$$
DELIMITER ;