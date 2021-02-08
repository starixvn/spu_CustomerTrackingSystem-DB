/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
USE CTS_DataCenter;
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidenceQueue_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidenceQueue_Insert`(
		IN 	ip_CustomerEvidences	JSON	
	,	IN 	ip_FileName				VARCHAR(200)
	,	IN 	ip_FileKey				VARCHAR(50)
	,	IN 	ip_CreatedBy			INT
	,	IN 	ip_ActionID				TINYINT UNSIGNED
    
	,	OUT op_ErrorMessage			VARCHAR(200)
)
SQL SECURITY INVOKER

BEGIN
	/*
		Created:	20210204@Long.Luu
		Task:		Insert customer evidences to queue [Redmine ID: #148719]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210204@Long.Luu: Created [Redmine ID: #148719]
		
		Param's Explanation (filtered by):   
			- ActionID: 1 insert, 2 override, 3 clear
            
		Example:			
			- call CTS_DataCenter.CTS_DC_CustEvidenceQueue_Insert('[{"CTSCustID":19314,"CustID":1773789,"SubscriberID":130,"EvidenceID":13,"Remark":"test"}]', 'test1.xlsx', '202102041055428556', 8, 1, @op_ErrorMessage);
	*/
	
	DECLARE lv_CurrentTime	TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;	
	
	INSERT INTO CTS_DataCenter.CustEvidenceQueue(CTSCustID, CustID, SubscriberID, EvidenceID, Remark, FileKey, FileName, CreatedBy, CreatedTime, ActionID)
	SELECT	tmpTable.CTSCustID
		,	tmpTable.CustID
		,	tmpTable.SubscriberID
		,	tmpTable.EvidenceID
		,	tmpTable.Remark
		,	ip_FileKey
		,	ip_FileName
		,	ip_CreatedBy
		,	lv_CurrentTime
		,	ip_ActionID
	FROM JSON_TABLE(ip_CustomerEvidences, 
		"$[*]" COLUMNS(
			  CTSCustID 	BIGINT UNSIGNED		PATH "$.CTSCustID"
			, CustID		INT UNSIGNED		PATH "$.CustID"
			, SubscriberID	INT UNSIGNED		PATH "$.SubscriberID"
			, EvidenceID	SMALLINT UNSIGNED	PATH "$.EvidenceID"
			, Remark		VARCHAR(500)		PATH "$.Remark"
		)) AS tmpTable;		
END$$

DELIMITER ;
