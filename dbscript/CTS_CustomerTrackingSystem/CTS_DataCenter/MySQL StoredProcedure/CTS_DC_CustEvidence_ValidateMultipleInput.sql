/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_ValidateMultipleInput`(IN ip_NewAccountEvidences json,IN ip_IsOverride tinyint)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200608@Long.Luu
		Task:		Check whether multiple account-evidence is valid [Redmine ID: 134489]
		DB:			CTS_DataCenter
		Original:

		Revisions:
		   - 20200608@Long.Luu: Created [Redmine ID: 134489]
		   - 20200824@Roger.Le[Redmine ID: 137551]: Evidence Upload - Overrite the data
		   - 20201116@Adam.Tran[Redmine ID: 141563]: Implement Cust Evidence from file
        
		Param's Explanation (filtered by):
	*/    
    
	DROP TEMPORARY TABLE IF EXISTS tmpMultipleAccountEvidence;    
	CREATE TEMPORARY TABLE tmpMultipleAccountEvidence 
    (	 
			RowId			INT
		,  	Username		VARCHAR(50)        
        , 	EvidenceCode	VARCHAR(10)        
        , 	PRIMARY KEY	tmpMultipleAccountEvidence(Username,EvidenceCode) 
    );     
    
    INSERT INTO tmpMultipleAccountEvidence(RowId, Username, EvidenceCode)
	SELECT 	tmpTable.RowId
		, 	tmpTable.Username
		, 	tmpTable.EvidenceCode
	FROM JSON_TABLE(ip_NewAccountEvidences,
		 "$[*]" COLUMNS(
			  RowId 			INT UNSIGNED		PATH "$.RowId"
			, Username			VARCHAR(50)			PATH "$.Username"
			, EvidenceCode		VARCHAR(10)			PATH "$.EvidenceCode"
		 )) AS tmpTable;  
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SELECT 	RowId
		,	c.CTSCustID
		,	c.CustID
		,	c.SubscriberID
        ,	e.EvidenceID
        ,	CASE 
				WHEN c.CTSCustID IS NULL AND e.EvidenceID IS NULL THEN 'Both Customer & Evidence do not exist.'
                WHEN c.CTSCustID IS NULL THEN 'This Customer does not exist.'
                WHEN e.EvidenceID IS NULL THEN 'This Evidence does not exist.'
                WHEN ce.CTSCustID IS NOT NULL AND ce.EvidenceID IS NOT NULL AND ip_IsOverride = false THEN 'This Customer has already been flagged with this Evidence.'
                ELSE ''
			END AS RowStatus
    FROM tmpMultipleAccountEvidence AS t
		LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON t.Username = c.Username
        LEFT JOIN CTS_DataCenter.Evidence AS e ON t.EvidenceCode = e.EvidenceCode
        LEFT JOIN CTS_DataCenter.CustEvidence AS ce ON c.CTSCustID = ce.CTSCustID AND e.EvidenceID = ce.EvidenceID AND ce.Level = 0;

	DROP TEMPORARY TABLE IF EXISTS tmpMultipleAccountEvidence;

END$$

DELIMITER ;