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
        
		Param's Explanation (filtered by):
        
        Example: 
			- CALL CTS_DC_AssociatedGroup_Remove(1,1);
	*/
    DECLARE lv_LogTypeID		INT DEFAULT 34;
    INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(lv_LogTypeID,'CTS_DC_AssociatedGroup_Remove', CONCAT('GroupID: ', ip_GroupID), NOW(), ip_UserID);
    
	UPDATE CTS_DataCenter.AssociatedGroup 
	SET		IsDisable = 1
		,	ModifiedBy = ip_UserID
    WHERE GroupID = ip_GroupID;
END$$
DELIMITER ;