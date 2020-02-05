DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_AddEvidence $$

CREATE PROCEDURE CTS_DC_AddEvidence (
	IN ip_CTSCustID BIGINT,    
    IN ip_SubscriberID INT,
    IN ip_EvidenceID SMALLINT,
    IN ip_Remark VARCHAR(500),    
    IN ip_UserID INT,
    IN ip_IsCreatedByMaster BOOL)
    
proc_label: BEGIN
	/*
		Created:	20200204@Thai
		Task:		Add a flagged evidence and affected evidences for associated customers[Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):			
        
        CALL CTS_DC_AddEvidence (11113, 2, 5, 'test by Thai', 8, TRUE)
	*/    
      
    DECLARE		vr_CreatedDate	DATETIME;
    DECLARE		vr_SPName 	VARCHAR(100) 	DEFAULT 'CTS_DC_AddEvidence';        
    
    SET	vr_CreatedDate = CURRENT_TIME();
        	
    IF EXISTS (SELECT 1 FROM CTS_DataCenter.CustEvidence
				WHERE CTSCustID = ip_CTSCustID										
					AND EvidenceID = ip_EvidenceID
                    AND Level = 0) THEN
		LEAVE proc_label;
	END IF;
    
    #======INSERT FLAGGED EVIDENCE=================================    
	INSERT INTO CTS_DataCenter.CustEvidence(CTSCustID, SubscriberID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy, IsCreatedByMaster)
	VALUES (ip_CTSCustID, ip_SubscriberID, ip_EvidenceID, ip_Remark, 0, ip_CTSCustID, vr_CreatedDate, ip_UserID, ip_IsCreatedByMaster);
	
	#=====INSERT AFFECTED EVIDENCE==========================
    DROP TABLE IF EXISTS tmpAffectedDevices;
    CREATE TEMPORARY TABLE tmpAffectedDevices(
		DCSDeviceID BIGINT
	);
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
    
    INSERT INTO tmpAffectedDevices(DCSDeviceID)
    SELECT DISTINCT DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice
    WHERE CTSCustID = ip_CTSCustID
		AND SubscriberID = ip_SubscriberID;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
	INSERT INTO CTS_DataCenter.CustEvidence(CTSCustID, SubscriberID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy, IsCreatedByMaster)
    SELECT DISTINCT ass.CTSCustID, ip_SubscriberID, ip_EvidenceID, ip_Remark, 2, ip_CTSCustID, vr_CreatedDate, ip_UserID, ip_IsCreatedByMaster
    FROM CTS_DataCenter.AssociationByDevice AS ass
    INNER JOIN tmpAffectedDevices AS dev    
		   ON (ass.DCSDeviceID = dev.DCSDeviceID)
	WHERE ass.CTSCustID <> ip_CTSCustID		
		AND ass.CTSCustID NOT IN (SELECT ToCTSCustID
									FROM CTS_DataCenter.CustException AS exc
                                    WHERE exc.FromCTSCustID = ip_CTSCustID)
		AND ass.CTSCustID NOT IN (SELECT CTSCustID
									FROM CTS_DataCenter.CustRetractEvidence AS cre
                                    WHERE cre.EvidenceID = ip_EvidenceID);    	
    
    #=====LOG==========================
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, vr_SPName, CONCAT('Insert Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_SubscriberID = ', ip_SubscriberID, ';ip_EvidenceID = ', ip_EvidenceID), vr_CreatedDate, ip_UserID);
    
END$$
DELIMITER ;