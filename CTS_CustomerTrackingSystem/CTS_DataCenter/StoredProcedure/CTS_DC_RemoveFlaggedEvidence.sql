DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_RemoveFlaggedEvidence $$

CREATE PROCEDURE CTS_DC_RemoveFlaggedEvidence (
	IN ip_CTSCustID BIGINT,        
    IN ip_EvidenceID SMALLINT,	
    IN ip_UserID INT)
BEGIN
	/*
		Created:	20200204@Thai
		Task:		Remove a flagged evidence [Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):			
        
        CALL CTS_DC_RemoveFlaggedEvidence (11113, 5, 8)
	*/    
     
	DECLARE		vr_CreatedDate	DATETIME;	
    DECLARE		vr_SPName 	VARCHAR(100) 	DEFAULT 'CTS_DC_RemoveFlaggedEvidence';    
    SET	vr_CreatedDate = CURRENT_TIME();
    	
	SET SQL_SAFE_UPDATES = 0;
    
    DELETE FROM CTS_DataCenter.CustEvidence
	WHERE CTSCustID = ip_CTSCustID		
		AND EvidenceID = ip_EvidenceID
        AND Level = 0;
        
	SET SQL_SAFE_UPDATES = 1;
        
    #=====LOG==========================
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(4, vr_SPName, CONCAT('Remove Flagged Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_EvidenceID = ', ip_EvidenceID), vr_CreatedDate, ip_UserID);
    
END$$
DELIMITER ;