/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_Get`()
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
			- CALL CTS_DC_AssociatedGroup_Get(); 
	*/
    
    SELECT 	grp.GroupID
		,	grp.GroupName
        ,	grp.ABI
        ,	(SELECT COUNT(1) 
             FROM AssociatedGroupAccount AS acc
             WHERE acc.GroupID =  grp.GroupID) AS TotalAccount
        ,	grp.Remark
        ,	grp.Created
		,	us.UserName AS CreatedBy
    FROM CTS_DataCenter.AssociatedGroup AS grp
		LEFT JOIN CTS_Admin.CTSUser AS us ON grp.CreatedBy = us.UserID
	WHERE grp.IsDisable = 0;
END$$
DELIMITER ;