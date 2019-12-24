DELIMITER $$
USE CTS_DataCenter$$
DROP PROCEDURE IF EXISTS CTS_DC_GetEvidenceByCTSCustID $$

CREATE PROCEDURE CTS_DC_GetEvidenceByCTSCustID(IN ip_CTSCustID INT)
BEGIN
	/*
		Created:	20191218@Marcus
		Task :		Get Evidence 
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
	SELECT e.EvidenceName
		   ,e.EvidenceDesc
		   ,e.EvidenceCode
		   ,e.OrderNo
		   ,e.CreatedDate
		   ,eg.EvidenceGroupName
	FROM   CustEvidence AS ce
	INNER JOIN Evidence AS e 
		   ON (ce.EvidenceID = e.EvidenceID)
	INNER JOIN EvidenceGroup AS eg
		   ON (e.EvidenceGroupID = eg.EvidenceGroupID)
	WHERE e.IsActive = True
		  AND ce.CTSCustID = ip_CTSCustID;
          
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;   
END$$
DELIMITER ;