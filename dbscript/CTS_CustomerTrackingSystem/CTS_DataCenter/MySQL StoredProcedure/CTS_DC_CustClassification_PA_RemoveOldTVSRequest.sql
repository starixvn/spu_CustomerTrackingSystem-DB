/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin,ctsWebAdmin" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_PA_RemoveOldTVSRequest`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_RemoveOldTVSRequest`(
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
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_RemoveOldTVSRequest();
            
	*/ 
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedEvidence;    
	CREATE TEMPORARY TABLE Temp_ExistedEvidence(	  
			CTSCustID				BIGINT UNSIGNED 
        ,	EvidenceID_Licensee 	SMALLINT	        
        ,	EvidenceID_Credit 		SMALLINT	
        ,  	INDEX IX_Temp_ExistedEvidence_CTSCustIDEvidenceID(CTSCustID, EvidenceID_Licensee, EvidenceID_Credit)
    );
    
    /* REMOVE FROM QUEUE  */
    UPDATE Temp_PA AS t
		INNER JOIN CTSCustomerClassificationQueue AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	SET d.IsFromTVS = 0
	WHERE t.TVSRequestID IS NOT NULL;
        
    DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTSCustomerClassificationQueue AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE t.TVSRequestID IS NOT NULL
		AND (d.IsFromCTS = 0 AND d.IsFromTW = 0);
    
    /* REMOVE FROM OLD PA  */
    UPDATE Temp_PA AS t
		INNER JOIN CTSCustomerClassificationOldPA AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	SET d.IsFromTVS = 0
	WHERE t.TVSRequestID IS NOT NULL;
    
    DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTSCustomerClassificationOldPA AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE t.TVSRequestID IS NOT NULL
		AND (d.IsFromCTS = 0 AND d.IsFromTW = 0 AND d.IsFromAI = 0);
    
    /* REMOVE FROM CLASSIFICATION HISTORY  */    
	DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTSCustomerClassification_History AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE t.TVSRequestID IS NOT NULL;
        
    /* REMOVE FROM CLASSIFICATION  */
    INSERT INTO Temp_ExistedEvidence(CTSCustID, EvidenceID_Licensee, EvidenceID_Credit)
    SELECT DISTINCT t.CTSCustID, c.EvidenceID_Licensee, c.EvidenceID_Credit
    FROM Temp_PA AS t
		INNER JOIN CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
        INNER JOIN CustomerCategory AS c ON d.CategoryID = d.CategoryID
	WHERE t.TVSRequestID IS NOT NULL;    
    
    UPDATE Temp_PA AS t
		INNER JOIN CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	SET d.IsFromTVS = 0
	WHERE t.TVSRequestID IS NOT NULL;
    
	DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE t.TVSRequestID IS NOT NULL
		AND (d.IsFromCTS = 0 AND d.IsFromTW = 0 AND d.IsFromAI = 0);
      
	/* REMOVE FROM CUSTOMER EVIDENCE  */ 
    DELETE d
    FROM Temp_ExistedEvidence AS t
		INNER JOIN CustEvidence AS d ON t.CTSCustID = d.CTSCustID 
			AND (t.EvidenceID_Credit = d.EvidenceID OR t.EvidenceID_Licensee = d.EvidenceID)
	WHERE d.Level = 0;    			

	/* LOG THE VOID REQUEST FOR FURTHER TRACKING */
    INSERT INTO TVSVoidRequest_History (TVSRequestID,CustIDs,ReasonID,CreatedBy,CreatedDate)
    SELECT TVSRequestID, GROUP_CONCAT(DISTINCT CustID), ReasonID, CreatedBy, NOW()
    FROM Temp_PA
    GROUP BY TVSRequestID, ReasonID, CreatedBy;
    
END$$
DELIMITER ;