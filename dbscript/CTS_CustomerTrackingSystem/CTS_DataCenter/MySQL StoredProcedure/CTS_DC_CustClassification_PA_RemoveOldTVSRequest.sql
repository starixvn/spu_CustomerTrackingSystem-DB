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
			- 20230404@Victoria.Le:		TVS Abnormal Bet and Abnormal Account - Add IsParlay,SportType,IssueTypeID [Redmine ID: #185319] 
			- 20230601@Victoria.Le:		Add TVSRequestID <> 0 for TVSRequestID IS NOT NULL [Redmine ID: #189023]
            - 20240306@Thomas.Nguyen:	Add column InsertedTime [Redmine ID: #201993]
			- 20240624@Victoria.Le:		Renovate CC Phase 2 [Redmine ID: #205317]

        Param's Explanation (filtered by):
        
        Example:	
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_RemoveOldTVSRequest();
            
	*/ 
    
    DECLARE CONST_WINLOSSSTATUS_LOSING		SMALLINT DEFAULT 0;
    DECLARE CONST_WINLOSSSTATUS_KEEP		SMALLINT DEFAULT 1;
    DECLARE CONST_WINLOSSSTATUS_WINNING		SMALLINT DEFAULT 2;
	DECLARE CONST_TVSRequestTypeID_PA		TINYINT DEFAULT 1;
	DECLARE CONST_TVSRequestTypeID_ROBOT	TINYINT DEFAULT 2;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedEvidence;    
	CREATE TEMPORARY TABLE Temp_ExistedEvidence(	  
			CTSCustID				BIGINT UNSIGNED 
        ,	EvidenceID_Licensee 	SMALLINT	        
        ,	EvidenceID_Credit 		SMALLINT	
        ,  	INDEX IX_Temp_ExistedEvidence_CTSCustIDEvidenceID(CTSCustID, EvidenceID_Licensee, EvidenceID_Credit)
    );
    
    /* REMOVE FROM QUEUE  */
    UPDATE Temp_PA AS t
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationQueue AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	SET d.IsFromTVS = 0
	WHERE IFNULL(t.TVSRequestID,0) <> 0;
        
    DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationQueue AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE IFNULL(t.TVSRequestID,0) <> 0
		AND (d.IsFromCTS = 0 AND d.IsFromTW = 0);
    
    /* REMOVE FROM OLD PA  */
    UPDATE Temp_PA AS t
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
		INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.CategoryID = d.CategoryID
	SET d.IsFromTVS = 0
	WHERE IFNULL(t.TVSRequestID,0) <> 0
		AND ccs.IsKeepOldCateID = 1
		AND EXISTS (SELECT 1
					FROM CTS_DataCenter.CTSCustomerClassification AS cls
						INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = cls.CategoryID
					WHERE d.CustID = cls.CustID
						AND (cs.IsParallelParentID = 1 OR IsMultiCateIDSameParentID = 1)
					);
    
    DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
		INNER JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON ccs.CategoryID = d.CategoryID
	WHERE IFNULL(t.TVSRequestID,0) <> 0
		AND ccs.IsKeepOldCateID = 1
		AND (d.IsFromCTS = 0 AND d.IsFromTW = 0 AND d.IsFromAI = 0 AND d.IsFromImperva = 0)
		AND EXISTS (SELECT 1
					FROM CTS_DataCenter.CTSCustomerClassification AS cls
						INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = cls.CategoryID
					WHERE d.CustID = cls.CustID
						AND (cs.IsParallelParentID = 1 OR IsMultiCateIDSameParentID = 1)
					);
    
    /* REMOVE FROM CLASSIFICATION HISTORY  */    
	DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE IFNULL(t.TVSRequestID,0) <> 0;
        
    /* REMOVE FROM CLASSIFICATION  */
    INSERT INTO Temp_ExistedEvidence(CTSCustID, EvidenceID_Licensee, EvidenceID_Credit)
    SELECT DISTINCT t.CTSCustID, c.EvidenceID_Licensee, c.EvidenceID_Credit
    FROM Temp_PA AS t
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS c ON d.CategoryID = c.CategoryID
	WHERE IFNULL(t.TVSRequestID,0) <> 0
		AND NOT EXISTS (SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
							INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = cls.CategoryID
						WHERE d.CustID = cls.CustID
							AND (cs.IsParallelParentID = 1 OR IsMultiCateIDSameParentID = 1)
						);  
    
    UPDATE Temp_PA AS t
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	SET 	d.IsFromTVS = 0
		,	t.WinlossStatus = 	CASE 	
									WHEN t.WinlossStatus = CONST_WINLOSSSTATUS_KEEP THEN CONST_WINLOSSSTATUS_WINNING
                                    ELSE t.WinlossStatus
								END
	WHERE IFNULL(t.TVSRequestID,0) <> 0
		AND NOT EXISTS (SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
							INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = cls.CategoryID
						WHERE d.CustID = cls.CustID
							AND (cs.IsParallelParentID = 1 OR IsMultiCateIDSameParentID = 1)
						);
    
	DELETE d
    FROM Temp_PA AS t
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS d ON t.TVSRequestID = d.TVSRequestID AND t.CustID = d.CustID
	WHERE IFNULL(t.TVSRequestID,0) <> 0
		AND (d.IsFromCTS = 0 AND d.IsFromTW = 0 AND d.IsFromAI = 0 AND d.IsFromImperva = 0)
		AND NOT EXISTS (SELECT 1
						FROM CTS_DataCenter.CTSCustomerClassification AS cls
							INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = cls.CategoryID
						WHERE d.CustID = cls.CustID
							AND (cs.IsParallelParentID = 1 OR IsMultiCateIDSameParentID = 1)
						);
      
	/* REMOVE FROM CUSTOMER EVIDENCE  */ 
    DELETE d
    FROM Temp_ExistedEvidence AS t
		INNER JOIN CTS_DataCenter.CustEvidence AS d ON t.CTSCustID = d.CTSCustID 
			AND (t.EvidenceID_Credit = d.EvidenceID OR t.EvidenceID_Licensee = d.EvidenceID)
	WHERE d.Level = 0;    		
	
    /* REMOVE AFFECTED EVIDENCE  */ 
    INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueRemove (CTSCustID,EvidenceID,Created)
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
	INSERT INTO CTS_DataCenter.TVSVoidRequest (TVSRequestID,CustID,ReasonID,CreatedBy,IsParlay,SportType,IssueTypeID,RequestTypeID)
	SELECT 	t.TVSRequestID,t.CustID,t.ReasonID,t.CreatedBy,t.IsParlay,t.SportType,t.IssueTypeID,t.RequestTypeID
		,	CASE WHEN c.CustomerClassName = 'Robot' THEN CONST_TVSRequestTypeID_ROBOT ELSE CONST_TVSRequestTypeID_PA END AS RequestTypeID
    FROM Temp_PA AS t
		INNER JOIN CTS_DataCenter.CustomerCategory AS c ON t.CategoryID = c.CategoryID
															AND t.ReasonID = c.ReasonID
	WHERE t.IsFromTVS = 1;
	
END$$
DELIMITER ;