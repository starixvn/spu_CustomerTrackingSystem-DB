/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_ValidateMultipleInput`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_ValidateMultipleInput`(
		IN ip_NewAccountEvidences 	JSON
	,	IN ip_IsOverride 			BOOLEAN
)
SQL SECURITY INVOKER

BEGIN
	/*
		Created:	20200608@Long.Luu
		Task:		Check whether multiple account-evidence is valid [Redmine ID: #134489]
		DB:			CTS_DataCenter
		Original:

		Revisions:
		   - 20200608@Long.Luu: Created [Redmine ID: #134489]
		   - 20200824@Roger.Le: Evidence Upload - Overrite the data [Redmine ID: #137551]
		   - 20201116@Adam.Tran: Implement Cust Evidence from file [Redmine ID: #141563]
		   - 20210407@Adam.Tran: Prevent Adding Evidence for Sub Account [Redmine ID: #153007]
		Param's Explanation (filtered by):
			call CTS_DataCenter.CTS_DC_CustEvidence_ValidateMultipleInput('[{"RowId":1,"Username":"member17","EvidenceCode":"2.1"},{"RowId":3,"Username":"M9D2CSub01","EvidenceCode":"6.1"}]', 0);
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
				WHEN c.CustSubID IS NOT NULL AND c.CustSubID <> 0 THEN 'This Customer cannot be added evidence.'
                ELSE ''
			END AS RowStatus
    FROM tmpMultipleAccountEvidence AS t
		LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON t.Username = c.Username
        LEFT JOIN CTS_DataCenter.Evidence AS e ON t.EvidenceCode = e.EvidenceCode
        LEFT JOIN CTS_DataCenter.CustEvidence AS ce ON c.CTSCustID = ce.CTSCustID AND e.EvidenceID = ce.EvidenceID AND ce.Level = 0;	

END$$

DELIMITER ;