DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CustEvidence_GetFlaggedFromCustList$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_CustEvidence_GetFlaggedFromCustList(
	IN ip_FromCTSCustID 	BIGINT, 
    IN ip_ToCTSCustID 		VARCHAR(50))
BEGIN
	/*
		Created:	20200123@Casey.Huynh	
		Task :		GET Affeted Evidence List between 2 customers
		DB:			CTS_DataCenter
		Original: 
		Revisions:
		Param's Explanation (filtered by):
	*/ 

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT 		DISTINCT ed.EvidenceCode , ed.EvidenceName
    FROM		CTS_DataCenter.CustEvidence AS ce
    INNER JOIN	CTS_DataCenter.Evidence AS ed
				ON ce.EvidenceID = ed.EvidenceId
	WHERE		(( ce.CTSCustID = ip_FromCTSCustID)
				OR (ce.CTSCustID = ip_ToCTSCustID))
                AND	ce.Level = 0;
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

END$$	
DELIMITER ;