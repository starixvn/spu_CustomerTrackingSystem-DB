DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_RemoveOldEvidence $$


CREATE PROCEDURE `CTS_DC_RemoveOldEvidence`(
	IN ip_CTSCustIDs 			JSON    
	,IN ip_RemoveLog 			BOOLEAN
    
    ,OUT op_ErrorMessage 		VARCHAR(200)
)
sp: BEGIN
	/*
		Created:	20200825@Roger.Le
		Task:		Evidence Upload - Overrite the data
		DB:			CTS_DataCenter
		Original:

		Revisions:
		   - 20200825@Roger.Le: Created [Redmine ID: 137551]
	*/
    
     # Handle error
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    IF(ip_RemoveLog) THEN
		BEGIN
			TRUNCATE TABLE CustEvidenceLog;
            SET op_ErrorMessage = "Remove log success";
			LEAVE sp;
        END;
    ELSE
		BEGIN
			DROP TEMPORARY TABLE IF EXISTS tmpMultipleAccount;    
			CREATE TEMPORARY TABLE tmpMultipleAccount 
			(	 
					CTSCustID		BIGINT UNSIGNED
				, 	PRIMARY KEY	tmpMultipleAccount(CTSCustID) 
			);      
			
			DROP TABLE IF EXISTS tmpAssociationException;
			CREATE TEMPORARY TABLE tmpAssociationException(
					FromCTSCustID 	BIGINT UNSIGNED
				,	ToCTSCustID 	BIGINT UNSIGNED
				, 	PRIMARY KEY	tmpAssociationException(FromCTSCustID,ToCTSCustID)
			);
			
			DROP TABLE IF EXISTS tmpAffectedDevices;
			CREATE TEMPORARY TABLE tmpAffectedDevices(
					CTSCustID		BIGINT UNSIGNED     
				,	DCSDeviceID		BIGINT UNSIGNED
				, 	PRIMARY KEY	tmpAffectedDevices(CTSCustID,DCSDeviceID) 
			);
            
			DROP TABLE IF EXISTS tmpCustEvidence;
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
         
			SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;       
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
			WHERE e.FromCTSCustID IS NULL OR e.ToCTSCustID IS NULL; 
            
            # Save log
            SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
            INSERT IGNORE INTO CTS_DataCenter.CustEvidenceLog(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
				SELECT cus.CTSCustID, cus.EvidenceID, cus.Remark, cus.Level, cus.FromCustID, cus.CreatedDate, cus.CreatedBy
				FROM tmpCustEvidence tmp
					INNER JOIN CTS_DataCenter.CustEvidence as cus ON tmp.CTSCustID = cus.CTSCustID AND cus.FromCustID = tmp.FromCustID;
                    
            # Remove old evidence
			DELETE cus  FROM CTS_DataCenter.CustEvidence cus INNER JOIN tmpCustEvidence tmp
            WHERE  tmp.CTSCustID = cus.CTSCustID AND cus.FromCustID = tmp.FromCustID;
            
            SET op_ErrorMessage = "Remove evidence success";

            # Begin: Cleanup
            DROP TEMPORARY TABLE tmpMultipleAccount;
			DROP TEMPORARY TABLE tmpAssociationException;
			DROP TEMPORARY TABLE tmpAffectedDevices;
			DROP TEMPORARY TABLE tmpCustEvidence;
            # End: Cleanup
            
            LEAVE sp;
        END;
    END IF;
     
END$$
DELIMITER ;