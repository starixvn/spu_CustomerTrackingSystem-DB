DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_AddEvidence $$

CREATE PROCEDURE CTS_DC_AddEvidence (
	IN ip_CTSCustID BIGINT,        
    IN ip_EvidenceID SMALLINT,
    IN ip_Remark VARCHAR(500),    
    IN ip_UserID INT
)
    
proc_label: BEGIN
	/*
		Created:	20200204@Thai
		Task:		Add a flagged evidence and affected evidences for associated customers[Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original:

		Revisions:
		   - 20200225@Lex: Fix cocurrency issue when inserting
		   - 20200227@Lex: Fix exclude exception
           - 20200513@Lex: Fix wrong subID mapping of level 2
			[20200807@Casey.Huynh]:[138925] Chagne CustEvidence Structure for Cross Subscriber : Remove SubscriberID and IsCreatedByMaster
        
		Param's Explanation (filtered by):			
        
        CALL CTS_DC_AddEvidence (11113, 2, 5, 'test by Thai', 8, TRUE)
	*/    
      
    DECLARE		vr_CreatedDate	DATETIME;
    DECLARE		vr_SPName 	VARCHAR(100) 	DEFAULT 'CTS_DC_AddEvidence';        
    
    SET	vr_CreatedDate = CURRENT_TIME();
        	
	IF NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomer
			WHERE CTSCustID = ip_CTSCustID) THEN
		LEAVE proc_label;
	END IF;
    
    IF EXISTS (SELECT 1 FROM CTS_DataCenter.CustEvidence
				WHERE CTSCustID = ip_CTSCustID										
					AND EvidenceID = ip_EvidenceID
                    AND Level = 0) THEN
		LEAVE proc_label;
	END IF;
    
	DROP TABLE IF EXISTS tmpExclusion;
    CREATE TEMPORARY TABLE tmpExclusion(
		CTSCustID BIGINT
	);
    
  #======INSERT FLAGGED EVIDENCE=================================    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	VALUES (ip_CTSCustID, ip_EvidenceID, ip_Remark, 0, ip_CTSCustID, vr_CreatedDate, ip_UserID);
	
	#=====INSERT AFFECTED EVIDENCE==========================
    DROP TABLE IF EXISTS tmpAffectedDevices;
    CREATE TEMPORARY TABLE tmpAffectedDevices(
		DCSDeviceID BIGINT
	);
	
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
    
    INSERT INTO tmpAffectedDevices(DCSDeviceID)
    SELECT DISTINCT ass.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice ass    
    WHERE ass.CTSCustID = ip_CTSCustID
		AND  ass.SubscriberID = ip_SubscriberID;

	#======GET EXCEPTION LIST=================================
    INSERT INTO tmpExclusion(CTSCustID)
    SELECT DISTINCT CASE WHEN LeastCTSCustID_Order = ip_CTSCustID THEN GreatestCTSCustID_Order ELSE LeastCTSCustID_Order END
    FROM CTS_DataCenter.CustException
    WHERE LeastCTSCustID_Order = ip_CTSCustID
    OR GreatestCTSCustID_Order = ip_CTSCustID;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT DISTINCT ass.CTSCustID, ip_EvidenceID, ip_Remark, 2, ip_CTSCustID, vr_CreatedDate, ip_UserID
    FROM CTS_DataCenter.AssociationByDevice AS ass
    INNER JOIN CTS_DataCenter.CTSCustomer cust
		   ON (cust.CTSCustID = ass.CTSCustID)
    INNER JOIN tmpAffectedDevices AS dev    
		   ON (ass.DCSDeviceID = dev.DCSDeviceID)
	WHERE ass.CTSCustID <> ip_CTSCustID		
    	AND ass.CTSCustID NOT IN (SELECT CTSCustID FROM tmpExclusion);
    
    #=====LOG==========================
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, vr_SPName, CONCAT('Insert Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_EvidenceID = ', ip_EvidenceID), vr_CreatedDate, ip_UserID);
    
END$$
DELIMITER ;