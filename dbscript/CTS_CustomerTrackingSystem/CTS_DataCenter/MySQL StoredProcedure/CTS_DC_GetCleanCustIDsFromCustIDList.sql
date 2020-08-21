DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DC_GetCleanCustIDsFromCustIDList $$

CREATE PROCEDURE `CTS_DC_GetCleanCustIDsFromCustIDList`(IN ip_CTSCustIDList VARCHAR(2000))
BEGIN
	/*
		Created:	20200820@Long.Luu
		Task :		Get Clean Customers After removing evidence
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200820@Long.Luu: Created [Redmine ID: 139701]
		
		Param's Explanation (filtered by):
	*/
    
    DROP TEMPORARY TABLE IF EXISTS TempCTSCustIDs;
    CREATE TEMPORARY TABLE TempCTSCustIDs (
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS TempCleanCustID;
    CREATE TEMPORARY TABLE TempCleanCustID (
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
    SET @sql = CONCAT("INSERT INTO TempCTSCustIDs (CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    INSERT INTO TempCleanCustID(CTSCustID)
	SELECT DISTINCT c.CTSCustID
	FROM CTS_DataCenter.CustEvidence AS c
		INNER JOIN TempCTSCustIDs AS t ON c.CTSCustID = t.CTSCustID
		LEFT JOIN CTS_DataCenter.CustRetractEvidence AS r ON c.CTSCustID = r.CTSCustID AND c.EvidenceID = r.EvidenceID
	WHERE (r.CTSCustID IS NULL AND r.EvidenceID IS NULL)
	GROUP BY c.CTSCustID
	HAVING COUNT(1) = 0;

    SELECT DISTINCT	c.CustID
    FROM TempCleanCustID AS a
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID;
        
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$
DELIMITER ;
