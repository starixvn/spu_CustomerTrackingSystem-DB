/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_RemoveOldEvidenceForInsertMultiple`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_RemoveOldEvidenceForInsertMultiple`(IN ip_CTSCustIDs json,IN ip_SessionId bigint,IN ip_IsRollback tinyint,IN ip_IsClearLog tinyint,OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20200825@Roger.Le
		Task:		Evidence Upload - Overrite the data
		DB:			CTS_DataCenter
		Original:

		Revisions: 
		   - 20200825@Roger.Le [Redmine ID: 137551]: Created
		   - 20201111@Irena.Vo [Redmine ID: #145027]: Enhance logic Insert History for Evidence Category
		   - 20201125@Irena.Vo [Redmine ID: #141563]: Move flow sync Evidence to Category
		   - 20201130@Irena.Vo [Redmine ID: #141563]: Enhance logic Insert new evidence (remove existed evidence category before)
	*/
    
    # Handle error
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    IF(ip_IsClearLog) THEN
		BEGIN
			# Remove log data
            DELETE FROM CTS_DataCenter.CustEvidenceLog
			WHERE SessionId = ip_SessionId;
            
            LEAVE sp;
        END;
    END IF;
    
     DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccount;    
	CREATE TEMPORARY TABLE Temp_MultipleAccount 
	(	 
			CTSCustID		BIGINT UNSIGNED
		,   CustID          BIGINT UNSIGNED
        ,   SubscriberID    INT UNSIGNED
		, 	PRIMARY KEY	Temp_MultipleAccount_CTSCustID(CTSCustID) 
	);      
	
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationException;
	CREATE TEMPORARY TABLE Temp_AssociationException(
			FromCTSCustID 	BIGINT UNSIGNED
		,	ToCTSCustID 	BIGINT UNSIGNED
		, 	PRIMARY KEY	Temp_AssociationException_FromCTSCustID_ToCTSCustID(FromCTSCustID,ToCTSCustID)
	);
	
	DROP  TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
	CREATE TEMPORARY TABLE Temp_AffectedDevices(
			CTSCustID		BIGINT UNSIGNED     
		,	DCSDeviceID		BIGINT UNSIGNED
		, 	PRIMARY KEY	Temp_AffectedDevices_CTSCustID_DCSDeviceID(CTSCustID,DCSDeviceID) 
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence;
	CREATE TEMPORARY TABLE Temp_CustEvidence(
			CTSCustID 	BIGINT UNSIGNED
		,	FromCustID 	BIGINT UNSIGNED
		,   INDEX		IX_Temp_CustEvidence_CTSCustID_FromCustID(CTSCustID, FromCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceList;
	CREATE TEMPORARY TABLE Temp_CustEvidenceList(
			CTSCustID 	BIGINT UNSIGNED
		,	EvidenceID 	BIGINT UNSIGNED
		,   INDEX		IX_Temp_CustEvidenceList_CTSCustID_EvidenceID(CTSCustID,EvidenceID)
	);
	
	
	INSERT INTO Temp_MultipleAccount(CTSCustID)
	SELECT 	temp.CTSCustID
	FROM JSON_TABLE(ip_CTSCustIDs,
		 "$[*]" COLUMNS(
			  CTSCustID 	BIGINT UNSIGNED		PATH "$.CTSCustID"
		 )) AS temp;

	/*GET CUSTOMER INFO*/
    UPDATE 		Temp_MultipleAccount AS t
	INNER JOIN 	CTS_DataCenter.CTSCustomer AS c ON t.CTSCustID = c.CTSCustID AND c.CustSubID = 0
    SET 		t.CustID = c.CustID
			,	t.SubscriberID = c.SubscriberID;
    
	INSERT INTO Temp_AffectedDevices(CTSCustID, DCSDeviceID)
	SELECT DISTINCT t.CTSCustID, a.DCSDeviceID
	FROM CTS_DataCenter.AssociationByDevice AS a    
		INNER JOIN Temp_MultipleAccount AS t ON a.CTSCustID = t.CTSCustID;
	 
	INSERT INTO Temp_AssociationException(FromCTSCustID, ToCTSCustID)
	SELECT DISTINCT t.CTSCustID
		,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order ELSE e.LeastCTSCustID_Order END
	FROM CTS_DataCenter.CustException AS e
		INNER JOIN Temp_MultipleAccount AS t ON e.LeastCTSCustID_Order = t.CTSCustID
													OR e.GreatestCTSCustID_Order = t.CTSCustID;
	
   # Get all association follow devices
	INSERT INTO Temp_CustEvidence(CTSCustID, FromCustID)
		SELECT 	DISTINCT a.CTSCustID
						, t.CTSCustID
				FROM Temp_MultipleAccount AS t
					INNER JOIN Temp_AffectedDevices AS d ON t.CTSCustID = d.CTSCustID
					INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
					LEFT JOIN Temp_AssociationException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	WHERE a.CTSCustID <> d.CTSCustID		
    	AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    IF(!ip_IsRollback) THEN
		BEGIN
			 # Save log
            INSERT IGNORE INTO CTS_DataCenter.CustEvidenceLog(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy, SessionId)
				SELECT cus.CTSCustID, cus.EvidenceID, cus.Remark, cus.Level, cus.FromCustID, cus.CreatedDate, cus.CreatedBy, ip_SessionId
				FROM Temp_MultipleAccount AS tmp
					INNER JOIN CTS_DataCenter.CustEvidence as cus ON tmp.CTSCustID = cus.CTSCustID AND cus.Level = 0;
                    
            INSERT IGNORE INTO CTS_DataCenter.CustEvidenceLog(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy, SessionId)
				SELECT cus.CTSCustID, cus.EvidenceID, cus.Remark, cus.Level, cus.FromCustID, cus.CreatedDate, cus.CreatedBy, ip_SessionId
				FROM Temp_CustEvidence AS tmp
					INNER JOIN CTS_DataCenter.CustEvidence as cus ON tmp.CTSCustID = cus.CTSCustID AND cus.FromCustID = tmp.FromCustID;
        END;
    END IF;
    
    -- Get Evidence List for customers before remove
	INSERT INTO Temp_CustEvidenceList
    SELECT DISTINCT temp.CTSCustID, evd.EvidenceID
    FROM Temp_MultipleAccount AS temp 
    INNER JOIN CustEvidence AS evd ON temp.CTSCustID = evd.FromCustID;
    
	DELETE evd
    FROM  CustEvidence AS evd
    INNER JOIN  Temp_MultipleAccount AS temp ON temp.CTSCustID = evd.FromCustID;
    
    IF(ip_IsRollback) THEN
		BEGIN
            # Rollback data
            INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
				SELECT log.CTSCustID, log.EvidenceID, log.Remark, log.Level, log.FromCustID, log.CreatedDate, log.CreatedBy
				FROM CTS_DataCenter.CustEvidenceLog log
                WHERE log.SessionId = ip_SessionId;
                
            # Remove log data
            DELETE FROM CTS_DataCenter.CustEvidenceLog
			WHERE SessionId = ip_SessionId;
        END;
    END IF;
    
	-- Return CTSCustID, CustID, SubscriberID, EvidenceID, 2 (ActionType)
    SELECT DISTINCT temp.CTSCustId
           , temp.CustId
           , temp.SubscriberId
           , evd.EvidenceId
           , 2 AS ActionType-- remove
	FROM Temp_MultipleAccount AS temp
    INNER JOIN Temp_CustEvidenceList AS evd ON evd.CTSCustID = temp.CTSCustID;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidenceList;
	DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccount;
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationException;
	DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
	DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence; 
    
END$$

DELIMITER ;