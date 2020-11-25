/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustEvidence_RemoveFlagged`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_RemoveFlagged`(IN ip_CTSCustID bigint, IN ip_EvidenceID smallint,IN ip_UserID int,OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200204@Thai
		Task:		Remove a flagged evidence [Redmine ID: 127150]
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20200225@Lex: Fix remove flag evidence also associted evidence (level 2)
			- 20201013@Long.Luu [Redmine ID: #141756]: Sync Evidence to Category
            - 20201020@Irena.Vo [Redmine ID: #141756]: Enhance logic remove Evidence Category
            - 20201111@Irena.Vo [Redmine ID: #145027]: Enhance logic Insert History for Evidence Category
            - 20201125@Irena.Vo [Redmine ID: #141563]: Move flow sync Evidence to Category
        
		Param's Explanation (filtered by):			
        
        CALL CTS_DataCenter.CTS_DC_CustEvidence_RemoveFlagged(221882500, 41, 8, @op_ErrorMessage);
	*/    
     
    DECLARE		lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_CustEvidence_RemoveFlagged';  
    DECLARE		lv_CreatedDateTime 	DATETIME 		DEFAULT CURRENT_TIME();
   
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
	
    /*DELETE FLAGGED EVIDENCE*/
    DELETE FROM CTS_DataCenter.CustEvidence
	WHERE FromCustID = ip_CTSCustID		
	AND EvidenceID = ip_EvidenceID;
  
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(4, lv_SPName, CONCAT('Remove Flagged Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_EvidenceID = ', ip_EvidenceID), lv_CreatedDateTime, ip_UserID); 

     -- Web will return ip_CTSCustID, ip_CustID, ip_SubscriberID, ip_EvidenceID, 2 (ActionType)
END$$

DELIMITER ;