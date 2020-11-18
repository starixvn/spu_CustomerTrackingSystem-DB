/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidenceFromFile_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidenceFromFile_Insert`(
		IN ip_CustomerEvidences		JSON	
	,	IN ip_IsOverwrite			BIT
	,	IN ip_FileName				VARCHAR(200)
	,	IN ip_FileKey				VARCHAR(50)
	,	IN ip_CreatedBy				INT
	,	OUT op_ErrorMessage			VARCHAR(200)
)
SQL SECURITY INVOKER

BEGIN
	/*
		Created:	20201106@Adam.Tran
		Task:		Insert customer evidences [Redmine ID: 141563]
		DB:			CTS_DataCenter
		Original:

		Revisions:
		- 20201106@Adam.Tran [Redmine ID: 141563]: Created
	*/
	
	DECLARE lv_CurrentTime	TIMESTAMP		DEFAULT CURRENT_TIMESTAMP();
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
	BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;	
	
	INSERT INTO CTS_DataCenter.CustEvidenceFromFile(CTSCustID, CustID, SubscriberID, EvidenceID, Remark, IsOverwrite, FileKey, FileName, CreatedBy, CreatedTime)
	SELECT	tmpTable.CTSCustID
		,	tmpTable.CustID
		,	tmpTable.SubscriberID
		,	tmpTable.EvidenceID
		,	tmpTable.Remark
		,	ip_IsOverwrite
		,	ip_FileKey
		,	ip_FileName
		,	ip_CreatedBy
		,	lv_CurrentTime
	FROM JSON_TABLE(ip_CustomerEvidences, 
		"$[*]" COLUMNS(
			  CTSCustID 	INT UNSIGNED		PATH "$.CTSCustID"
			, CustID		INT UNSIGNED		PATH "$.CustID"
			, SubscriberID	INT UNSIGNED		PATH "$.SubscriberID"
			, EvidenceID	SMALLINT UNSIGNED	PATH "$.EvidenceID"
			, Remark		VARCHAR(500)		PATH "$.Remark"
		)) AS tmpTable;	
	
END$$

DELIMITER ;
