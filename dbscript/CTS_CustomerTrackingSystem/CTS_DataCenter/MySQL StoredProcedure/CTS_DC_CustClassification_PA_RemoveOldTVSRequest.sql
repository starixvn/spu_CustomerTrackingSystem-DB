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
			- 20220602@Long.Luu: 		Created [Redmine ID: #172561]
			- 20220628@Long.Luu: 		Remove affected evidence in case of update Reason [Redmine ID: #174430]
			- 20220801@Long.Luu: 		Adjust Winloss Status for Old Requests [Redmine ID: #174219]
			- 20221007@Harvey.Nguyen: 	Change CTSCustomerClassificationOldPA -> CTSCustomerClassificationOldCategory [Redmine ID: #178022]
			- 20230315@Victoria.Le:		Add Robot Imperva [Redmine ID: #184773]
            
        Param's Explanation (filtered by):
        
        Example:	
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_RemoveOldTVSRequest();
            
	*/ 
    
    DECLARE CONST_WINLOSSSTATUS_LOSING		SMALLINT DEFAULT 0;
    DECLARE CONST_WINLOSSSTATUS_KEEP		SMALLINT DEFAULT 1;
    DECLARE CONST_WINLOSSSTATUS_WINNING		SMALLINT DEFAULT 2;
    
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
		INNER JOIN CTSCustomerClassificationOldCategory AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	SET d.IsFromTVS = 0
	WHERE t.TVSRequestID IS NOT NULL;
    
    DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTSCustomerClassificationOldCategory AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE t.TVSRequestID IS NOT NULL
		AND (d.IsFromCTS = 0 AND d.IsFromTW = 0 AND d.IsFromAI = 0 AND d.IsFromImpreva = 0);
    
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
        INNER JOIN CustomerCategory AS c ON d.CategoryID = c.CategoryID
	WHERE t.TVSRequestID IS NOT NULL;    
    
    UPDATE Temp_PA AS t
		INNER JOIN CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	SET 	d.IsFromTVS = 0
		,	t.WinlossStatus = 	CASE 	
									WHEN t.WinlossStatus = CONST_WINLOSSSTATUS_KEEP THEN CONST_WINLOSSSTATUS_WINNING
                                    ELSE t.WinlossStatus
								END
	WHERE t.TVSRequestID IS NOT NULL;
    
	DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE t.TVSRequestID IS NOT NULL
		AND (d.IsFromCTS = 0 AND d.IsFromTW = 0 AND d.IsFromAI = 0 AND d.IsFromImpreva = 0);
      
	/* REMOVE FROM CUSTOMER EVIDENCE  */ 
    DELETE d
    FROM Temp_ExistedEvidence AS t
		INNER JOIN CustEvidence AS d ON t.CTSCustID = d.CTSCustID 
			AND (t.EvidenceID_Credit = d.EvidenceID OR t.EvidenceID_Licensee = d.EvidenceID)
	WHERE d.Level = 0;    		
	
    /* REMOVE AFFECTED EVIDENCE  */ 
    INSERT INTO CustEvidenceAffectedQueueRemove (CTSCustID,EvidenceID,Created)
	WITH CTE_data (CTSCustID,EvidenceID) AS 
    (
		SELECT	t.CTSCustID
			,	CASE WHEN d.IsLicensee = 1 THEN EvidenceID_Licensee ELSE EvidenceID_Credit END
		FROM Temp_ExistedEvidence AS t
			INNER JOIN CTSCustomer AS d ON t.CTSCustID = d.CTSCustID
	)   
    SELECT CTSCustID, EvidenceID, NOW() 
    FROM CTE_data
    WHERE EvidenceID IS NOT NULL;

	/* LOG THE VOID REQUEST FOR FURTHER TRACKING */
    INSERT INTO TVSVoidRequest_History (TVSRequestID,CustIDs,ReasonID,CreatedBy,CreatedDate)
    SELECT TVSRequestID, GROUP_CONCAT(DISTINCT CustID), ReasonID, CreatedBy, NOW()
    FROM Temp_PA
    GROUP BY TVSRequestID, ReasonID, CreatedBy;
    
END$$
DELIMITER ;