USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustEvidence_RemoveOldEvidenceForInsertMultiple`;

DELIMITER $$
USE `CTS_DataCenter`$$
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
	*/
	DECLARE		lv_CreatedDateTime 	DATETIME 		DEFAULT CURRENT_TIME();
    DECLARE     lv_CreatedBy        INT DEFAULT     10278938;
    
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
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY
	);      
	
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationException;
	CREATE TEMPORARY TABLE Temp_AssociationException(
			FromCTSCustID 	BIGINT UNSIGNED
		,	ToCTSCustID 	BIGINT UNSIGNED
		, 	PRIMARY KEY	PK_Temp_AssociationException(FromCTSCustID,ToCTSCustID)
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
	CREATE TEMPORARY TABLE Temp_AffectedDevices(
			CTSCustID		BIGINT UNSIGNED     
		,	DCSDeviceID		BIGINT UNSIGNED
		, 	PRIMARY KEY	PK_Temp_AffectedDevices(CTSCustID,DCSDeviceID) 
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence;
	CREATE TEMPORARY TABLE Temp_CustEvidence(
			CTSCustID 	BIGINT UNSIGNED
		,	FromCustID 	BIGINT UNSIGNED
		,   INDEX		IX_Temp_CustEvidence(CTSCustID, FromCustID)
	);
	
	INSERT INTO Temp_MultipleAccount(CTSCustID)
	SELECT 	temp.CTSCustID
	FROM JSON_TABLE(ip_CTSCustIDs,
		 "$[*]" COLUMNS(
			  CTSCustID 	BIGINT UNSIGNED		PATH "$.CTSCustID"
		 )) AS temp;
 
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
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
    
    # Remove old evidence & category
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History
	(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT  DISTINCT c.CustID
			, 	c.CTSCustID
			, 	NULL
			,   0
			,   lv_CreatedDateTime
			,   lv_CreatedBy
            ,   2
            ,   1
			,   DATE(lv_CreatedDateTime)
            , 0
            , 0
            , 0
            , 0
	FROM CTS_DataCenter.CTSCustomerClassification AS c
    INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.CategoryID = c.CategoryID
    INNER JOIN CustEvidence AS cus ON cus.EvidenceID = e.EvidenceID AND c.CTSCustID = cus.FromCustID
    INNER JOIN Temp_MultipleAccount AS tmp ON tmp.CTSCustID = c.CTSCustID;
    
	DELETE c
	FROM CTS_DataCenter.CTSCustomerClassification AS c
    INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.CategoryID = c.CategoryID
    INNER JOIN CustEvidence AS cus ON cus.EvidenceID = e.EvidenceID AND c.CTSCustID = cus.FromCustID
    INNER JOIN Temp_MultipleAccount AS tmp ON tmp.CTSCustID = c.CTSCustID;
    
	DELETE cus  FROM CTS_DataCenter.CustEvidence AS cus 
    INNER JOIN Temp_MultipleAccount AS tmp
	WHERE  cus.CTSCustID = tmp.CTSCustID
			AND cus.Level = 0;
			
	DELETE cus  FROM CTS_DataCenter.CustEvidence AS cus 
    INNER JOIN Temp_CustEvidence AS tmp 
	WHERE  tmp.CTSCustID = cus.CTSCustID AND cus.FromCustID = tmp.FromCustID; 
    
    IF(ip_IsRollback) THEN
		BEGIN
            # Rollback data
            INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
				SELECT log.CTSCustID, log.EvidenceID, log.Remark, log.Level, log.FromCustID, log.CreatedDate, log.CreatedBy
				FROM CTS_DataCenter.CustEvidenceLog AS log
                WHERE log.SessionId = ip_SessionId;
                
            # Remove log data
            DELETE FROM CTS_DataCenter.CustEvidenceLog
			WHERE SessionId = ip_SessionId;
        END;
    END IF;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_MultipleAccount;
	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationException;
	DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
	DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence; 
     
END$$

DELIMITER ;