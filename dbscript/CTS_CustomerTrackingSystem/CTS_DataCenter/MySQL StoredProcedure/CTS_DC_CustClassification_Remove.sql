/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Remove`(
		IN ip_CustID			BIGINT UNSIGNED
	,   IN ip_CTSCustID			BIGINT UNSIGNED 
	,	IN ip_CategoryID		SMALLINT
	,	IN ip_CreatedBy 		INT
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
    SQL SECURITY INVOKER 
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
            - 20200908@Irena.Vo: Delete VVIP OR All Category has Pin before (Include Customer Class) [Redmine ID: #141020]
            - 20200921@Irena.Vo: Enhance SP & insert Probation Management flow [Redmine ID: #141755]
			- 20200923@Irena.Vo: Enhance SP [Redmine ID: #141755]
            - 20201201@Aries.Nguyen: Update metadata for goSQL. Remove transaction isolation level REPEATABLE READ and READ UNCOMMITTED. Remove logic detail category. [Redmine ID: #145954]
            - 20201214@Irena.Vo: Update History Log & Auto Unpin category & Return CustID with TypeID = 1 [RedmineID: #145951]
            
		Param's Explanation:
	*/ 

    DECLARE lv_CurrentDateTime DATETIME DEFAULT NOW();
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_RemoveCTSCustomerClassification';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
  
   /*	ACTION FOR VVIP	*/
    IF (ip_CategoryID = 213) THEN
        -- Remove data CTSCustomerClassification
		DELETE 	cate
		FROM 	CTS_DataCenter.CTSCustomerClassification AS cate
		WHERE 	cate.CustID = ip_CustID AND cate.CategoryID  = 213;
        
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(12, lv_SPName, CONCAT('Remove all classification: From ip_CustID_', ip_CustID, '; ip_CategoryID_', ip_CategoryID), lv_CurrentDateTime, ip_CreatedBy);
	
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
        (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID)
		SELECT 	ip_CustID
			, 	ip_CTSCustID
            ,   213
            ,   200
			, 	lv_CurrentDateTime
			, 	ip_CreatedBy
			,   2  -- Remove
			,   0  -- Manual
			,   DATE(lv_CurrentDateTime)
            ,   -1 -- is Remove VVIP
			,   14 -- item name = Remove VVIP
			;
            
        -- Auto Unpin
        DELETE pin
		FROM CTS_DataCenter.PinCustomerCategory AS pin
		WHERE pin.CustID = ip_CustID;
        
    END IF;
    
	/*	GET LASTEST CUSTID LIST	*/
    SELECT 	ip_CustID AS CustId,	1 AS TypeId;
    
END$$

DELIMITER ;