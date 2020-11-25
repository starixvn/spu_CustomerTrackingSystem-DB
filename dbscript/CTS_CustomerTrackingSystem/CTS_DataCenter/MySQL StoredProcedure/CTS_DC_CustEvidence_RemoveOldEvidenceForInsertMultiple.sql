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
    
    DROP TEMPORARY TABLE IF EXISTS tmpMultipleAccount;    
	CREATE TEMPORARY TABLE tmpMultipleAccount 
	(	 
			CTSCustID		BIGINT UNSIGNED
		, 	PRIMARY KEY	tmpMultipleAccount(CTSCustID) 
	);      
	
	DROP TEMPORARY TABLE IF EXISTS tmpAssociationException;
	CREATE TEMPORARY TABLE tmpAssociationException(
			FromCTSCustID 	BIGINT UNSIGNED
		,	ToCTSCustID 	BIGINT UNSIGNED
		, 	PRIMARY KEY	tmpAssociationException(FromCTSCustID,ToCTSCustID)
	);
	
	DROP  TEMPORARY TABLE IF EXISTS tmpAffectedDevices;
	CREATE TEMPORARY TABLE tmpAffectedDevices(
			CTSCustID		BIGINT UNSIGNED     
		,	DCSDeviceID		BIGINT UNSIGNED
		, 	PRIMARY KEY	tmpAffectedDevices(CTSCustID,DCSDeviceID) 
	);
	
	DROP TEMPORARY TABLE IF EXISTS tmpCustEvidence;
	CREATE TEMPORARY TABLE tmpCustEvidence(
			CTSCustID 	BIGINT UNSIGNED
		,	FromCustID 	BIGINT UNSIGNED
		, INDEX		IX_CustEvidence(CTSCustID, FromCustID)
	);
	
	INSERT INTO tmpMultipleAccount(CTSCustID)
	SELECT 	tmpTable.CTSCustID
	FROM JSON_TABLE(ip_CTSCustIDs,
		 "$[*]" COLUMNS(
			  CTSCustID 	BIGINT UNSIGNED		PATH "$.CTSCustID"
		 )) AS tmpTable;
 
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	INSERT INTO tmpAffectedDevices(CTSCustID, DCSDeviceID)
	SELECT DISTINCT t.CTSCustID, a.DCSDeviceID
	FROM CTS_DataCenter.AssociationByDevice AS a    
		INNER JOIN tmpMultipleAccount AS t ON a.CTSCustID = t.CTSCustID;
	 
	INSERT INTO tmpAssociationException(FromCTSCustID, ToCTSCustID)
	SELECT DISTINCT t.CTSCustID
		,	CASE WHEN e.LeastCTSCustID_Order = t.CTSCustID THEN e.GreatestCTSCustID_Order ELSE e.LeastCTSCustID_Order END
	FROM CTS_DataCenter.CustException AS e
		INNER JOIN tmpMultipleAccount AS t ON e.LeastCTSCustID_Order = t.CTSCustID
													OR e.GreatestCTSCustID_Order = t.CTSCustID;
	
   # Get all association follow devices
	INSERT INTO tmpCustEvidence(CTSCustID, FromCustID)
		SELECT 	DISTINCT a.CTSCustID
						, t.CTSCustID
				FROM tmpMultipleAccount AS t
					INNER JOIN tmpAffectedDevices AS d ON t.CTSCustID = d.CTSCustID
					INNER JOIN CTS_DataCenter.AssociationByDevice AS a ON a.DCSDeviceID = d.DCSDeviceID
					LEFT JOIN tmpAssociationException AS e ON t.CTSCustID = e.FromCTSCustID AND a.CTSCustID = e.ToCTSCustID
	WHERE a.CTSCustID <> d.CTSCustID		
    	AND (e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL);
    
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    IF(!ip_IsRollback) THEN
		BEGIN
			 # Save log
            INSERT IGNORE INTO CTS_DataCenter.CustEvidenceLog(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy, SessionId)
				SELECT cus.CTSCustID, cus.EvidenceID, cus.Remark, cus.Level, cus.FromCustID, cus.CreatedDate, cus.CreatedBy, ip_SessionId
				FROM tmpMultipleAccount tmp
					INNER JOIN CTS_DataCenter.CustEvidence as cus ON tmp.CTSCustID = cus.CTSCustID AND cus.Level = 0;
                    
            INSERT IGNORE INTO CTS_DataCenter.CustEvidenceLog(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy, SessionId)
				SELECT cus.CTSCustID, cus.EvidenceID, cus.Remark, cus.Level, cus.FromCustID, cus.CreatedDate, cus.CreatedBy, ip_SessionId
				FROM tmpCustEvidence tmp
					INNER JOIN CTS_DataCenter.CustEvidence as cus ON tmp.CTSCustID = cus.CTSCustID AND cus.FromCustID = tmp.FromCustID;
        END;
    END IF;
    
	DELETE cus  FROM CTS_DataCenter.CustEvidence cus INNER JOIN tmpMultipleAccount tmp
	WHERE  cus.CTSCustID = tmp.CTSCustID
			AND cus.Level = 0;
			
	DELETE cus  FROM CTS_DataCenter.CustEvidence cus INNER JOIN tmpCustEvidence tmp 
	WHERE  tmp.CTSCustID = cus.CTSCustID AND cus.FromCustID = tmp.FromCustID; 
    
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
    
	-- Web will return CTSCustID, CustID, SubscriberID, EvidenceID, 2 (ActionType) from sp ValidateInput file
    
	DROP TEMPORARY TABLE IF EXISTS tmpMultipleAccount;
	DROP TEMPORARY TABLE IF EXISTS tmpAssociationException;
	DROP TEMPORARY TABLE IF EXISTS tmpAffectedDevices;
	DROP TEMPORARY TABLE IF EXISTS tmpCustEvidence;
END$$

DELIMITER ;