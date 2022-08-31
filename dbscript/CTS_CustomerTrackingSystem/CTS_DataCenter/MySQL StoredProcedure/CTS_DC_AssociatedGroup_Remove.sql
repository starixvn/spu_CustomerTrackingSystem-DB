/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_Remove`(
		IN ip_GroupID 		BIGINT UNSIGNED
	,	IN ip_UserID 		INT UNSIGNED
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
			- CALL CTS_DC_AssociatedGroup_Remove(1,1);
	*/
    DECLARE lv_AuditInfo JSON;
    SET lv_AuditInfo = JSON_OBJECT('GroupID', ip_GroupID);
    
    INSERT INTO CTS_DataCenter.CTSAuditLog(EventName,CreatedBy, Info)
	VALUES("CTS_DC_AssociatedGroup_Remove",ip_UserID, lv_AuditInfo);
    
	UPDATE CTS_DataCenter.AssociatedGroup 
	SET		IsDisable = 1
		,	ModifiedBy = ip_UserID
    WHERE GroupID = ip_GroupID;
END$$
DELIMITER ;