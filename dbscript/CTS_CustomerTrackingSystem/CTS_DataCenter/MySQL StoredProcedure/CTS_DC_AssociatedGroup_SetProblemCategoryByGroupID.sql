/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_SetProblemCategoryByGroupID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_SetProblemCategoryByGroupID`(
		IN ip_GroupID 			BIGINT UNSIGNED
    ,	IN ip_PACategoryID		INT
    ,	IN ip_PAAllCredit		TINYINT
    ,	IN ip_PAAllLicensee		TINYINT
    ,	IN ip_PASites			LONGTEXT
    ,	IN ip_ModifiedBy 		INT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
/* 
		Created:	20221025@Harvey.Nguyen
		Task :		[CTS] Associated Group Enhancement
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
            - 20221025@Harvey.Nguyen: Update PA for group [Redmine ID: #179398]
		
        Param's Explanation: 

		Example:
			- CALL CTS_DC_AssociatedGroup_SetProblemCategoryByGroupID(1,'Group 111', 47,1,1,'66,101,187,111',1,1,1,1, 'Comment11', 15471129);

*/
	DECLARE lv_AuditInfo JSON;
    SET lv_AuditInfo = JSON_OBJECT('GroupID', ip_GroupID, 
								   'PACategoryID', ip_PACategoryID, 
								   'PAAllCredit', ip_PAAllCredit, 
                                   'PAAllLicensee', ip_PAAllLicensee, 
                                   'PASites', ip_PASites);
    
    INSERT INTO CTS_DataCenter.CTSAuditLog(EventName,CreatedBy, Info)
	VALUES("CTS_DC_AssociatedGroup_SetPA",ip_ModifiedBy, lv_AuditInfo);
	
    UPDATE CTS_DataCenter.AssociatedGroup
    SET  	PACategoryID = CASE WHEN ip_PACategoryID = -1 THEN NULL ELSE ip_PACategoryID END
		,	PAAllCredit = ip_PAAllCredit
        ,	PAAllLicensee = ip_PAAllLicensee
		,	PASites = ip_PASites
        ,	ModifiedBy = ip_ModifiedBy
    WHERE GroupID = ip_GroupID;
END$$
DELIMITER ;