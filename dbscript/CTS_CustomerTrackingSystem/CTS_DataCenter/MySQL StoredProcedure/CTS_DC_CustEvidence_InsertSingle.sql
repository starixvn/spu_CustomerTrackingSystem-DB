/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_InsertSingle`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_InsertSingle`(
		IN ip_CTSCustID			BIGINT UNSIGNED
	,	IN ip_EvidenceID		SMALLINT
	,	IN ip_Remark			VARCHAR(500)
	,	IN ip_UserID			INT
	
	,	OUT op_ErrorMessage		VARCHAR(200)
)
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
            - 20201013@Long.Luu: Sync Evidence to Category [Redmine ID: #141756]
			- 20201020@Irena.Vo: Enhance logic Remove all category (Detail & General) [Redmine ID: #141756]
            - 20201111@Irena.Vo: Enhance logic Insert History for Evidence Category [Redmine ID: #145027]
            - 20201125@Irena.Vo: Move flow sync Evidence to Category [Redmine ID: #141563]
			- 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
        
		Param's Explanation (filtered by):		

		Example: 
			-CALL CTS_DataCenter.CTS_DC_CustEvidence_InsertSingle(221882500, 41, 'Na Test', 8, @op_ErrorMessage);
	*/    
      
   DECLARE		lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_CustEvidence_InsertSingle';    
    DECLARE		lv_CreatedDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE 	lv_CreatedBy        BIGINT DEFAULT 10278938;
  
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
	
    /*IGNORE NOT EXISTED CUSTOMERS OR EXISTED EVIDENCE*/
	IF NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomer WHERE CTSCustID = ip_CTSCustID) THEN
		LEAVE sp;
	END IF;
    
    IF EXISTS (SELECT 1 FROM CTS_DataCenter.CustEvidence WHERE CTSCustID = ip_CTSCustID	AND EvidenceID = ip_EvidenceID AND Level = 0) THEN
		LEAVE sp;
	END IF;
    
	/*INSERT FLAGGED EVIDENCE*/    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	VALUES (ip_CTSCustID, ip_EvidenceID, ip_Remark, 0, ip_CTSCustID, lv_CreatedDateTime, ip_UserID);
	
	/*GET AFFECTED DEVICES*/
    INSERT INTO Temp_AffectedDevices(DCSDeviceID)
    SELECT DISTINCT ass.DCSDeviceID
    FROM CTS_DataCenter.AssociationByDevice ass    
    WHERE ass.CTSCustID = ip_CTSCustID;

	/*GET ASSOCITED EXCEPTION*/
    INSERT INTO Temp_AssociatedException(ToCTSCustID)
    SELECT DISTINCT CASE WHEN LeastCTSCustID_Order = ip_CTSCustID THEN GreatestCTSCustID_Order 
						 ELSE LeastCTSCustID_Order 
					END
    FROM CTS_DataCenter.CustException
    WHERE  LeastCTSCustID_Order = ip_CTSCustID 
		OR GreatestCTSCustID_Order = ip_CTSCustID;
   
   /*INSERT AFFECTED EVIDENCES*/    
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
    SELECT	DISTINCT 
			ass.CTSCustID
		,	ip_EvidenceID
		,	ip_Remark
		,	2
		,	ip_CTSCustID
		,	lv_CreatedDateTime
		,	ip_UserID
    FROM CTS_DataCenter.AssociationByDevice AS ass
		INNER JOIN CTS_DataCenter.CTSCustomer cust ON cust.CTSCustID = ass.CTSCustID
		INNER JOIN Temp_AffectedDevices AS dev ON ass.DCSDeviceID = dev.DCSDeviceID
	WHERE ass.CTSCustID <> ip_CTSCustID		
    	  AND ass.CTSCustID NOT IN (SELECT ToCTSCustID FROM Temp_AssociatedException);
    
   /*WRITE LOG*/
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(3, lv_SPName, CONCAT('Insert Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_EvidenceID = ', ip_EvidenceID), lv_CreatedDateTime, ip_UserID);
    
    -- Web will return ip_CTSCustID, ip_CustID, ip_SubscriberID, ip_EvidenceID, 0 (ActionType)
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociatedException;
	DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
    
END$$

DELIMITER ;