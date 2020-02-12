DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_GetAllEvidences$$
CREATE PROCEDURE CTS_DataCenter.CTS_DC_GetAllEvidences()
BEGIN
/*
		Created:	20200203@Adam.Tran
		Task :		Chain To Evidence
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
	SELECT e.EvidenceID
			,e.EvidenceCode
		    ,e.EvidenceName
			,e.EvidenceDesc
	FROM   Evidence AS e
    WHERE e.IsActive = 1
    ORDER BY e.EvidenceGroupID, e.OrderNo;
          
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;   
END$$
DELIMITER ;
