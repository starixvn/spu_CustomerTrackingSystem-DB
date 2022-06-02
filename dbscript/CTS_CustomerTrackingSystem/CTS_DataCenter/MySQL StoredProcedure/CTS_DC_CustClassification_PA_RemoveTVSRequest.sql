/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_PA_RemoveOldTVSRequest`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_RemoveOldTVSRequest`(
		IN ip_TVSRequestIDs			VARCHAR(2000)
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20220602@Long.Luu
		Task:		Remove TVS Request data
		DB:			CTS_DataCenter
		Original:
		Revisions:
            - 20220602@Long.Luu: Created [Redmine ID: #172561]
            
        Param's Explanation (filtered by):
        
        Example:	
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_RemoveOldTVSRequest('1,2');
            
	*/ 
    DROP TEMPORARY TABLE IF EXISTS Temp_TVSRequestID;    
	CREATE TEMPORARY TABLE Temp_TVSRequestID(
			RequestID			BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustClassification;
    CREATE TEMPORARY TABLE Temp_CustClassification(
			CTSCustID		BIGINT UNSIGNED
        ,	EvidenceID		SMALLINT
        ,	PRIMARY KEY (CTSCustID, EvidenceID)
	);
	
	SET @sql = CONCAT("INSERT INTO Temp_TVSRequestID (RequestID) VALUES ('", REPLACE(ip_TVSRequestIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
  
    /* REMOVE FROM QUEUE  */
    DELETE d
    FROM Temp_TVSRequestID AS t
		INNER JOIN CTSCustomerClassificationQueue AS d ON t.RequestID = d.TVSRequestID;
    
    /* REMOVE FROM OLD PA  */
    DELETE d
    FROM Temp_TVSRequestID AS t
		INNER JOIN CTSCustomerClassificationOldPA AS d ON t.RequestID = d.TVSRequestID;
        	
    /* REMOVE FROM CLASSIFICATION LOG  */
	DELETE d
    FROM Temp_TVSRequestID AS t
		INNER JOIN CTSCustomerClassification_Log AS d ON t.RequestID = d.TVSRequestID;
    
    /* REMOVE FROM CLASSIFICATION HISTORY  */    
	DELETE d
    FROM Temp_TVSRequestID AS t
		INNER JOIN CTSCustomerClassification_History AS d ON t.RequestID = d.TVSRequestID;
        
    /* REMOVE FROM CLASSIFICATION  */    
    INSERT IGNORE INTO Temp_CustClassification(CTSCustID, EvidenceID)
    SELECT 	i.CTSCustID
        ,	(CASE 	WHEN i.IsLicensee = 1 THEN c.EvidenceID_Licensee
					WHEN i.IsLicensee = 0 THEN c.EvidenceID_Credit
					ELSE NULL 
			END)
    FROM Temp_TVSRequestID AS t
		INNER JOIN CTSCustomerClassification AS d ON t.RequestID = d.TVSRequestID
		INNER JOIN CTSCustomer AS i ON d.CustID = i.CustID
		INNER JOIN CustomerCategory AS c ON c.CategoryID = d.CategoryID;
            
	DELETE t
    FROM Temp_TVSRequestID AS t
		INNER JOIN CTSCustomerClassification AS q ON t.RequestID = q.TVSRequestID;
        
	/* REMOVE FROM CUSTOMER EVIDENCE  */ 
    DELETE t
    FROM Temp_CustClassification AS t
		INNER JOIN CustEvidence AS e ON t.CTSCustID = e.CTSCustID AND t.EvidenceID = e.EvidenceID
	WHERE e.Level = 0;    			
 
END$$
DELIMITER ;