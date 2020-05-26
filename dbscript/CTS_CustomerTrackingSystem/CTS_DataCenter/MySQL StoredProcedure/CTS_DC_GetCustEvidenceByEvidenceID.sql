DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustEvidenceByEvidenceID $$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_GetCustEvidenceByEvidenceID (IN ip_EvidenceID VARCHAR(200))
BEGIN
	/*
		Created:	20202105@Harvey.Nguyen
		Task :		Get CustEvidence by EvidenceID - [Redmine: 134591]
		DB:			CTS_DataCenter
		Original: 
		Revisions:
		Param's Explanation (filtered by):
	*/ 
    
	DROP TEMPORARY TABLE IF EXISTS tempEviID;
    CREATE TEMPORARY TABLE tempEviID (
		EvidenceID INT PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO tempEviID (EvidenceID) VALUES ('", REPLACE(ip_EvidenceID, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
	SELECT DISTINCT cust.CustID
	FROM CTS_DataCenter.CustEvidence ce
		INNER JOIN CTS_DataCenter.CTSCustomer cust ON ce.CTSCustID = cust.CTSCustID
        INNER JOIN tempEviID te ON te.EvidenceID = ce.EvidenceID
	WHERE cust.CustID IS NOT NULL;
				

END$$	
DELIMITER ;