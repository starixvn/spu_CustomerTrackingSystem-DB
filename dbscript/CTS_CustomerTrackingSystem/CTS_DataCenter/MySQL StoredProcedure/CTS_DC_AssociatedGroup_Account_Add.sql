/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_Account_Add`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_Account_Add`(
		IN ip_GroupID 		BIGINT UNSIGNED
    ,	IN ip_CTSCustIDs 	LONGTEXT
    ,	IN ip_IsAuto		TINYINT
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
            - 20220831@Aries.Nguyen: Associated Group Enhancement [Redmine ID: #176991]
        
		Param's Explanation (filtered by):

        Example: 
			- CALL CTS_DC_AssociatedGroup_Account_Add(1,"1,2",0,"comment",169368);
	*/
    DECLARE lv_AuditInfo JSON;
	IF ip_IsAuto = 1 THEN
		SET ip_CreatedBy = 10278938;
    END IF;
    
    SET lv_AuditInfo = JSON_OBJECT('GroupID', ip_GroupID, 
								   'CTSCustIDs', ip_CTSCustIDs, 
								   'IsAuto', ip_IsAuto, 
                                   'Remark', ip_Remark);
    
    INSERT INTO CTS_DataCenter.CTSAuditLog(EventName,CreatedBy, Info)
	VALUES("CTS_DC_AssociatedGroup_Account_Add",ip_CreatedBy, lv_AuditInfo);
    
    INSERT IGNORE INTO CTS_DataCenter.AssociatedGroupAccount(GroupID,CTSCustID,IsAuto,Remark,CreatedBy)
    SELECT 	ip_GroupID AS GroupID
		,	tmp.CTSCustID
        ,	ip_IsAuto AS IsAuto
        ,	ip_Remark AS Remark
        ,	ip_CreatedBy AS CreatedBy
    FROM JSON_TABLE(CONCAT('[',ip_CTSCustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp;
END$$
DELIMITER ;