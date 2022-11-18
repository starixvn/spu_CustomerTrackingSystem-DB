/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_Update`(
		IN ip_GroupID 			BIGINT UNSIGNED
	,	IN ip_GroupName 		VARCHAR(100)
    ,	IN ip_ABI 				INT
    ,	IN ip_Danger1 			INT
    ,	IN ip_AllCredit			TINYINT
    ,	IN ip_AllLicensee		TINYINT
    ,	IN ip_Sites				LONGTEXT
    ,	IN ip_HasDevice			TINYINT
    ,	IN ip_HasManual			TINYINT
    ,	IN ip_HasIP				TINYINT
    ,	IN ip_HasAI				TINYINT
    ,	IN ip_Remark 			VARCHAR(200)
    ,	IN ip_ModifiedBy 		INT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
/* 
		Created:	20220831@Aries.Nguyen
		Task :		[CTS] Associated Group Enhancement
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
			- 20220831@Aries.Nguyen: Created [Redmine ID: #176991] 
            - 20221025@Harvey.Nguyen: Associated Group Enhancement [Redmine ID: #179398]
		
        Param's Explanation: 

		Example:
			- CALL CTS_DC_AssociatedGroup_Update(1,'Group 111', 47,1,1,'66,101,187,111',1,1,1,1, 'Comment11', 15471129);

*/
	DECLARE lv_AuditInfo JSON;
    SET lv_AuditInfo = JSON_OBJECT('GroupID', ip_GroupID, 
								   'GroupName', ip_GroupName, 
								   'ABI', ip_ABI, 
                                   'Danger1', ip_Danger1, 
                                   'AllCredit', ip_AllCredit, 
                                   'AllLicensee', ip_AllLicensee, 
                                   'Sites', ip_Sites, 
                                   'HasDevice', ip_HasDevice, 
                                   'HasManual', ip_HasManual, 
                                   'HasIP', ip_HasIP, 
								   'HasAI', ip_HasAI,
                                   'Remark', ip_Remark);
    
    INSERT INTO CTS_DataCenter.CTSAuditLog(EventName,CreatedBy, Info)
	VALUES("CTS_DC_AssociatedGroup_Update",ip_ModifiedBy, lv_AuditInfo);
	
    UPDATE CTS_DataCenter.AssociatedGroup
    SET  	GroupName =  ip_GroupName
		,	ABI = ip_ABI
        ,	Danger1 = ip_Danger1
		,	AllCredit = ip_AllCredit
		,	AllLicensee = ip_AllLicensee
		,	Sites = ip_Sites
		,	HasDevice = ip_HasDevice
		,	HasManual = ip_HasManual
		,	HasIP = ip_HasIP
		,	HasAI = ip_HasAI
		,	Remark =  ip_Remark
        ,	ModifiedBy = ip_ModifiedBy
    WHERE GroupID = ip_GroupID;
    
    
END$$
DELIMITER ;