DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_CustEvidence_InsertSingle $$

CREATE PROCEDURE CTS_DC_CustEvidence_InsertSingle (
	IN 	ip_CTSCustID 		BIGINT,        
    IN 	ip_EvidenceID 		SMALLINT,
    IN	ip_Remark 			VARCHAR(500),    
    IN 	ip_UserID 			INT,
    
    OUT op_ErrorMessage 	VARCHAR(200)
)
sp: BEGIN
	/*
		Created:	20200204@Thai
		Task:		Add a flagged evidence and affected evidences for associated customers[Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200225@Lex: Fix cocurrency issue when inserting
			- 20200227@Lex: Fix exclude exception
			- 20200513@Lex: Fix wrong subID mapping of level 2
			- 20200807@Casey.Huynh [138925]: Chagne CustEvidence Structure for Cross Subscriber : Remove SubscriberID and IsCreatedByMaster
            - 20201013@Long.Luu [Redmine ID: #141756]: Sync Evidence to Category
        
		Param's Explanation (filtered by):			
        
			CALL CTS_DC_AddEvidence (11113, 2, 5, 'test by Thai', 8, TRUE)
	*/    
      
    DECLARE		lv_CreatedDate		DATETIME;
    DECLARE		lv_CustID			BIGINT UNSIGNED;
    DECLARE		lv_SubscriberID		SMALLINT UNSIGNED;
    DECLARE		lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_CustEvidence_InsertSingle';    
    DECLARE		lv_IsSyncEvi2Cate	VARCHAR(1) DEFAULT '';
    DECLARE     lv_CreatedBy 		INT DEFAULT 10278938;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    SET	lv_CreatedDate = CURRENT_TIME();        	
	
	DROP TABLE IF EXISTS Temp_Exclusion;
    CREATE TEMPORARY TABLE Temp_Exclusion(
		CTSCustID BIGINT
	);
    
    DROP TABLE IF EXISTS Temp_AffectedDevices;
    CREATE TEMPORARY TABLE Temp_AffectedDevices(
		DCSDeviceID BIGINT
	);
    
	IF NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomer
			WHERE CTSCustID = ip_CTSCustID) THEN
		LEAVE sp;
	END IF;
    
    IF EXISTS (SELECT 1 FROM CTS_DataCenter.CustEvidence
				WHERE CTSCustID = ip_CTSCustID										
					AND EvidenceID = ip_EvidenceID
                    AND Level = 0) THEN
		LEAVE sp;
	END IF;
    
    SELECT CustID, SubscriberID
    INTO lv_CustID, lv_SubscriberID
    FROM CTS_DataCenter.CTSCustomer
	WHERE CTSCustID = ip_CTSCustID;
    
	#======INSERT FLAGGED EVIDENCE=================================    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	VALUES (ip_CTSCustID, ip_EvidenceID, ip_Remark, 0, ip_CTSCustID, lv_CreatedDate, ip_UserID);
	
	#=====INSERT AFFECTED EVIDENCE==========================
    
	
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   
    
    INSERT INTO Temp_AffectedDevices(DCSDeviceID)
    SELECT DISTINCT ass.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice ass    
    WHERE ass.CTSCustID = ip_CTSCustID;

	#======GET EXCEPTION LIST=================================
    INSERT INTO Temp_Exclusion(CTSCustID)
    SELECT DISTINCT CASE WHEN LeastCTSCustID_Order = ip_CTSCustID THEN GreatestCTSCustID_Order ELSE LeastCTSCustID_Order END
    FROM CTS_DataCenter.CustException
    WHERE LeastCTSCustID_Order = ip_CTSCustID
    OR GreatestCTSCustID_Order = ip_CTSCustID;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT DISTINCT ass.CTSCustID, ip_EvidenceID, ip_Remark, 2, ip_CTSCustID, lv_CreatedDate, ip_UserID
    FROM CTS_DataCenter.AssociationByDevice AS ass
    INNER JOIN CTS_DataCenter.CTSCustomer cust
		   ON (cust.CTSCustID = ass.CTSCustID)
    INNER JOIN Temp_AffectedDevices AS dev    
		   ON (ass.DCSDeviceID = dev.DCSDeviceID)
	WHERE ass.CTSCustID <> ip_CTSCustID		
    	AND ass.CTSCustID NOT IN (SELECT CTSCustID FROM Temp_Exclusion);
    
    #=====LOG==========================
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, CONCAT('Insert Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_EvidenceID = ', ip_EvidenceID), lv_CreatedDate, ip_UserID);
    
    # Sync Evidence to Category
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
    IF(lv_IsSyncEvi2Cate = '1'
		AND NOT EXISTS (SELECT 1 FROM CTS_DataCenter.SpecialCustomerClass
				WHERE CTSCustID = ip_CTSCustID)) THEN
		INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT 	lv_CustID
			, 	ip_CTSCustID
			, 	lv_SubscriberID
			, 	CategoryID
			,   0
			, 	'Synced from Evidence'
			, 	CURRENT_TIMESTAMP()
			,   lv_CreatedBy
			,   CURRENT_TIMESTAMP()
			,   lv_CreatedBy
			,   CURRENT_DATE
        FROM CTS_DataCenter.EvidenceToCategory
        WHERE EvidenceID = ip_EvidenceID;
    END IF;
    
    
END$$
DELIMITER ;