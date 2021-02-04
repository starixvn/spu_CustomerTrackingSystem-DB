/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
USE CTS_DataCenter;
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidenceQueue_RollbackRemovedEvidences`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidenceQueue_RollbackRemovedEvidences`(
		IN 	ip_SessionId			BIGINT UNSIGNED
    
	,	OUT op_ErrorMessage			VARCHAR(200)
)
SQL SECURITY INVOKER
	
BEGIN
	/*
		Created:	20210204@Long.Luu
		Task:		Rollback removed customer evidences [Redmine ID: #148719]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210204@Long.Luu: Created [Redmine ID: #148719]
		
		Param's Explanation (filtered by):   
            
		Example:			
			- call CTS_DataCenter.CTS_DC_CustEvidenceQueue_RollbackRemovedEvidences(1, @op_ErrorMessage);
	*/
	
	INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, Level, FromCustID, CreatedDate, CreatedBy)
	SELECT 	l.CTSCustID
		, 	l.EvidenceID
        , 	l.Remark
        , 	l.Level
        , 	l.FromCustID
        , 	l.CreatedDate
        , 	l.CreatedBy
	FROM CTS_DataCenter.CustEvidenceLog AS l
	WHERE l.SessionId = ip_SessionId;
		
	DELETE FROM CTS_DataCenter.CustEvidenceLog
	WHERE SessionId = ip_SessionId;
	
END$$

DELIMITER ;
