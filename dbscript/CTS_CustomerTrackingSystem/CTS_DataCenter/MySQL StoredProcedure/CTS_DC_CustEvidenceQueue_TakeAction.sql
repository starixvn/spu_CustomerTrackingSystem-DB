/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
USE CTS_DataCenter;
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidenceQueue_TakeAction`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidenceQueue_TakeAction`(
		IN 	ip_CustEvidence 		JSON
	,	IN	ip_ActionID				TINYINT UNSIGNED
    
    ,	OUT op_ErrorMessage 		VARCHAR(200)    
    ,	OUT op_Result 				VARCHAR(8000)
)
SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210204@Long.Luu
		Task:		Main SP of Customer Evidence Queue [Redmine ID: #148719]
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20210204@Long.Luu: Created [Redmine ID: #148719]
            - 20220426@Casey.Huynh: Add CreatedBy [Redmine ID: #171512]
            
            
		Param's Explanation (filtered by):   
			- ip_ActionID: 1 insert, 2 override, 3 clear
		Example:			
			- call CTS_DataCenter.CTS_DC_CustEvidenceQueue_TakeAction('[{"CTSCustID":19314,"EvidenceID":13,"Remark":"test","CreatedBy":8}]', 1, @op_ErrorMessage);
	*/
    
    DECLARE lv_CustIDList 	VARCHAR(8000);
    DECLARE lv_CreatedBy 	INT DEFAULT 10278938;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidences;    
	CREATE TEMPORARY TABLE Temp_CustomerEvidences 
	(	 
			CTSCustID		BIGINT UNSIGNED
        ,	EvidenceID		SMALLINT UNSIGNED
        ,	Remark			VARCHAR(500)
        ,	CreatedBy		INT	UNSIGNED
		, 	INDEX	IX_Temp_CustomerEvidences_CTSCustID_EvidenceID(CTSCustID,EvidenceID) 
	);      
    
    INSERT INTO Temp_CustomerEvidences(CTSCustID, EvidenceID, Remark, CreatedBy)
	SELECT	tmpTable.CTSCustID
		,	tmpTable.EvidenceID
		,	tmpTable.Remark
		,	tmpTable.CreatedBy
	FROM JSON_TABLE(ip_CustEvidence, 
		"$[*]" COLUMNS(
			  CTSCustID 	BIGINT UNSIGNED		PATH "$.CTSCustID"
			, EvidenceID	SMALLINT UNSIGNED	PATH "$.EvidenceID"
			, Remark		VARCHAR(500)		PATH "$.Remark"
            , CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
		)) AS tmpTable;		
    
    IF (ip_ActionID = 1) THEN
		CALL CTS_DataCenter.CTS_DC_CustEvidence_InsertMultiple(ip_CustEvidence, lv_CreatedBy, 0, op_ErrorMessage);
    ELSEIF (ip_ActionID = 2) THEN
		CALL CTS_DataCenter.CTS_DC_CustEvidence_InsertMultiple(ip_CustEvidence, lv_CreatedBy, 1, op_ErrorMessage);
    ELSEIF (ip_ActionID = 3) THEN
		SELECT GROUP_CONCAT(t.CTSCustID)
        INTO lv_CustIDList
		FROM Temp_CustomerEvidences AS t;

		CALL CTS_DC_CustEvidence_ClearEvidence(ip_CustEvidence, op_ErrorMessage, op_Result);

    END IF;
END$$
DELIMITER ;