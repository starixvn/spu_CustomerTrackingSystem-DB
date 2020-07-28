DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_Task_CountAssociatedAccountNewAssociation $$
CREATE PROCEDURE CTS_DataCenter.CTS_DC_Task_CountAssociatedAccountNewAssociation()
BEGIN
/*
	Created: 20200706@Long.Luu
	Task: Task to Count Associated Account New Association
	DB: CTS_DataCenter
  
	Revisions:
		- 20200706@Long.Luu: created  [Redmine ID: #134652]

	Param's Explanation:
*/   
		DECLARE LastScannedCTSAssDevID		BIGINT UNSIGNED;
        DECLARE CurrentMaxCTSAssDevID		BIGINT UNSIGNED;
        SET @CurrentScanTime				= NOW();
        SET @CurrentScanDate				= CURRENT_DATE();
        SET @DataDateRange					= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -5 DAY));
        
        DROP TEMPORARY TABLE IF EXISTS TmpAccountDevice;
		CREATE TEMPORARY TABLE TmpAccountDevice (
				CTSCustID 		BIGINT UNSIGNED
            ,	DCSDeviceID		BIGINT 
            ,	INDEX 			IX_TmpAccountDevice_DCSDeviceID(DCSDeviceID)
		);
        
        DROP TEMPORARY TABLE IF EXISTS TmpAssociations;
		CREATE TEMPORARY TABLE TmpAssociations (
				SourceCTSCustID 		BIGINT UNSIGNED
            ,	TargetCTSCustID 		BIGINT UNSIGNED
            ,	AssociationDevID 		BIGINT UNSIGNED
            ,	PRIMARY KEY 	PK_TmpAssociations_SourceCTSCustIDTargetCTSCustID(SourceCTSCustID,TargetCTSCustID,AssociationDevID)
		);
        
        DROP TEMPORARY TABLE IF EXISTS TmpHistoricalAssociations;
		CREATE TEMPORARY TABLE TmpHistoricalAssociations (
				SourceCTSCustID 		BIGINT UNSIGNED
            ,	TargetCTSCustID 		BIGINT UNSIGNED
            ,	PRIMARY KEY 	PK_TmpHistoricalAssociations_SourceCTSCustIDTargetCTSCustID(SourceCTSCustID,TargetCTSCustID)
		);
        
        SET SQL_SAFE_UPDATES = 0;
        
        # Delete old data in AssociatedAccountNewAssociation
        DELETE FROM CTS_DataCenter.AssociatedAccountNewAssociation
        WHERE CreatedDate < @DataDateRange;
    
		# Get last scanned CTSAssDevID value
        SELECT CAST(s.ParameterValue AS UNSIGNED)
        INTO LastScannedCTSAssDevID
        FROM CTS_DataCenter.SystemParameter AS s
        WHERE s.ParameterID = 1;
        
        # Get current max CTSAssDevID value
        SELECT MAX(a.CTSAssDevID)
        INTO CurrentMaxCTSAssDevID
        FROM CTS_DataCenter.AssociationByDevice AS a;
        
        # Get devices of AssociatedAccountMonitor
        INSERT INTO TmpAccountDevice(CTSCustID, DCSDeviceID)
        SELECT a.CTSCustID, a.DCSDeviceID
        FROM CTS_DataCenter.AssociationByDevice AS a	
			INNER JOIN CTS_DataCenter.AssociatedAccountMonitor AS m ON a.CTSCustID = m.CTSCustID;
            
		# Get all associated accounts
        INSERT INTO TmpAssociations(SourceCTSCustID, TargetCTSCustID, AssociationDevID)
        SELECT t.CTSCustID, a.CTSCustID, a.CTSAssDevID
        FROM CTS_DataCenter.AssociationByDevice AS a
			INNER JOIN TmpAccountDevice AS t ON a.DCSDeviceID = t.DCSDeviceID
		WHERE a.CTSAssDevID <= CurrentMaxCTSAssDevID AND a.CTSCustID <> t.CTSCustID;
        
        # Get all historical associated accounts
        INSERT INTO TmpHistoricalAssociations(SourceCTSCustID, TargetCTSCustID)
        SELECT DISTINCT t.SourceCTSCustID, t.TargetCTSCustID
        FROM TmpAssociations AS t
		WHERE t.AssociationDevID <= LastScannedCTSAssDevID;
        
        # Remove unused data
        DELETE t
        FROM TmpAssociations AS t
			INNER JOIN TmpHistoricalAssociations AS h ON (t.SourceCTSCustID = h.SourceCTSCustID AND t.TargetCTSCustID = h.TargetCTSCustID) 
				OR (t.SourceCTSCustID = h.TargetCTSCustID AND t.TargetCTSCustID = h.SourceCTSCustID)
		WHERE t.AssociationDevID > LastScannedCTSAssDevID;
        
        DELETE FROM TmpAssociations
        WHERE AssociationDevID <= LastScannedCTSAssDevID;
        
        # Count new association for AssociatedAccountMonitor
        INSERT INTO CTS_DataCenter.AssociatedAccountNewAssociation(CTSCustID, UserName, NewAssCount, CreatedDate, CreatedTime)
        SELECT 	a.SourceCTSCustID
			,	c.UserName
			, 	COUNT(DISTINCT a.TargetCTSCustID) AS NewAssCount
            ,	@CurrentScanDate
            ,	@CurrentScanTime
        FROM TmpAssociations AS a
            INNER JOIN CTS_DataCenter.CTSCustomer AS c ON a.SourceCTSCustID = c.CTSCustID
        GROUP BY a.SourceCTSCustID, c.UserName;
        
        # Remove the useless data
        DELETE a
        FROM CTS_DataCenter.AssociatedAccountNewAssociation AS a
			LEFT JOIN CTS_DataCenter.AssociatedAccountMonitor AS m ON a.CTSCustID = m.CTSCustID
		WHERE m.CTSCustID IS NULL;
        
        # Update last scanned CTSAssDevID value
        UPDATE CTS_DataCenter.SystemParameter
        SET ParameterValue = CAST(CurrentMaxCTSAssDevID AS CHAR)
        WHERE ParameterID = 1;
	END$$
DELIMITER ;