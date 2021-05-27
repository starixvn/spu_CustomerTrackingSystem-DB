/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_Remove`(
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
            - 20201214-20201229@Irena.Vo: Insert History Log & Auto Unpin category. Insert Error Log [RedmineID: #145951]
            - 20210226@Irena.Vo: Update CategoryID from VVIP [RedmineID: #150454]
			- 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [RedmineID: #152965] 
		Param's Explanation:
	*/ 
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_SPName 			VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_Remove';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	/*Remove VVIP*/
	DELETE FROM CTS_DataCenter.CTSCustomerClassification WHERE CTSCustID = ip_CTSCustID AND CategoryID = ip_CategoryID;
	
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(12, lv_SPName, CONCAT('Remove VVIP: From ip_CTSCustID_', ip_CTSCustID, ';ip_CategoryID_', ip_CategoryID), lv_CurrentDateTime, ip_CreatedBy);

	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
	(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
	SELECT 	ip_CustID
		, 	ip_CTSCustID
		,   ip_CategoryID
		,   200
		, 	lv_CurrentDateTime
		, 	ip_CreatedBy
		,   2
		,   0
		,   DATE(lv_CurrentDateTime)
		,   -1
		,   14
		,	1;
		
	/*Auto Unpin*/
	DELETE FROM CTS_DataCenter.PinCustomerCategory WHERE CTSCustID = ip_CTSCustID;
END$$
DELIMITER ;