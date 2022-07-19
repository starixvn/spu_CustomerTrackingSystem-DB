/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_Account_Add`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_Account_Add`(
		IN ip_GroupID 		BIGINT UNSIGNED
    ,	IN ip_CTSCustIDs 	LONGTEXT
    ,	IN ip_IsAuto		BIT
    ,	IN ip_Remark 		VARCHAR(200)
    ,	IN ip_CreatedBy 	INT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/* 
		Created:	20220705@Aries.Nguyen
		Task:		[CTS] Fraud Group Management [Redmine ID: #167748]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220705@Aries.Nguyen: Created [Redmine ID: #167748]
        
		Param's Explanation (filtered by):
	*/
    DECLARE lv_LogTypeID		INT DEFAULT 34;
    
	IF ip_IsAuto = 1 THEN
		SET ip_CreatedBy = 10278938;
    END IF;
    
    INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(lv_LogTypeID,'CTS_DC_AssociatedGroup_Account_Add', CONCAT('GroupID:', ip_GroupID), NOW(), ip_CreatedBy);
    
    INSERT IGNORE INTO CTS_DataCenter.AssociatedGroupAccount(GroupID,CTSCustID,IsAuto,Remark,CreatedBy)
    SELECT 	ip_GroupID AS GroupID
		,	tmp.CTSCustID
        ,	ip_IsAuto AS IsAuto
        ,	ip_Remark AS Remark
        ,	ip_CreatedBy AS CreatedBy
    FROM JSON_TABLE(CONCAT('[',ip_CTSCustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp;
END$$
DELIMITER ;