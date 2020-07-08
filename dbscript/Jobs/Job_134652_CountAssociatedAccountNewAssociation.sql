/*
	Created: 20200706@Long.Luu
	Task: Job to Count Associated Account New Association
	DB: CTS_DataCenter
  
	Revisions:
		- 20200706@Long.Luu: created  [Redmine ID: #134652]

	Param's Explanation:  
	
*/

DELIMITER @@;

CREATE EVENT CTS_DataCenter.CTS_JOB_CountAssociatedAccountNewAssociation
	ON SCHEDULE
		EVERY 5 MINUTE
		STARTS '2020-06-30 04:00:00' ON COMPLETION PRESERVE ENABLE 
	DO BEGIN
		DECLARE LastScannedCTSAssDevID		BIGINT;
        DECLARE CurrentMaxCTSAssDevID		BIGINT;
        SET @CurrentScanTime				= NOW();
        SET @CurrentScanDate				= CURRENT_DATE();
        SET @DataDateRange					= DATE(DATE_ADD(CURRENT_DATE(), INTERVAL -5 DAY));
        
        DROP TEMPORARY TABLE IF EXISTS TmpAccountDevice;
		CREATE TEMPORARY TABLE TmpAccountDevice (
				CTSCustID 		BIGINT UNSIGNED
            ,	DCSDeviceID		BIGINT 
            ,	INDEX 			IX_TmpAccountDevice_DCSDeviceID(DCSDeviceID)
		);
        
        # Delete old data in AssociatedAccountNewAssociation
        DELETE FROM CTS_DataCenter.AssociatedAccountNewAssociation
        WHERE CreatedDate < @DataDateRange;
    
		# Get last scanned CTSAssDevID value
        SELECT u.AccountNewAssID
        INTO LastScannedCTSAssDevID
        FROM CTS_DataCenter.CTSUserNotificationParameter AS u
        WHERE u.UserID = 229;
        
        # Get current max CTSAssDevID value
        SELECT MAX(a.CTSAssDevID)
        INTO CurrentMaxCTSAssDevID
        FROM CTS_DataCenter.AssociationByDevice AS a;
        
        # Get devices of AssociatedAccountMonitor
        INSERT INTO TmpAccountDevice(CTSCustID, DCSDeviceID)
        SELECT a.CTSCustID, a.DCSDeviceID
        FROM CTS_DataCenter.AssociationByDevice AS a	
			INNER JOIN CTS_DataCenter.AssociatedAccountMonitor AS m ON a.CTSCustID = m.CTSCustID;
        
        # Count new association for AssociatedAccountMonitor
        INSERT INTO CTS_DataCenter.AssociatedAccountNewAssociation(CTSCustID, UserName, NewAssCount, CreatedDate, CreatedTime)
        SELECT 	t.CTSCustID
			,	c.UserName
			, 	COUNT(DISTINCT a.CTSCustID) AS NewAssCount
            ,	@CurrentScanDate
            ,	@CurrentScanTime
        FROM CTS_DataCenter.AssociationByDevice AS a
			INNER JOIN TmpAccountDevice AS t ON a.DCSDeviceID = t.DCSDeviceID
            INNER JOIN CTS_DataCenter.CTSCustomer AS c ON t.CTSCustID = c.CTSCustID
        WHERE a.CTSAssDevID > LastScannedCTSAssDevID AND a.CTSAssDevID <= CurrentMaxCTSAssDevID AND a.CTSCustID <> t.CTSCustID
        GROUP BY t.CTSCustID, c.UserName;
        
        # Remove the useless data
        DELETE a
        FROM CTS_DataCenter.AssociatedAccountNewAssociation AS a
			LEFT JOIN CTS_DataCenter.AssociatedAccountMonitor AS m ON a.CTSCustID = m.CTSCustID
		WHERE m.CTSCustID IS NULL;
        
        # Update last scanned CTSAssDevID value
        UPDATE CTS_DataCenter.CTSUserNotificationParameter
        SET AccountNewAssID = CurrentMaxCTSAssDevID
        WHERE UserID = 229;
	END;
    @@;
DELIMITER ;

        
        
        
        
