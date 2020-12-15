/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_SpecialCustClass_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_SpecialCustClass_Remove`(IN ip_CTSCustID int,IN ip_UserID int,OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
BEGIN
		/*
		Created:	20200908@Long.Luu
		Task:		Remove special customer class [Redmine ID: #140996]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200908@Long.Luu [Redmine ID: #140996]: Created 
			- 20201214@Irena.Vo: Update History Log & Return CustID with TypeID = 2 [Redmine ID: #145951]
        
		Param's Explanation (filtered by):
	*/
    DECLARE lv_CustID BIGINT UNSIGNED;
    DECLARE lv_CustomerClass TINYINT;
    
    DECLARE lv_CurrentDateTime DATETIME DEFAULT NOW();
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_SpecialCustClass_Remove'; 
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    -- Get customer info
    SELECT CustID
    INTO lv_CustID
    FROM CTS_DataCenter.CTSCustomer WHERE CTSCustID = ip_CTSCustID;    
    
    -- Get CC
    SELECT CustomerClass
    INTO lv_CustomerClass
    FROM CTS_DataCenter.SpecialCustomerClass WHERE CustID = lv_CustID;
    
    -- Remove old CC
	DELETE	s
    FROM	CTS_DataCenter.SpecialCustomerClass AS s WHERE s.CustID = lv_CustID;
    
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(20, lv_SPName, CONCAT('Remove special customer class: ip_CTSCustID_ ', ip_CTSCustID) , DATE(lv_CurrentDateTime), ip_UserID);
    
    -- Insert Log
    IF NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomerClassification AS cate  WHERE cate.CustID = lv_CustID) THEN
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID,  LastModifiedDate,LastModifiedBy, ActionType,  IsAuto, InsertDate, TargetCC, SourceTypeID)
		SELECT    lv_CustID
				, ip_CTSCustID
				, 201
				, 200
				, lv_CurrentDateTime
				, ip_UserID
				, 2 -- remove
				, 0 -- manual
				, DATE(lv_CurrentDateTime)
				, -1
				, 12; -- item name = Remove Customer Class;
    ELSE            
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID,  LastModifiedDate,LastModifiedBy, ActionType,  IsAuto, InsertDate, TargetCC, SourceTypeID)
		SELECT    lv_CustID
				, ip_CTSCustID
				, cate.CategoryID
				, cate.SportGroupID
				, lv_CurrentDateTime
				, ip_UserID
				, 2 -- remove
				, 0 -- manual
				, DATE(lv_CurrentDateTime)
				, -1
				, 12 -- item name = Remove Customer Class
		FROM CTS_DataCenter.CTSCustomerClassification AS cate 
		WHERE cate.CustID = lv_CustID;
	END IF;
    
    /*	GET LASTEST CUSTID LIST	*/
    SELECT DISTINCT lv_CustID AS CustId,	2 AS TypeId;
    
END$$

DELIMITER ;