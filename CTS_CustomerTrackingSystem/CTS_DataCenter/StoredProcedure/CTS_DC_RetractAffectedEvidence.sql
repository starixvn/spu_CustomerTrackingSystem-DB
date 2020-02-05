DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_RetractAffectedEvidence $$

CREATE PROCEDURE CTS_DC_RetractAffectedEvidence (
	IN ip_CTSCustID BIGINT,        
    IN ip_EvidenceID SMALLINT,	
    IN ip_UserID INT)
BEGIN
	/*
		Created:	20200204@Thai
		Task:		Retract an affected evidence for a customer then remove his affected evidence [Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):			
        
        CALL CTS_DC_RetractAffectedEvidence (127512, 5, 8)
	*/    
     
	DECLARE		vr_CreatedDate	DATETIME;	
    DECLARE		vr_SPName 	VARCHAR(100) 	DEFAULT 'CTS_DC_RetractAffectedEvidence';    
    SET	vr_CreatedDate = CURRENT_TIME();
    	
	IF NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CustRetractEvidence
					WHERE CTSCustID = ip_CTSCustID										
						AND EvidenceID = ip_EvidenceID) THEN
	
		#=====INSERT RETRACT EVIDENCE==========================
		INSERT INTO CTS_DataCenter.CustRetractEvidence( CTSCustID, EvidenceID, CreatedDate)
		VALUES (ip_CTSCustID, ip_EvidenceID, vr_CreatedDate);		
                
	END IF;
    
    #=====REMOVE AFFECTED EVIDENCE==========================
	SET SQL_SAFE_UPDATES = 0;
	
	DELETE FROM CTS_DataCenter.CustEvidence
	WHERE CTSCustID = ip_CTSCustID
		AND EvidenceID = ip_EvidenceID
		AND Level = 2;
	
	SET SQL_SAFE_UPDATES = 1;
    		
    #=====LOG==========================
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(5, vr_SPName, CONCAT('Retract Affected Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_EvidenceID = ', ip_EvidenceID), vr_CreatedDate, ip_UserID);
    
END$$
DELIMITER ;