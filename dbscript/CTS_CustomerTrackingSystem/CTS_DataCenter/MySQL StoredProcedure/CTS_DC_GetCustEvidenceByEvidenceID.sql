DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetCustEvidenceByEvidenceID $$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_GetCustEvidenceByEvidenceID (IN ip_EvidenceID SMALLINT)
BEGIN
	/*
		Created:	20202105@Harvey.Nguyen
		Task :		Get CustEvidence by EvidenceID - [Redmine: 134591]
		DB:			CTS_DataCenter
		Original: 
		Revisions:
		Param's Explanation (filtered by):
	*/ 

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT cust.CustID
		, evi.EvidenceCode
		, evi.EvidenceName
	FROM CTS_DataCenter.CustEvidence ce
		INNER JOIN CTS_DataCenter.CTSCustomer cust ON ce.CTSCustID = cust.CTSCustID
		INNER JOIN CTS_DataCenter.Evidence evi ON ce.EvidenceID = evi.EvidenceID
	WHERE ce.EvidenceID = ip_EvidenceID
		AND cust.CustID IS NOT NULL;
				

END$$	
DELIMITER ;