DELIMITER $$
USE CTS_DataCenter$$
DROP PROCEDURE IF EXISTS CTS_DC_CustEvidence_Get $$

CREATE PROCEDURE CTS_DC_CustEvidence_Get(IN ip_CTSCustID INT)
BEGIN
	/*
		Created:	20191218@Marcus
		Task :		Get Distinct Customer Evidence for All Level
		DB:			CTS_DataCenter
		Original:

		Revisions:
					20200218@CaseyHuynh: Remove Inner Join with EvidenceGroup, and Disctinct Evidence
		Param's Explanation (filtered by):
	*/
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
	SELECT DISTINCT e.EvidenceName
		   ,e.EvidenceDesc
		   ,e.EvidenceCode
		   ,e.OrderNo
	FROM   CustEvidence AS ce
	INNER JOIN Evidence AS e 
		   ON (ce.EvidenceID = e.EvidenceID)
	WHERE  ce.CTSCustID = ip_CTSCustID;
          
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;   
END$$
DELIMITER ;