DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_CustEvidence_RemoveFlagged $$

CREATE PROCEDURE CTS_DC_CustEvidence_RemoveFlagged (
	IN ip_CTSCustID 		BIGINT,        
	IN ip_EvidenceID 		SMALLINT,	
	IN ip_UserID 			INT,
    
    OUT op_ErrorMessage 	VARCHAR(200)
)
BEGIN
	/*
		Created:	20200204@Thai
		Task:		Remove a flagged evidence [Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200225@Lex: Fix remove flag evidence also associted evidence (level 2)
			- 20201013@Long.Luu [Redmine ID: #141756]: Sync Evidence to Category
        
		Param's Explanation (filtered by):			
        
        CALL CTS_DC_RemoveFlaggedEvidence (11113, 5, 8)
	*/    
     
	DECLARE		lv_CreatedDate		DATETIME;	
    DECLARE		lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_CustEvidence_RemoveFlagged';  
    DECLARE		lv_IsSyncEvi2Cate	VARCHAR(1) 		DEFAULT '';  
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    SET			lv_CreatedDate 		= CURRENT_TIME();
    	
	SET SQL_SAFE_UPDATES = 0;
    
    DELETE FROM CTS_DataCenter.CustEvidence
	WHERE FromCustID = ip_CTSCustID		
		AND EvidenceID = ip_EvidenceID;
        
	# Sync Evidence to Category
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
    IF(lv_IsSyncEvi2Cate = '1') THEN
		DELETE c
        FROM CTS_DataCenter.CTSCustomerClassification AS c
			INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON c.CategoryID = e.CategoryID
		WHERE c.CTSCustID = ip_CTSCustID		
			AND e.EvidenceID = ip_EvidenceID;
    END IF;
        
	SET SQL_SAFE_UPDATES = 1;
        
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(4, lv_SPName, CONCAT('Remove Flagged Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_EvidenceID = ', ip_EvidenceID), lv_CreatedDate, ip_UserID);
    
END$$
DELIMITER ;