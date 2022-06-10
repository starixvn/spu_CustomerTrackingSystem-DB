/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
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
		AND (d.IsFromCTS = 0 AND d.IsFromTW = 0 AND IsFromAI = 0);
    
    /* REMOVE FROM CLASSIFICATION HISTORY  */    
	DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTSCustomerClassification_History AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE t.TVSRequestID IS NOT NULL;
        
    /* REMOVE FROM CLASSIFICATION  */      
    UPDATE Temp_PA AS t
		INNER JOIN CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	SET d.IsFromTVS = 0
	WHERE t.TVSRequestID IS NOT NULL;
    
	DELETE t
    FROM Temp_PA AS t
		INNER JOIN CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE t.TVSRequestID IS NOT NULL
		AND (d.IsFromCTS = 0 AND d.IsFromTW = 0 AND IsFromAI = 0);
      
	/* REMOVE FROM CUSTOMER EVIDENCE  */ 
    DELETE t
    FROM Temp_PA AS t
		INNER JOIN CustEvidence AS e ON t.CTSCustID = e.CTSCustID AND t.ToEvidenceID = e.EvidenceID
	WHERE t.TVSRequestID IS NOT NULL
		AND e.Level = 0;    			

	/* LOG THE VOID REQUEST FOR FURTHER TRACKING */
    INSERT INTO TVSVoidRequest_History (TVSRequestID,CustIDs,ReasonID,CreatedBy,CreatedDate)
    SELECT TVSRequestID, GROUP_CONCAT(DISTINCT CustID), ReasonID, CreatedBy, NOW()
    FROM Temp_PA
    GROUP BY TVSRequestID, ReasonID, CreatedBy;
    
END$$
DELIMITER ;