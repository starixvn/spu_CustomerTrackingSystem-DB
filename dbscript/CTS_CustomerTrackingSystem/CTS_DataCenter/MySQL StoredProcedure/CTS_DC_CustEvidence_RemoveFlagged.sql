/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustEvidence_RemoveFlagged`;

DELIMITER $$
USE `CTS_DataCenter`$$
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
        
		Param's Explanation (filtered by):			
        
        CALL CTS_DataCenter.CTS_DC_CustEvidence_RemoveFlagged(221882500, 41, 8, @op_ErrorMessage);
	*/    
     
    DECLARE		lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_CustEvidence_RemoveFlagged';  
    DECLARE		lv_CreatedDateTime 	DATETIME 		DEFAULT CURRENT_TIME();
    DECLARE     lv_CreatedBy        BIGINT DEFAULT     10278938;
    
	DECLARE		lv_CustID			BIGINT UNSIGNED;  
    DECLARE		lv_IsSyncEvi2Cate	VARCHAR(1) 		DEFAULT '';  
     
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
     
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedEvidenceCategories;    
	CREATE TEMPORARY TABLE Temp_ExistedEvidenceCategories 
    (	  
			CTSCustID			BIGINT UNSIGNED
        , 	CategoryID	        SMALLINT UNSIGNED 
        ,   EvidenceID          SMALLINT UNSIGNED
        , 	INDEX 				IX_Temp_ExistedEvidenceCategories_CTSCustID_CategoryID(CTSCustID, CategoryID)       
     );

	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
	SET SQL_SAFE_UPDATES = 0;
    
    /*DELETE FLAGGED EVIDENCE*/
    DELETE FROM CTS_DataCenter.CustEvidence
	WHERE FromCustID = ip_CTSCustID		
	AND EvidenceID = ip_EvidenceID;
    
    /*GET EXISTED EVIDENCE LIST ARE MAPPING TO CATEGORY*/
	INSERT INTO Temp_ExistedEvidenceCategories
    SELECT ip_CTSCustID, e.CategoryID, evd.EvidenceID
    FROM CTS_DataCenter.CustEvidence AS evd
    INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = evd.EvidenceID 
    WHERE evd.FromCustID = ip_CTSCustID AND evd.Level = 0;
  
	/*SYNC EVIDENCE TO CATEGORY*/
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
    IF(lv_IsSyncEvi2Cate = '1') THEN
        -- Insert log after all evd category are deleted
        INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
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
        LEFT JOIN Temp_ExistedEvidenceCategories AS ex ON ex.CTSCustID = c.CTSCustID
        WHERE ex.CTSCustID IS NULL AND c.CTSCustID = ip_CTSCustID;
        
		DELETE c
        FROM CTS_DataCenter.CTSCustomerClassification AS c
        INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.CategoryID = c.CategoryID
        LEFT JOIN Temp_ExistedEvidenceCategories AS ex ON ex.CategoryID = c.CategoryID AND ex.CTSCustID = c.CTSCustID
        WHERE ex.CategoryID IS NULL AND c.CTSCustID = ip_CTSCustID;
        
    END IF;
  
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(4, lv_SPName, CONCAT('Remove Flagged Evidence: ip_CTSCustID = ', ip_CTSCustID, ';ip_EvidenceID = ', ip_EvidenceID), lv_CreatedDateTime, ip_UserID); 
    
    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedEvidenceCategories;     
END$$

DELIMITER ;