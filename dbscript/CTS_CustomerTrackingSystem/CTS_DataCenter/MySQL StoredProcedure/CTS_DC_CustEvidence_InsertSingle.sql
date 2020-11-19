/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustEvidence_InsertSingle`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_InsertSingle`(IN ip_CTSCustID bigint,IN ip_EvidenceID smallint,IN ip_Remark varchar(500),IN ip_UserID int,OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
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
			- 20201020@Irena.Vo [Redmine ID: #141756]: Enhance logic Remove all category (Detail & General) 
            - 20201111@Irena.Vo [Redmine ID: #145027]: Enhance logic Insert History for Evidence Category
        
		Param's Explanation (filtered by):			
        call CTS_DataCenter.CTS_DC_CustEvidence_InsertSingle(221882500, 41, 'Na Test', 8, @op_ErrorMessage);
	*/    
      
    DECLARE		lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_CustEvidence_InsertSingle';    
    DECLARE		lv_CreatedDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE 	lv_CreatedBy        BIGINT DEFAULT 10278938;
    
    DECLARE		lv_CustID			BIGINT UNSIGNED;
    DECLARE		lv_SubscriberID		INT UNSIGNED;
    DECLARE		lv_IsSyncEvi2Cate	VARCHAR(1) DEFAULT '';

    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
  
	DROP TEMPORARY TABLE IF EXISTS   Temp_AffectedDevices;
    CREATE TEMPORARY TABLE Temp_AffectedDevices(
			DCSDeviceID		BIGINT
	);
    
	DROP TEMPORARY TABLE IF EXISTS   Temp_AssociatedException;
    CREATE TEMPORARY TABLE Temp_AssociatedException(
        	ToCTSCustID 	BIGINT UNSIGNED
	);
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    
    /*IGNORE NOT EXISTED CUSTOMERS OR EXISTED EVIDENCE*/
	IF NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomer WHERE CTSCustID = ip_CTSCustID) THEN
		LEAVE sp;
	END IF;
    
    IF EXISTS (SELECT 1 FROM CTS_DataCenter.CustEvidence WHERE CTSCustID = ip_CTSCustID	AND EvidenceID = ip_EvidenceID AND Level = 0) THEN
		LEAVE sp;
	END IF;
    
    /*GET CUST INFO*/
    SELECT CustID, SubscriberID
    INTO lv_CustID, lv_SubscriberID
    FROM CTS_DataCenter.CTSCustomer
	WHERE CTSCustID = ip_CTSCustID;
    
	/*INSERT FLAGGED EVIDENCE*/    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	VALUES (ip_CTSCustID, ip_EvidenceID, ip_Remark, 0, ip_CTSCustID, lv_CreatedDateTime, ip_UserID);
	
	/*GET AFFECTED DEVICES*/
    INSERT INTO Temp_AffectedDevices(DCSDeviceID)
    SELECT DISTINCT DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice
    WHERE CTSCustID = ip_CTSCustID;

	/*GET ASSOCITED EXCEPTION*/
    INSERT INTO Temp_AssociatedException(ToCTSCustID)
    SELECT DISTINCT CASE WHEN LeastCTSCustID_Order = ip_CTSCustID THEN GreatestCTSCustID_Order 
						 ELSE LeastCTSCustID_Order 
					END
    FROM CTS_DataCenter.CustException
    WHERE LeastCTSCustID_Order = ip_CTSCustID OR GreatestCTSCustID_Order = ip_CTSCustID;
   
   /*INSERT AFFECTED EVIDENCES*/    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT DISTINCT ass.CTSCustID, ip_EvidenceID, ip_Remark, 2, ip_CTSCustID, lv_CreatedDateTime, ip_UserID
    FROM CTS_DataCenter.AssociationByDevice AS ass
    INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON (cust.CTSCustID = ass.CTSCustID)
    INNER JOIN Temp_AffectedDevices AS dev ON (ass.DCSDeviceID = dev.DCSDeviceID)
	WHERE ass.CTSCustID <> ip_CTSCustID		
    	  AND ass.CTSCustID NOT IN (SELECT ToCTSCustID FROM Temp_AssociatedException);
    
   /*WRITE LOG*/
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, CONCAT('Insert Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_EvidenceID = ', ip_EvidenceID), lv_CreatedDateTime, ip_UserID);
    
    /*SYNC EVIDENCE TO CATEGORY*/
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
    IF(lv_IsSyncEvi2Cate = '1' AND NOT EXISTS (SELECT 1 FROM CTS_DataCenter.SpecialCustomerClass WHERE CTSCustID = ip_CTSCustID)) THEN
		DELETE cate
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ip_EvidenceID
		WHERE cate.CustID = lv_CustID AND cc.ParentID IN (1, 200);
		
		DELETE pro
		FROM CTS_DataCenter.ProbationAccountMonitor AS pro CROSS JOIN CTS_DataCenter.EvidenceToCategory AS e
		WHERE pro.CustID = lv_CustID AND e.EvidenceID = ip_EvidenceID;
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
		SELECT 	lv_CustID
			, 	ip_CTSCustID
			, 	lv_SubscriberID
			, 	CategoryID
			,   0
			, 	'Synced by Evidence'
			, 	lv_CreatedDateTime
			,   lv_CreatedBy
			,   lv_CreatedDateTime
			,   lv_CreatedBy
			,   DATE(lv_CreatedDateTime)
		FROM CTS_DataCenter.EvidenceToCategory
		WHERE EvidenceID = ip_EvidenceID;  
		
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TurnoverRM, WinlossRM, BetCount, ActiveDays)
		SELECT 	lv_CustID
			, 	ip_CTSCustID
			, 	CategoryID
			,   0
			,   lv_CreatedDateTime
			,   lv_CreatedBy
			,   0
			,   1
			,   DATE(lv_CreatedDateTime)
            , 0
            , 0
            , 0
            , 0
		FROM CTS_DataCenter.EvidenceToCategory
		WHERE EvidenceID = ip_EvidenceID;  
    END IF;
   
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedException;
	DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices; 
END$$

DELIMITER ;