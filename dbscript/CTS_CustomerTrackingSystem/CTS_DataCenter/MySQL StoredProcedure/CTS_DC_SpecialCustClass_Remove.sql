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
			- 20201214-20201229@Irena.Vo: Insert History Log.  [Redmine ID: #145951]
        
		Param's Explanation (filtered by):
	*/
    DECLARE lv_CustID BIGINT UNSIGNED;
    DECLARE lv_CustomerClass TINYINT;
    
    DECLARE lv_CurrentDateTime DATETIME DEFAULT CURRENT_TIME();
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
    FROM CTS_DataCenter.SpecialCustomerClass WHERE CTSCustID = ip_CTSCustID AND CreatedFromFunction = 1;
    
    -- Remove old CC
	DELETE	s
    FROM	CTS_DataCenter.SpecialCustomerClass AS s WHERE s.CTSCustID = ip_CTSCustID AND s.CreatedFromFunction = 1;
    
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(20, lv_SPName, CONCAT('Remove special customer class: ip_CTSCustID_ ', ip_CTSCustID) , DATE(lv_CurrentDateTime), ip_UserID);
    
    -- Insert Log
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
	(CustID, CTSCustID, LastModifiedDate,LastModifiedBy, ActionType,  IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
	SELECT  DISTINCT  lv_CustID
			, ip_CTSCustID
			, lv_CurrentDateTime
			, ip_UserID
			, 2 -- remove
			, 0 -- manual
			, DATE(lv_CurrentDateTime)
			, -1
			, 12 -- item name = Remove Customer Class
			, 1; -- View History
END$$

DELIMITER ;