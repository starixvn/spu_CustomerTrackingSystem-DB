DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_RestoreAffectedEvidence $$

CREATE PROCEDURE CTS_DC_RestoreAffectedEvidence (
	IN ip_CTSCustID BIGINT,        
    IN ip_EvidenceID SMALLINT,	
    IN ip_UserID INT)
    
BEGIN
	/*
		Created:	20200204@Thai
		Task:		The customer will be affected with this evidence [Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):			
        
        CALL CTS_DC_RestoreAffectedEvidence (11113, 5, 8)
	*/    
      
    DECLARE		vr_CreatedDate	DATETIME;	
    DECLARE		vr_SPName 	VARCHAR(100) 	DEFAULT 'CTS_DC_RestoreAffectedEvidence';        
    SET	vr_CreatedDate = CURRENT_TIME();
    
    	
	#=====REMOVE RETRACT EVIDENCE==========================
	DELETE FROM CTS_DataCenter.CustRetractEvidence
	WHERE CTSCustID = ip_CTSCustID										
		AND EvidenceID = ip_EvidenceID;	
    	
    #=====LOG==========================
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(6, vr_SPName, CONCAT('Restore Affected Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_EvidenceID = ', ip_EvidenceID), vr_CreatedDate, ip_UserID);
    
END$$
DELIMITER ;