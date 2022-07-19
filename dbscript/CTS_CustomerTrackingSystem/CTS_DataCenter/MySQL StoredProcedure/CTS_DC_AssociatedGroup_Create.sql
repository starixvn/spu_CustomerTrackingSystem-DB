/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_Create`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_Create`(
		IN ip_GroupName 		VARCHAR(100)
    ,	IN ip_ABI 				INT
    ,	IN ip_Remark 			VARCHAR(200)
    ,	IN ip_CreatedBy 		INT UNSIGNED
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
			- CALL CTS_DC_AssociatedGroup_Create('Group 1', 47, 'Comment', 15471129);
	*/
	DECLARE lv_LogTypeID		INT DEFAULT 34;
    INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(lv_LogTypeID,'CTS_DC_AssociatedGroup_Create', CONCAT('GroupName:', ip_GroupName,';ABI:', ip_ABI), NOW(), ip_CreatedBy);

    INSERT INTO CTS_DataCenter.AssociatedGroup(GroupName,ABI,Remark,CreatedBy)
    VALUES(ip_GroupName,ip_ABI,ip_Remark,ip_CreatedBy);
END$$
DELIMITER ;